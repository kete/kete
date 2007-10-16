module RequiredSoftware
  unless included_modules.include? RequiredSoftware
    def load_required_software
      YAML.load_file("#{RAILS_ROOT}/config/required_software.yml")
    end

    # poached and modified to include non-gem/lib requirements
    # from http://www.depixelate.com/2006/8/9/quick-tip-ensuring-required-gems-and-libs-are-available
    # --- [ check that we have all the gems and libs we need ] ---
    def missing_libs(required_software)
      missing_libs = Array.new
      required_libs = required_software['gems']

      required_software['libs'].each do |key, value|
        required_libs[key] = value
      end

      required_libs.values.each do |lib|
        begin
          require lib
        rescue LoadError
          missing_libs << lib
        end
      end
      missing_libs
    end

    # if standard rails things like mysql aren't installed, the server won't start up
    # so they don't need to be done here
    def missing_commands(required_software)
      missing_commands = Array.new
      required_commands = required_software['commands']

      required_commands.each do |pretty_name, command_test|
        # the passed in command_test should return a value
        # if the required software is installed
        command_found = `#{command_test}`
        if command_found.blank?
          missing_commands << pretty_name
        end
      end
      missing_commands
    end
  end
end
