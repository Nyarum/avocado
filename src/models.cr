require "./avocado"

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

    property id : UInt16 = 0
    property value : UInt16 = 0
  end

  struct ItemAttribute
    include Avocado::Pack
    include Avocado::Unpack

    property attr : UInt16 = 0
    property is_init : UInt8 = 0
  end

  # A2 (162 bytes)
  struct ItemGrid
    include Avocado::Pack
    include Avocado::Unpack

    property id : UInt16 = 0
    property num : UInt16 = 0
    property endure : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property energy : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property forge_lv : UInt8 = 0
    property db_param : Array(UInt32) = Array(UInt32).new(2, 0) # 2
    property inst_attrs : Array(InstAttribute) = Array(InstAttribute).new(5, InstAttribute.new)
    property item_attrs : Array(ItemAttribute) = Array(ItemAttribute).new(40, ItemAttribute.new)
    property change : Bool = true
  end

  @[AvocadoModel(order: Avocado::Order::LittleEndian)]
  struct Look
    include Avocado::Pack
    include Avocado::Unpack

    property ver : UInt16 = 0
    property type_id : UInt16 = 1
    property item_grids : Array(ItemGrid) = Array(ItemGrid).new(10, ItemGrid.new) # 10
    property hair : UInt16 = 2062
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
end