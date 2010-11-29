# a registry of expected values
# providing this so they can be replaced when necessary by add-ons
# where expected values may changes depending on whether add-on is installed or not
# this should be used only if you can't get the value from I18n.t call

# to register an value
# HasValue.key_name = value

# to use a value
# assert_equal HasValue.key_name, thing_i_am_testing_for_value

# the value, if it contains \#\{...\} within it
# will be eval'd in the context the reader method was called in
# also Arrays, Hashes, integers, booleans will be eval'd to their expected values
# everything is stored internally as a string
#
# largely cribbed from lib/kete.rb for concepts
class HasValue
  class << self
    def overwrites
      @@overwrites ||= { :blocks => nil }
    end

    def overwrites=(overwrites)
      @@overwrites = overwrites
    end

    def load_overwrites!
      return if overwrites[:blocks].nil?
      overwrites[:blocks].each do |key, procs|
        procs.each { |proc| proc.call }
      end
    end

    # setter method
    # create class variable that stores value
    # undefine any previous reader method
    # define reader method
    # which will eval booleans, etc.
    def method_missing(method_sym, *args, &block)
      method_name = method_sym.to_s
      if method_name =~ /\=$/
        var_name = method_name.sub(/\=$/, "")

        class_variable_set('@@' + var_name, args[0])

        # create the template code
        code = reader_proc_for(var_name)

        metaclass.instance_eval { define_method(var_name, &code) }
      end
    end

    def reader_proc_for(var_name)
      Proc.new {
        value = class_variable_get('@@' + var_name)
        has_substitution = value.present? && value.include?('#{')
        if value.present? && (value.match(/^([0-9\{\[]|true|false)/) || has_substitution)
          value = eval(value)
        end
        value
      }
    end
  end
end

# we have one registry file per type of test
# and pull them in here
# you need to register your defaults in these files
require File.expand_path(File.dirname(__FILE__) + "/unit_values")

# uncomment these when they are are created
# require File.expand_path(File.dirname(__FILE__) + "/functional_values")
# require File.expand_path(File.dirname(__FILE__) + "/integration_values")

