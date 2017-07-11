class ExtendedFieldSettings
  # ROB:  This class is here to remove settings stored in the acts_as_configurable 
  #       table.
  #       This would be per-object settings with targetable_type = "extended_field"

  def self.get(name, *args)
    # EOIN: just while we are figuring out how this works
    raise "Woah, we expected just a name but we got the name #{name} and these extras: #{args}" unless args.empty?
    p "called extended_field instance #setting. You passed #{name}"

    settings.fetch(name)
  rescue
    :extended_field_settings_did_not_know_about_setting
  end

  private

  def self.settings
    {
      base_url: '/',
      # ROB:  presumably it's possible for baskets to have different
      #       base-URLs on the same server. Lets not use the system 
      #       one for the time being.
    }
  end
end

