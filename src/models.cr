require "./avocado_2"
require "json"

module Models

  @[AvocadoModel(opcode: 940)]
  struct FirstTime
    include Avocado::Pack

    property time : String = ""
  end
  
  @[AvocadoModel(opcode: 431)]
  struct Credentials
    include Avocado::Unpack

    property key : String = ""
    property login : String = ""
    property password : String = ""
    property mac : String = ""
    property is_cheat : UInt16 = 0
    property client_version : UInt16 = 0
  end

  struct InstAttribute
    include Avocado::Pack
    include Avocado::Unpack
    include JSON::Serializable

    property id : UInt16 = 0
    property value : UInt16 = 0
  end

  struct ItemAttribute
    include Avocado::Pack
    include Avocado::Unpack
    include JSON::Serializable

    property attr : UInt16 = 0
    property is_init : UInt8 = 0
  end

  # A2 (162 bytes)
  struct ItemGrid
    include Avocado::Pack
    include Avocado::Unpack
    include JSON::Serializable

    property id : UInt16 = 0
    property num : UInt16 = 0
    property endure : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property energy : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property forge_lv : UInt8 = 0
    property db_param : Array(UInt32) = Array(UInt32).new(2, 0) # 2
    property inst_attrs : Array(InstAttribute) = Array(InstAttribute).new(5)
    property item_attrs : Array(ItemAttribute) = Array(ItemAttribute).new(40)
    property change : Bool = true

    def initialize
      (1..5).each do |x|
          @inst_attrs << InstAttribute.from_json %({})
      end

      (1..40).each do |x|
          @item_attrs << ItemAttribute.from_json %({})
      end
    end
  end

  @[AvocadoModel(order: IO::ByteFormat::LittleEndian)]
  struct Look
    include Avocado::Pack
    include Avocado::Unpack
    include JSON::Serializable

    property ver : UInt16 = 0
    property type_id : UInt16 = 1
    property item_grids : Array(ItemGrid) = Array(ItemGrid).new(10) # 10
    property hair : UInt16 = 2062

    def initialize
      (1..10).each do |x|
          @item_grids << ItemGrid.new
      end
    end
  end

  # LOOK size (from ver:) 2 + 2 + (10 * (2 + 2 + 4 + 4 + 1 + 1 + 4 + (5 * 4) + (58 * 2) + 1 + 1 + 1 + 1)) + 2 = 1586
  # LOOK 2 size: 2 + 2 + 34 * (1 + 2 + 4 + 2 + 2 + 4 + 4 + 1 + 4 + (5 * 4) + (58 * 3) + 1 + 1)
  struct Character
    include Avocado::Pack

    property is_active : UInt8 = 0

    @[AvocadoItem(if: "is_active")]
    property name : String = ""

    @[AvocadoItem(if: "is_active")]
    property job : String = ""

    @[AvocadoItem(if: "is_active")]
    property level : UInt16 = 0

    @[AvocadoItem(if: "is_active")]
    property look_size : UInt16 = 1626

    @[AvocadoItem(if: "is_active")]
    property look : Look = Look.new
  end

  @[AvocadoModel(opcode: 931)]
  struct Auth
    include Avocado::Pack

    property error_code : UInt16 = 0
    property key : Bytes = Bytes[0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49]

    @[AvocadoItem(len: true)]
    property characters : Array(Character) = Array(Character).new(0)
    property pincode : UInt8 = 0
    property encryption : UInt32 = 0
    property dw_flag : UInt32 = 12820
  end

  @[AvocadoModel(opcode: 435)]
  struct CreateCharacter
    include Avocado::Unpack

    property name : String = ""
    property map : String = ""
    property look_size : UInt16 = 0
    property look : Look = Look.new
  end

  @[AvocadoModel(opcode: 935)]
  struct CreateCharacterReply
    include Avocado::Pack

    property error_code : UInt16 = 0
  end

  @[AvocadoModel(opcode: 436)]
  struct DeleteCharacter
    include Avocado::Unpack

    property name : String = ""
    property pincode : String = ""
  end

  @[AvocadoModel(opcode: 936)]
  struct DeleteCharacterReply
    include Avocado::Pack

    property error_code : UInt16 = 0
  end

  @[AvocadoModel(opcode: 346)]
  struct CreatePincode
    include Avocado::Unpack

    property pincode : String = ""
  end

  @[AvocadoModel(opcode: 941)]
  struct CreatePincodeReply
    include Avocado::Pack

    property error_code : UInt16 = 0
  end

  @[AvocadoModel(opcode: 347)]
  struct ChangePincode
    include Avocado::Unpack

    property old_pincode : String = ""
    property new_pincode : String = ""
  end

  @[AvocadoModel(opcode: 942)]
  struct ChangePincodeReply
    include Avocado::Pack

    property error_code : UInt16 = 0
  end

  @[AvocadoModel(opcode: 432)]
  struct ExitAccount
    include Avocado::Unpack

    property error_code : UInt16 = 0
  end
end