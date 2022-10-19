require "./avocado_2"
require "json"
require "./enums"

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

  @[AvocadoModel(opcode: 433)]
  struct EnterGame
    include Avocado::Unpack

    property character_name : String = ""
  end

  struct Position
    include Avocado::Pack

    property x : UInt32 = 0
    property y : UInt32 = 0
    property radius : UInt32 = 0
  end

  struct CharacterBase
    include Avocado::Pack

    property cha_id : UInt32 = 0
    property world_id : UInt32 = 0
    property gm_lv : UInt8 = 0
    property handle : UInt32 = 0
    property ctrl_type : UInt8 = 0
    property name : String = ""
    property motto_name : String = ""
    property icon : UInt16 = 0
    property guild_id : UInt32 = 0
    property guild_name : String = ""
    property guild_motto : String = ""
    property guild_permission : UInt32 = 0
    property guild_circle_colour : UInt32 = 0
    property guild_icon : UInt8 = 0
    property stall_name : String = ""
    property state : UInt16 = 0
    property position : Position = Position.new
    property angle : UInt16 = 0
    property team_leader_id : UInt32 = 0
  end

  struct CharacterSkill
    include Avocado::Pack

    property id : UInt16 = 0
    property state : UInt8 = 0
    property level : UInt8 = 0
    property use_sp : UInt16 = 0
    property use_endure : UInt16 = 0
    property use_energy : UInt16 = 0
    property resume_time : UInt32 = 0
    property range_type : UInt16 = 0
    property params : Array(UInt16) = Array(UInt16).new(0, 0) # 4

    def initialize(range_params)
      if range_params.nil?
        @range_type = RANGE_TYPE_NONE
      else
        range_params.each do |param|
          @params << param
        end
      end
    end
  end

  struct CharacterSkillBag
    include Avocado::Pack

    property default_skill_id : UInt16 = 0
    property type : UInt8 = 0
    property skill_num : UInt16 = 0
    property skills : Array(CharacterSkill) = Array(CharacterSkill).new(0)
    
    def initialize
      @skill_num = @skills.size.to_u16
    end
  end

  struct SkillState
    include Avocado::Pack

    property id : UInt8 = 0
    property level : UInt8 = 0
    property duration : UInt32 = 0
    property start : UInt32 = 0
  end

  struct CharacterSkillState
    include Avocado::Pack

    property current_server_time : UInt32 = 0

    @[AvocadoItem(len: true)]
    property states : Array(SkillState) = Array(SkillState).new(0)
  end

  struct Attribute
    include Avocado::Pack

    property id : UInt8 = 0
    property value : UInt32 = 0
  end

  struct CharacterAttribute
    include Avocado::Pack

    property type : UInt8 = 0
    property num : UInt16 = 0
    property attributes : Array(Attribute) = Array(Attribute).new(0)
  end

  struct Item
    property id : UInt16 = 0
    property type : UInt32 = 0
  end

  struct KitbagItem
    include Avocado::Pack

    property grid_id : UInt16 = 0
    property id : UInt16 = 0
    property db_id : UInt16 = 0 
    property need_level : UInt16 = 0
    property num : UInt16 = 0
    property endure : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property energy : Array(UInt16) = Array(UInt16).new(2, 0) # 2
    property forge_level : UInt8 = 0
    property is_valid : Bool = false
    property item_db_params0 : Array(UInt32) = Array(UInt32).new(0, 0)
    property item_db_forge : UInt32 = 0
    property item_db_params1 : Array(UInt32) = Array(UInt32).new(0, 0)
    property is_params : Bool = false
    property inst_attrs : Array(InstAttribute) = Array(InstAttribute).new(0) # 5

    def initialize(items)
      if items[id].type == ItemType::Boat
        item_db_params0 << UInt32.new(0)
        item_db_params1 << UInt32.new(0)
      else
        item_db_params0 << UInt32.new(0)
      end

      @is_params = @inst_attrs.size != 0 ? true : false
    end
  end

  struct CharacterKitbag
    include Avocado::Pack

    property type : UInt8 = 0

    #if @type == SYN_KITBAG::INIT #Implement annotation to integrate field if previous value is equal to some another value
      #property keybag_num : UInt16 = 0
    #end

    property items : Array(KitbagItem) = Array(KitbagItem).new(48)

    def initialize
      (1..MAX_KBITEM_NUM_PER_TYPE).each do |x|
          @items << KitbagItem.new(Array(Item).new)
      end
    end
  end

  struct Shortcut
    include Avocado::Pack

    property type : UInt8 = 0
    property grid_id : UInt16 = 0
  end

  struct CharacterShortcut
    include Avocado::Pack

    property shortcuts : Array(Shortcut) = Array(Shortcut).new(0)

    def initialize
      (1..SHORT_CUT_NUM).each do |x|
          @shortcuts << Shortcut.new
      end
    end
  end

  struct CharacterBoat
    include Avocado::Pack

    property character_base : CharacterBase = CharacterBase.new
    property character_attribute : CharacterAttribute = CharacterAttribute.new
    property character_kitbag : CharacterKitbag = CharacterKitbag.new
    property character_skill_state : CharacterSkillState = CharacterSkillState.new
  end

  @[AvocadoModel(opcode: 516)]
  struct EnterGameReply
    include Avocado::Pack

    property enter_ret : UInt16 = 0
    property auto_lock : UInt8 = 0
    property kitbag_lock : UInt8 = 0
    property enter_type : UInt8 = 0
    property is_new_char : UInt8 = 0
    property map_name : String = ""
    property can_team : UInt8 = 0
    property imps : UInt32 = 0
    property character_base : CharacterBase = CharacterBase.new
    property character_skill_bag : CharacterSkillBag = CharacterSkillBag.new
    property character_skill_state : CharacterSkillState = CharacterSkillState.new
    property character_attribute : CharacterAttribute = CharacterAttribute.new
    property character_kitbag : CharacterKitbag = CharacterKitbag.new
    property character_kitbag_temp : CharacterKitbag = CharacterKitbag.new
    property character_shortcut : CharacterShortcut = CharacterShortcut.new

    @[AvocadoItem(len: true)]
    property character_boats : Array(CharacterBoat) = Array(CharacterBoat).new(0)
    property character_kitbag_temp : CharacterKitbag = CharacterKitbag.new
  end
end