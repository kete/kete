module RequiredSoftware
  unless included_modules.include? RequiredSoftware
    def load_required_software
      YAML.load_file("#{RAILS_ROOT}/config/required_software.yml")
    end

    # poached and modified to include non-gem/lib requirements
    # from http://www.depixelate.com/2006/8/9/quick-tip-ensuring-required-gems-and-libs-are-available
    # --- [ check that we have all the gems and libs we need ] ---
    def missing_libs(required_software, lib_type='gems', args = {})
      missing_libs = Array.new
      required_libs = Hash.new

      required_software[lib_type].each do |key, value|
        next if !args[:exclude].blank? && args[:exclude].include?(key)
        if !value.blank? && value.kind_of?(Hash)
          name = (value['lib_name'] || value['gem_name'] || key)
          if value['version']
            required_libs[key] = [name, value['version']]
          else
            required_libs[key] = name
          end
        else
          required_libs[key] = key
        end
      end

      unless lib_type == 'testing_gems'
        required_software['libs'].each do |key, value|
          required_libs[key] = value
        end
      end

      required_libs.values.each do |lib|
        begin
          if lib.is_a?(Array)
            gem lib[0], "= #{lib[1]}"
          else
            require lib
          end
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
