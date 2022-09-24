
annotation AvocadoModel
end

module Avocado

  module Pack

    #self.{{ type }}

    #types = {{ @type.instance_vars.map &.name.stringify }}

    def pack
      vars = [] of String

      {% for name, index in @type.instance_vars %}
        vars << typeof(self.{{ name }}).to_s
      {% end %}

      puts vars
    end

    def opcode
      {{ @type.annotation(AvocadoModel)[:opcode] }}
    end
  
  end

  module Unpack
    


  end

end

