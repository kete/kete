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
      @@extensions ||= { blocks: nil }
    end

    def extensions=(extensions)
      @@extensions = extensions
    end

    def setup_extensions!
      # setup so extensions are loaded once in production, but each request in development
      #      ActionController::Dispatcher.to_prepare { Kete.load_extensions! }
      # then setup initially so that script/console works
      #      Kete.load_extensions!
    end

    def load_extensions!
      return if extensions[:blocks].nil?
      extensions[:blocks].each do |key, procs|
        procs.each { |proc| proc.call }
      end
    end

    def add_code_to_extensions_for(key, code)
      extensions[:blocks] ||= Hash.new
      extensions[:blocks][key] ||= Array.new
      extensions[:blocks][key] << code
    end

    # dynamically define reader methods for system settings
    # for background on metaclass method definition
    # see http://blog.jayfields.com/2007/10/ruby-defining-class-methods.html
    # and rails/activesupport/lib/active_support/core_exts/object/metaclass.rb
    def define_reader_method_for(setting)
      method_name = setting.constant_name.downcase

      class_variable_set('@@' + method_name, setting.constant_value)

      # create the template code
      code = reader_proc_for(setting)

      metaclass.instance_eval { define_method(method_name, &code) }

      # create predicate method if boolean
      eval_value = setting.constant_value
      if eval_value.kind_of?(TrueClass) || eval_value.kind_of?(FalseClass)
        metaclass.instance_eval { define_method("#{method_name}?", &code) }
      end
    end

    def reader_proc_for(setting)
      method_name = setting.constant_name.downcase

      Proc.new do
        method_name = method_name.sub('?', '') if method_name.include?('?')
        class_variable_get('@@' + method_name)
      end
    end

    def define_reader_method_as(method_name, value)
      # create the template code
      code = Proc.new do
        value
      end

      metaclass.instance_eval { define_method(method_name, &code) }

      # create predicate method if boolean
      if value.kind_of?(TrueClass) || value.kind_of?(FalseClass)
        metaclass.instance_eval { define_method("#{method_name}?", &code) }
      end
    end

    def metaclass
      # !! should be replace by Object#singleton_class (ruby 1.9.2)
      class << self
        self
      end
    end
  end
end
