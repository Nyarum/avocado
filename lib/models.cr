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
    property is_cheat : Int16 = 0
    property client_version : Int16 = 0
  end

  struct InstAttribute
    include Avocado::Pack

    property id : UInt16 = 0
    property value : UInt16 = 0
  end

  struct Item
    include Avocado::Pack

    property id : UInt16 = 0
    property num : UInt16 = 0
    property endure : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property energy : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property forge_lv : UInt8 = 0
    property pass_value : UInt8 = 0
    property db_param : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property inst_attrs : Array(InstAttribute) = Array(InstAttribute).new(5, InstAttribute.new) # 5
    property item_attrs : Array(UInt16) = Array(UInt16).new(58, 0) # 58
    property init_flag : UInt8 = 0
    property pass_value2 : UInt8 = 0
    property valid : Bool = false
    property change : Bool = false
  end

  # LOOK size (from ver:) 2 + 2 + (10 * (2 + 2 + 4 + 4 + 1 + 1 + 4 + (5 * 4) + (58 * 2) + 1 + 1 + 1 + 1)) + 2 = 1586
  struct Character
    include Avocado::Pack

    property is_active : UInt8 = 0
    property name : String = ""
    property job : String = ""
    property level : UInt16 = 0
    property look_size : UInt16 = 1626
    property ver : UInt16 = 0
    property type_id : UInt16 = 1
    property items : Array(Item) = Array(Item).new(10, Item.new) # 10
    property hair : UInt16 = 0
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
end