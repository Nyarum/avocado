require "models"
require "socket"
require "./avocado"

abstract class PacketOut
  abstract def opcode
  abstract def result
end

PacketInputs = {} of UInt16 => PacketIn # need to clone it to avoid data races

class PacketIn
  macro inherited
    handler = {{ @type.name }}.new
    PacketInputs[handler.opcode] = handler
  end

  def opcode
    0.to_u16
  end

  def parse(data : Bytes)
    puts "base implement"
    self
  end

  def next()
    "base implement"
  end
end

module Packets
  class FirstTime < PacketOut
    @data = Models::FirstTime.new

    def opcode
      @data.opcode
    end

    def result
      io = IO::Memory.new(2094)
      @data.pack(io)
      io.to_s
    end
  end

  class Ping < PacketOut
    getter opcode : Int16

    def initialize()
      @opcode = 0
    end

    def opcode
      @opcode
    end

    def result
      String.new(Bytes[0x0, 0x02])
    end
  end

  class AuthCharacters < PacketOut
    @data = Models::Auth.new

    def opcode
      @data.opcode
    end

    def result
      io = IO::Memory.new(1024)
      
      char = Models::Character.new
      char.name = "Nyarum"

      @data.characters = [char]
      @data.pack(io)
      io.to_s
    end
  end

  class AuthTest < PacketIn
    @data : Models::CredentialsTest = Models::CredentialsTest.new
    
    def opcode
      @data.opcode
    end

    def parse(data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)
      self
    end
    
    def self.next()
    end
  end

  class Auth < PacketIn
    @data : Models::Credentials = Models::Credentials.new
    
    def opcode
      @data.opcode
    end

    def parse(data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)
      self
    end
    
    def next()
      auth_characters_packet = PacketBuilder.new.build(Packets::AuthCharacters.new)
      auth_characters_packet
    end
  end
end

class PacketBuilder

  def build(packet : PacketOut)
    io = IO::Memory.new(2094)
    packet_body = packet.result

    len_packet = (packet_body.size + 8).to_i16

    # Len
    io.write_bytes(len_packet, IO::ByteFormat::BigEndian)
    io.write_bytes(128_i32, IO::ByteFormat::LittleEndian)
    io.write_bytes(packet.opcode, IO::ByteFormat::BigEndian)
    io << packet_body

    io.to_s
  end

end

class PacketParser
  buffer : Array(String)

  def initialize()
    @buffer = Array(String).new
  end

  def parse(data : Bytes)
    len_packet = IO::ByteFormat::BigEndian.decode(Int16, data[..1])
    if len_packet == 2
      return 1
    end

    id = IO::ByteFormat::LittleEndian.decode(Int32, data[2..5])
    opcode = IO::ByteFormat::BigEndian.decode(UInt16, data[6..7])

    @buffer << PacketInputs[opcode].parse(data[8..]).next()
  end

  def next()
    size = @buffer.size
    if size == 0 
      return
    end

    {@buffer.pop, size}
  end
end