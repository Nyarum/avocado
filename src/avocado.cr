# DEPRECATED

annotation AvocadoModel
end

annotation AvocadoItem
end

module Avocado

  enum Order
    BigEndian
    LittleEndian  
  end

  def []=(variable, value)
    {% for ivar in @type.instance_vars %}
      if {{ivar.id.symbolize}}.to_s == variable.to_s.[1..]
        if value.is_a?({{ ivar.type.id }})
          @{{ivar}} = value
        else
          raise "Invalid type #{value.class} for {{ivar.id.symbolize}} (expected {{ ivar.type.id }})"
        end
      end
    {% end %}
  end

  def [](variable) 
    {% for ivar in @type.instance_vars %}
      if {{ivar.id.symbolize}}.to_s == variable.to_s.[1..]
        return @{{ivar}}
      end
    {% end %}
  end

  module Pack

    include Avocado

    @field_options = {} of String => NamedTuple(name: String, value: Bool | String)

    def pack(io, type, variable, order)
      {% if !@type.annotation(AvocadoModel).nil? %}
        case {{ @type.annotation(AvocadoModel)[:order] }}
        when Avocado::Order::LittleEndian
          order = IO::ByteFormat::LittleEndian
        else
          order = IO::ByteFormat::BigEndian
        end
      {% end %}

      if !@field_options[variable]?.nil? 
        field_value = @field_options[variable]

        if field_value[:name] == "if" && self[":" + field_value[:value].as(String)] != 1
          return
        end
      end

      case v = type
      when UInt8, UInt16, UInt32, UInt64
        io.write_bytes(v, order)
      when Bytes
        io.write_bytes(v.size.to_i16, order)
        io << String.new(v)
      when String
        v = v + " "
        io.write_bytes(v.size.to_i16, order)
        io << v
      when Bool
        if v
          io.write_bytes(1_u8, order)
        else
          io.write_bytes(0_u8, order)
        end
      when Struct
        v.pack(io)
      when Array
        if !@field_options[variable]?.nil? 
          field_value = @field_options[variable]

          case field_value[:name] 
          when "len"
            pack(io, v.size.to_u8, variable, order) unless !field_value[:value]
          end
        end
        
        v.each do |x|
          if x.is_a?(Struct)
            x.pack(io)
          else
            pack(io, x, variable, order)
          end
        end
      end
    end

    def pack(io)
      {% for ivar in @type.instance_vars %}
        {% if !ivar.annotation(AvocadoItem).nil? %}
          {% if ivar.annotation(AvocadoItem)[:len] != nil %}
            @field_options[{{ ivar.name.stringify }}] = {
              name: "len",
              value: {{ ivar.annotation(AvocadoItem)[:len] }},
            }
          {% end %}

          {% if ivar.annotation(AvocadoItem)[:if] != nil %}
            @field_options[{{ ivar.name.stringify }}] = {
              name: "if",
              value: {{ ivar.annotation(AvocadoItem)[:if] }},
            }
          {% end %}
        {% end %}
      {% end %}

      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        pack(io, self[":" + x], x, IO::ByteFormat::BigEndian)
      }
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}.to_u16
    end
  
  end

  module Unpack
    
    include Avocado

    def unpack(io, type, variable, order, is_array = false)
      {% if !@type.annotation(AvocadoModel).nil? %}
        case {{ @type.annotation(AvocadoModel)[:order] }}
        when Avocado::Order::LittleEndian
          order = IO::ByteFormat::LittleEndian
        else
          order = IO::ByteFormat::BigEndian
        end
      {% end %}

      case v = type
      when UInt8
        buf = Bytes.new(1)
        io.read(buf)
        
        v = order.decode(typeof(v), buf)
        if !is_array 
          self[":" + variable] = v
        else
          v
        end
      when UInt16
        buf = Bytes.new(2)
        io.read(buf)

        v = order.decode(typeof(v), buf)
        if !is_array 
          self[":" + variable] = v
        else
          v
        end
      when UInt32
        buf = Bytes.new(4)
        io.read(buf)

        v = order.decode(typeof(v), buf)
        if !is_array 
          self[":" + variable] = v
        else
          v
        end
      when UInt64
        buf = Bytes.new(8)
        io.read(buf)
        
        v = order.decode(typeof(v), buf)
        if !is_array 
          self[":" + variable] = v
        else
          v
        end
      when Bytes
        buf = Bytes.new(2)
        io.read(buf)
        len = order.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)

        if !is_array 
          self[":" + variable] = buf
        else
          buf
        end
      when String
        buf = Bytes.new(2)
        io.read(buf)
        len = order.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)

        res = String.new(buf[0, len-1])
        if !is_array 
          self[":" + variable] = res
        else
          res
        end
      when Struct
        v.unpack(io)
        v
      when Array
        key = 0
        puts ":" + variable
        size_of_array = v.size

        while key < size_of_array
          case value_in_array = v[key]
          when Struct
            value_in_array.unpack(io)
          when UInt16
            puts typeof(value_in_array)
            puts key
            tt = self[":" + variable].as(Array(UInt16))
            vvv = unpack(io, value_in_array, variable, order, is_array = true).as(typeof(value_in_array))

            puts "value #{vvv}"
            tt[key] = vvv

            puts "test"
            puts tt[key]
            puts self[":" + variable]
          end

          key += 1
        end

        puts self[":" + variable]
      end
    end

    def unpack(io)
      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        unpack(io, self[":" + x], x, IO::ByteFormat::BigEndian)
      }
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}.to_u16
    end

  end

end

