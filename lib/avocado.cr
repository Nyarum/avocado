
annotation AvocadoModel
end

macro define_pack_methods(class_name)
  pp {{ parse_type(class_name).resolve }}
end

macro define_unpack_methods

end

module Avocado

  class Pack

    #define_pack_methods {{ @type }}

    puts {{ @type }}
    puts {{ @type.includers }}
    puts {{ parse_type(@type.superclass.stringify).resolve }}

    def annotation
      {% for ann, idx in @type.annotations(AvocadoModel) %}
        pp "Annotation {{ idx }} = {{ ann[0].id }}"
      {% end %}
    end

  end

  class Unpack
    
    def do
      puts "test"
    end

  end

end