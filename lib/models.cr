require "avocado"

module Models

  @[AvocadoModel(opcode: 940)]
  class FirstTime
    include Avocado::Pack

    field time : String = ""
  end
  
  struct Credentials
    property key : String = ""
    property login : String = ""
    property password : String = ""
    property mac : String = ""
    property is_cheat : Int16 = 0
    property client_version : Int16 = 0
  end

  struct InstAttribute
    property id : UInt16 = 0
    property value : UInt16 = 0
  end

  struct Item
    property id : UInt16 = 0
    property num : UInt16 = 0
    property endure : Array(UInt16) = Array(UInt16).new(0) # 2
    property energy : Array(UInt16) = Array(UInt16).new(0) # 2
    property forge_lv : UInt8 = 0
    property pass_value : UInt8 = 0
    property db_param : Array(UInt16) = Array(UInt16).new(0) # 2
    property inst_attrs : Array(InstAttribute) = Array(InstAttribute).new(0) # 5
    property item_attrs : Array(UInt16) = Array(UInt16).new(0) # 58
    property init_flag : UInt8 = 0
    property pass_value2 : UInt8 = 0
    property valid : Bool = false
    property change : Bool = false
  end

  struct Character
    include Avocado::Pack

    field flag : UInt8 = 0
    field name : String = ""
    field job : String = ""
    field level : UInt16 = 0
    field ver : UInt16 = 0
    field type_id : UInt16 = 0
    field items : Array(Item) = Array(Item).new(0) # 10
    field hair : UInt16 = 0
  end

  @[AvocadoModel(opcode: 931)]
  struct Auth
    include Avocado::Pack

    field error_code : UInt16 = 0
    field key : Bytes = Bytes[0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49]
    field characters : Array(Character) = Array(Character).new(0), Character
    field pincode : UInt8 = 0
    field encryption : UInt32 = 0
    field dw_flag : UInt32 = 12820
  end
end