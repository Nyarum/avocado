
annotation AvocadoModel
end

annotation AvocadoItem
end

module Avocado

  module Pack

    @io = IO::Memory.new(1024)

    macro field(type, subType = 0)
      
      @{{ type.var }} : {{ type.type }} = {{ type.value }}

      def {{ type.var }}= (v)
        @{{ type.var }} = v
      end

      def pack_{{ type.var }}
        {% if type.type.resolve == UInt8 ||
          type.type.resolve == UInt16 || 
          type.type.resolve == UInt32 ||
          type.type.resolve == UInt64 %}
          @io.write_bytes(@{{ type.var }}, IO::ByteFormat::BigEndian)
        {% end %}

        {% if type.type.resolve == String %}
          @io.write_bytes(@{{ type.var }}.size.to_i16, IO::ByteFormat::BigEndian)
          @io << @{{ type.var }}
        {% end %}

        {% if type.type.resolve == Bytes %}
          @io.write_bytes(@{{ type.var }}.size.to_i16, IO::ByteFormat::BigEndian)
          @io << String.new(@{{ type.var }})
        {% end %}
      
        puts {{ type.type == Array }}
        {% if !type.type.resolve.annotation(AvocadoItem).nil? %}
          puts {{ type.type.resolve.annotation(AvocadoItem)[:type] }}
        {% end %}

        puts {{ type.type }}.class

        {% if type.type.resolve >= Array.resolve %}
          puts "test"
        {% end %}
      end
       
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}
    end
  
  end

  module Unpack
    


  end

end

