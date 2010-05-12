# Walter McGinnis, 2010-05-08
# For holding info about the kete application instance
# including an extensions mechanism that add-ons can use
# to alter Kete as necessary
#
# also, all system settings have accessors dynamically defined
# system settings are accessable as constants as well for the time being
# though accessors from Kete object will be preferred way going forward
# see config/initializers/load_system_settings.rb for details
class Kete
  class << self
    def extensions
      @@extensions ||= { :blocks => nil }
    end
  
    def extensions=(extensions)
      @@extensions = extensions
    end

    # dynamically define reader methods for system settings
    # for background on metaclass method definition
    # see http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
    # and rails/activesupport/lib/active_support/core_exts/object/metaclass.rb
    def define_reader_method_for(setting)
      # create the template code
      code = Proc.new {
        SystemSetting.find_by_name(setting.name).constant_value
      }
   
      method_name = setting.constant_name.downcase

      metaclass.instance_eval { define_method(method_name, &code) }

      # create predicate method if boolean
      eval_value = setting.constant_value
      if eval_value.kind_of?(TrueClass) || eval_value.kind_of?(FalseClass)
        metaclass.instance_eval { define_method("#{method_name}?", &code) }
      end 
    end

    def define_reader_method_as(method_name, value)
      # create the template code
      code = Proc.new {
        value
      }
   
      metaclass.instance_eval { define_method(method_name, &code) }

      # create predicate method if boolean
      if value.kind_of?(TrueClass) || value.kind_of?(FalseClass)
        metaclass.instance_eval { define_method("#{method_name}?", &code) }
      end 
    end
  end
end
