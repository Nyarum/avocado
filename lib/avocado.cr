
annotation AvocadoModel
end

annotation AvocadoItem
end

module Avocado

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

    @field_options = {} of String => NamedTuple(name: String, value: Bool)

    def pack(io, type, variable)
      case v = type
      when UInt8, UInt16, UInt32, UInt64
        io.write_bytes(v, IO::ByteFormat::BigEndian)
      when Bytes
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << String.new(v)
      when String
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << v
      when Bool
        if v
          io.write_bytes(1_u8, IO::ByteFormat::BigEndian)
        else
          io.write_bytes(0_u8, IO::ByteFormat::BigEndian)
        end
      when Array
        if !@field_options[variable]?.nil? 
          field_value = @field_options[variable]

          case field_value[:name] 
          when "len"
            pack(io, v.size.to_u8, variable) unless !field_value[:value]
          end
        end
        
        v.each do |x|
          if x.is_a?(Struct)
            x.pack(io)
          else
            pack(io, x, variable)
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
        {% end %}
      {% end %}

      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        pack(io, self[":" + x], x)
      }
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}.to_u16
    end
  
  end

  module Unpack
    
    include Avocado

    def unpack(io, type, variable)
      case v = type
      when UInt8
        buf = Bytes.new(1)
        io.read(buf)
        self[":" + variable] = IO::ByteFormat::BigEndian.decode(typeof(v), buf)
      when UInt16
        buf = Bytes.new(2)
        io.read(buf)
        self[":" + variable] = IO::ByteFormat::BigEndian.decode(typeof(v), buf)
      when UInt32
        buf = Bytes.new(4)
        io.read(buf)
        self[":" + variable] = IO::ByteFormat::BigEndian.decode(typeof(v), buf)
      when UInt64
        buf = Bytes.new(8)
        io.read(buf)
        self[":" + variable] = IO::ByteFormat::BigEndian.decode(typeof(v), buf)
      when Bytes
        buf = Bytes.new(2)
        io.read(buf)
        len = IO::ByteFormat::BigEndian.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)
        self[":" + variable] = buf
      when String
        buf = Bytes.new(2)
        io.read(buf)
        len = IO::ByteFormat::BigEndian.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)
        self[":" + variable] = String.new(buf)
      when Array
        v.each do |x|
          if x.is_a?(Struct)
            x.pack(io)
          else
            pack(io, x, variable)
          end
        end
      end
    end

    def unpack(io)
      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        unpack(io, self[":" + x], x)
      }
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}.to_u16
    end

  end

end

