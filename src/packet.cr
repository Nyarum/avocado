require "./models"
require "socket"
require "./avocado_2"
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

    def initialize(@characters, @is_pincode : Bool)
    end
  
    def opcode
      @data.opcode
    end

    def result
      io = IO::Memory.new(10984)

      if characters = @characters
        characters.each do |char|
          new_char = Models::Character.new
          new_char.name = char.name!
          new_char.job = char.job!
          new_char.level = char.level!.to_u16
          new_char.is_active = 1
          new_char.look = Models::Look.from_json char.look!.to_s

          @data.characters << new_char
        end
      end

      @data.pincode = @is_pincode ? 1.to_u8 : 0.to_u8
      
      @data.pack(io)

      io.to_s
    end
  end

  class Auth < PacketIn
    @data : Models::Credentials = Models::Credentials.new
    @characters : Array(DBModels::Character)? = Array(DBModels::Character).new
    @is_pincode : Bool = false

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      puts "Username #{@data.login}"

      user = DB.get_by!(DBModels::Account, Crecto::Repo::Query.where(username: @data.login).preload(:characters))

      case user
      when DBModels::Account
        password = user.password!
        
        @characters = user.characters?

        encrypted_password = encrypt_password(password, context[:date])

        context[:user_data]["user_id"] = user.id.as(Int32)

        @is_pincode = !user.pincode.nil?
      end

      pp "Credentials data #{@data}"
      self
    end
    
    def next
      auth_characters_packet = PacketBuilder.new.build(Packets::AuthCharacters.new(@characters, @is_pincode))

      puts auth_characters_packet.to_slice.to_unsafe_bytes.hexdump

      auth_characters_packet
    end
  end

  class CreateCharacterReply < PacketOut
    @data = Models::CreateCharacterReply.new

    def initialize
      
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

  class CreateCharacter < PacketIn
    @data : Models::CreateCharacter = Models::CreateCharacter.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      new_character = DBModels::Character.new
      new_character.account_id = context[:user_data]["user_id"]
      new_character.name = @data.name
      new_character.job = "Newbie"
      new_character.level = 1
      new_character.look = @data.look.to_json

      changeset = DB.insert(new_character)

      puts "Results of push to database #{changeset}"

      pp "Create character data #{@data}"
      self
    end
    
    def next
      reply = PacketBuilder.new.build(Packets::CreateCharacterReply.new)

      puts reply.to_slice.to_unsafe_bytes.hexdump

      reply
    end
  end

  class CreatePincodeReply < PacketOut
    @data = Models::CreatePincodeReply.new

    def initialize
      
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

  class CreatePincode < PacketIn
    @data : Models::CreatePincode = Models::CreatePincode.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      account = DB.get!(DBModels::Account, context[:user_data]["user_id"])
      account.pincode = @data.pincode
      changeset = DB.update(account)

      pp "Create pincode data #{@data}"
      self
    end
    
    def next
      reply = PacketBuilder.new.build(Packets::CreatePincodeReply.new)

      puts reply.to_slice.to_unsafe_bytes.hexdump

      reply
    end
  end

  class ChangePincodeReply < PacketOut
    @data = Models::ChangePincodeReply.new

    def initialize
      
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

  class ChangePincode < PacketIn
    @data : Models::ChangePincode = Models::ChangePincode.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      pp "Change pincode data #{@data}"
      self
    end
    
    def next
      reply = PacketBuilder.new.build(Packets::ChangePincodeReply.new)

      puts reply.to_slice.to_unsafe_bytes.hexdump

      reply
    end
  end

  class DeleteCharacterReply < PacketOut
    @data = Models::DeleteCharacterReply.new

    def initialize
      
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

  class DeleteCharacter < PacketIn
    @data : Models::DeleteCharacter = Models::DeleteCharacter.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      query = Crecto::Repo::Query.where(name: @data.name)
      changeset = DB.delete_all(DBModels::Character, query)

      pp "Results of deleting in database #{changeset}"

      pp "Delete character data #{@data}"
      self
    end
    
    def next
      reply = PacketBuilder.new.build(Packets::DeleteCharacterReply.new)

      puts reply.to_slice.to_unsafe_bytes.hexdump

      reply
    end
  end

  class EnterGameReply < PacketOut
    @data = Models::EnterGameReply.new

    def initialize
      
    end

    def opcode
      @data.opcode
    end

    def result
      io = IO::Memory.new(10986)
      @data.pack(io)
      io.to_s
    end
  end

  class EnterGame < PacketIn
    @data : Models::EnterGame = Models::EnterGame.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      pp "Enter game data #{@data}"
      self
    end
    
    def next
      res = Packets::EnterGameReply.new
      res.@data.map_name = "garner"
      res.@data.character_base.name = "test"

      reply = PacketBuilder.new.build(res)

      puts reply.to_slice.to_unsafe_bytes.hexdump

      reply
    end
  end

  class ExitAccount < PacketIn
    @data : Models::ExitAccount = Models::ExitAccount.new

    def opcode
      @data.opcode
    end

    def parse(context, data : Bytes)
      io = IO::Memory.new(data)
      @data.unpack(io)

      pp "Exit account #{@data}"
      context[:client].close
      self
    end
    
    def next
      
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

    next_packet = @packet_inputs[opcode].parse(context, data[8..]).next()
    if !next_packet.nil?
      @buffer << next_packet
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