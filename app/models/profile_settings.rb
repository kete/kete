class ProfileSettings
  # ROB:  This class is here to remove settings stored in the acts_as_configurable
  #       table.
  #       This would be per-object settings with targetable_type = "profile"
  #
  #       The original code has a comment that acts_as_configurable
  #       "holds our profile's rule set".

  def self.get(name, *args)
    # EOIN: just while we are figuring out how this works
    raise "Woah, we expected just a name but we got the name #{name} and these extras: #{args}" unless args.empty?
    p "called profile instance #setting. You passed #{name}"

    settings.fetch(name)
  rescue
    :profile_settings_did_not_know_about_setting
  end

  private

  def self.settings
    {}
  end
end
