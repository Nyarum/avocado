require "./models"
require "socket"
require "./avocado"
require "./database"
require "openssl"
require "./crypto"
require "pg"
require "crecto"

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

  def parse(context, data : Bytes)
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

    def initialize
      @data.time = Time.utc.to_s("[%m-%d %H:%M:%S:%L]")
    end

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
    @characters : Array(DBModels::Character)?

    def initialize(@characters)
    end
  
    def opcode
      @data.opcode
    end

    def result
      io = IO::Memory.new(2042)

      if characters = @characters
        characters.each do |char|
          new_char = Models::Character.new
          new_char.name = char.name!
          new_char.job = char.job!
          new_char.level = char.level!.to_u16
          new_char.is_active = 1

          @data.characters << new_char
        end
      end

      @data.pincode = 1
      
      @data.pack(io)

      io.to_s
    end
  end

  class Auth < PacketIn
    @data : Models::Credentials = Models::Credentials.new
    @characters : Array(DBModels::Character)? = Array(DBModels::Character).new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      puts "Username #{@data.login}"

      user = DB.get_by(DBModels::Account, Crecto::Repo::Query.where(username: @data.login).preload(:characters))

      case user
      when DBModels::Account
        password = user.password!
        
        @characters = user.characters?

        encrypted_password = encrypt_password(password, context[:date])
      end

      pp "Credentials data #{@data}"
      self
    end
    
    def next
      auth_characters_packet = PacketBuilder.new.build(Packets::AuthCharacters.new(@characters))

      puts auth_characters_packet.to_slice.to_unsafe_bytes.hexdump

      auth_characters_packet
    end
  end

  class CreateCharacter < PacketIn
    @data : Models::CreateCharacter = Models::CreateCharacter.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      pp "Create character data #{@data}"
      self
    end
    
    def next
      ""
    end
  end
end

class PacketBuilder

  def build(packet : PacketOut)
    io = IO::Memory.new(8096)
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
  @buffer : Array(String)
  @packet_inputs : Hash(UInt16, PacketIn)

  def initialize
    @buffer = Array(String).new
    @packet_inputs = {} of UInt16 => PacketIn

    PacketInputs.each do |k, v|
      @packet_inputs[k] = v
    end
  end

  def parse(context, data : Bytes)
    len_packet = IO::ByteFormat::BigEndian.decode(Int16, data[..1])
    if len_packet == 2
      return 1
    end

    id = IO::ByteFormat::LittleEndian.decode(Int32, data[2..5])
    opcode = IO::ByteFormat::BigEndian.decode(UInt16, data[6..7])

    puts "Opcode #{opcode}, id #{id}, len packet #{len_packet}"

    @buffer << @packet_inputs[opcode].parse(context, data[8..]).next()
  end

  def next()
    size = @buffer.size
    if size == 0 
      return
    end

    {@buffer.pop, size}
  end
end