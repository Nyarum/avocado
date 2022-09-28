
annotation AvocadoModel
end

annotation AvocadoItem
end

module Avocado

  def []=(variable, value)
    {% for ivar in @type.instance_vars %}
      if {{ivar.id.symbolize}} == variable
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

    def pack(io, type)
      case v = type
      when UInt8, UInt16, UInt32, UInt64
        io.write_bytes(v, IO::ByteFormat::BigEndian)
      when Bytes
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << String.new(v)
      when String
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << v
      when Array
        v.each do |x|
          if x.is_a?(Struct)
            x.pack(io)
          else
            pack(io, x)
          end
        end
      end
    end

    def pack(io)
      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        pack(io, self[":" + x])
      }
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}
    end
  
  end

  module Unpack
    
    include Avocado

    def unpack(io, type)
      case v = type
      when UInt8, UInt16, UInt32, UInt64
        IO::ByteFormat::BigEndian.decode(typeof(v), io)
      when Bytes
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << String.new(v)
      when String
        io.write_bytes(v.size.to_i16, IO::ByteFormat::BigEndian)
        io << v
      when Array
        v.each do |x|
          if x.is_a?(Struct)
            x.pack(io)
          else
            pack(io, x)
          end
        end
      end
    end

    def unpack(io)
      {{ @type.methods.map(&.name).select { |m| !m.includes?("=") }.map(&.stringify) }}.each { |x|
        if x == "initialize"
          next
        end

        pack(io, self[":" + x])
      }
    end

  end

end

