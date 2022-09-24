require "models"
require "socket"
require "avocado"

abstract class PacketOut
  abstract def opcode
  abstract def result
end

PacketInputs = [] of PacketIn.class

class PacketIn
  class_getter opcode : Int16 = 0

  macro inherited
    PacketInputs << {{@type}}
  end

  def self.parse(data : Bytes)
    puts "base implement"
  end

  def self.next()
    "base implement"
  end
end

module Packets
  class FirstTime < PacketOut
    getter opcode : Int16

    def initialize()
      @opcode = 940
    end

    def opcode
      @opcode
    end

    def result
      Time.utc.to_s("[%m-%d %H:%M:%S:%L]")
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
    getter opcode : Int16
    auth : Models::Auth

    def initialize(auth : Models::Auth)
      @opcode = 931
      @auth = auth
    end

    def opcode
      @opcode
    end

    def result
      io = IO::Memory.new(1024)
      io.write_bytes(@auth.error_code, IO::ByteFormat::BigEndian)
      io.write_bytes(@auth.key.size.to_i16, IO::ByteFormat::BigEndian)
      io << String.new(@auth.key)
      io.write_bytes(@auth.characters.size.to_i8, IO::ByteFormat::BigEndian)
      io.write_bytes(@auth.pincode, IO::ByteFormat::BigEndian)
      io.write_bytes(@auth.encryption, IO::ByteFormat::BigEndian)
      io.write_bytes(@auth.dw_flag, IO::ByteFormat::BigEndian)

      io.to_s
    end
  end

  class Test < PacketOut
    @data = Models::Character.new

    def opcode
      @data.opcode
    end

    def result
      @data.items << Models::Item.new
      @data.pack

      io = IO::Memory.new(1024)
      io.to_s
    end
  end

  class Auth < PacketIn
    @@credentials : Models::Credentials = Models::Credentials.new
    class_getter opcode : Int16 = 431

    def self.parse(data : Bytes)
      len_key = IO::ByteFormat::BigEndian.decode(Int16, data[..1]) + 1
      @@credentials.key = String.new(data[2..len_key])
      data = data[len_key+1..]

      len_login = IO::ByteFormat::BigEndian.decode(Int16, data[..1]) + 1
      @@credentials.login = String.new(data[2..len_login])
      data = data[len_login+1..]

      len_password = IO::ByteFormat::BigEndian.decode(Int16, data[..1]) + 1
      @@credentials.password = String.new(data[2..len_password])
      data = data[len_password+1..]

      len_mac = IO::ByteFormat::BigEndian.decode(Int16, data[..1]) + 1
      @@credentials.mac = String.new(data[2..len_mac])
      data = data[len_mac+1..]

      @@credentials.is_cheat = IO::ByteFormat::BigEndian.decode(Int16, data[..1])
      data = data[2..]

      @@credentials.client_version = IO::ByteFormat::BigEndian.decode(Int16, data[..1])

      puts @@credentials
    end
    
    def self.next()
      auth_characters_packet = PacketBuilder.new.build(Packets::AuthCharacters.new(Models::Auth.new))
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
    opcode = IO::ByteFormat::BigEndian.decode(Int16, data[6..7])

    PacketInputs.each do |elem|
      if opcode == elem.opcode
        elem.parse(data[8..])

        puts elem.next().to_slice
        @buffer << elem.next()
      end
    end
  end

  def next()
    size = @buffer.size
    if size == 0 
      return
    end

    {@buffer.pop, size}
  end
end