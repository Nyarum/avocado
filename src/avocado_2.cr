
require "./enums"

annotation AvocadoModel
end

annotation AvocadoItem
end

struct Bool
    def pack(io, order)
        if self
            io.write_bytes(1_u8, order)
        else
            io.write_bytes(0_u8, order)
        end
    end

    def unpack(io, order)
        buf = Bytes.new(1)
        io.read(buf)
        
        res = order.decode(UInt8, buf)
        res == 1 ? true : false
    end
end

struct UInt8
    def pack(io, order)
        io.write_bytes(self, order)
    end

    def unpack(io, order)
        buf = Bytes.new(1)
        io.read(buf)
    
        order.decode(UInt8, buf)
    end
end

struct UInt16
    def pack(io, order)
        io.write_bytes(self, order)
    end

    def unpack(io, order)
        buf = Bytes.new(2)
        io.read(buf)

        order.decode(UInt16, buf)
    end
end

struct UInt32
    def pack(io, order)
        io.write_bytes(self, order)
    end

    def unpack(io, order)
        buf = Bytes.new(4)
        io.read(buf)
    
        order.decode(UInt32, buf)
    end
end

struct Slice
    def pack(io, order)
        v = self
        io << String.new(v)
    end

    def unpack(io, order)
        buf = Bytes.new(2)
        io.read(buf)

        len = order.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)

        buf
    end
end

class Array
    def pack(io, order)
        self.each do |el|
            el.pack(io, order)
        end
    end

    def unpack(io, order)
        self.each do |el|
            el.unpack(io, order)
        end
    end
end

class String
    def pack(io, order)
        v = self + String.new(Bytes[0x00])
        io.write_bytes(v.size.to_i16, order)
        io << v
    end

    def unpack(io, order)
        buf = Bytes.new(2)
        io.read(buf)

        len = order.decode(UInt16, buf)

        buf = Bytes.new(len)
        io.read(buf)

        String.new(buf[0, len-1])
    end
end

module Avocado

    def opcode
        {{ @type.annotation(AvocadoModel)[:opcode] }}.to_u16
    end

    module Pack

        include Avocado

        @field_options = {} of String => NamedTuple(name: String, value: Bool | String)

        def pack(io, order = IO::ByteFormat::BigEndian)
            {% for ivar in @type.instance_vars %}
                {% if !ivar.annotation(AvocadoItem).nil? %}
                    {% if ivar.annotation(AvocadoItem)[:len] != nil %}
                        @field_options[{{ ivar.name.stringify }}] = {
                            name: "len",
                            value: {{ ivar.annotation(AvocadoItem)[:len] }},
                        }
                    {% end %}

                    {% if ivar.annotation(AvocadoItem)[:guard] != nil %}
                        @field_options[{{ ivar.name.stringify }}] = {
                            name: "guard",
                            value: {{ ivar.annotation(AvocadoItem)[:guard] }},
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

            {% if !@type.annotation(AvocadoModel).nil? %}
                order = {{ @type.annotation(AvocadoModel)[:order] }}
            {% end %}
            
            if order.nil?
                order = IO::ByteFormat::BigEndian
            end

            {% for ivar in @type.instance_vars %}
                {% if ivar.stringify != "field_options" %}
                    case struct_field = @{{ ivar }}
                    when Struct
                        struct_field.pack(io, order)
                    when Array
                        if !@field_options[{{ ivar.name.stringify }}]?.nil? 
                            field_value = @field_options[{{ ivar.name.stringify }}]
                
                            case field_value[:name] 
                            when "len"
                                size = UInt8.new(struct_field.size)
                                size.pack(io, order) unless !field_value[:value]
                            end
                        end

                        struct_field.each_with_index do |array_field, index|
                            array_field.pack(io, order)
                        end
                    else 
                        struct_field.pack(io, order)
                    end
                {% end %}
            {% end %}
            self
        end   

    end

    module Unpack

        include Avocado

        def unpack(io, order = IO::ByteFormat::BigEndian)
            {% if !@type.annotation(AvocadoModel).nil? %}
                order = {{ @type.annotation(AvocadoModel)[:order] }}
            {% end %}

            if order.nil?
                order = IO::ByteFormat::BigEndian
            end

            {% for ivar in @type.instance_vars %}
                {% if ivar.stringify != "field_options" %}
                    case struct_field = @{{ ivar }}
                    when Struct
                        @{{ ivar }} = struct_field.unpack(io, order)
                    when Array
                        struct_field.each_with_index do |array_field, index|
                            struct_field[index] = array_field.unpack(io, order)
                        end
                    else 
                        @{{ ivar }} = struct_field.unpack(io, order)
                    end
                {% end %}
            {% end %}
            self
        end   

    end
end
