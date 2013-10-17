class ConfigurableSetting < ActiveRecord::Base
  # This class replaces the acts_as_configurable vendorised-gem used before the Rails upgrade.
  # This was a customised version this git-repo: https://github.com/nkryptic/acts_as_configurable

  def self.set_object_setting(object, name, value)
    settings = self.by_object_and_name(object,name)

    if settings.empty?
      setting = new
      setting.configurable_id = object.id
      setting.configurable_type = object.class.to_s
      setting.name = name
    else
      setting = settings.last
    end

    setting.value = value.to_s
    setting.save
  end

  def self.object_setting(object, name)
    settings = by_object_and_name(object, name)
    settings.empty?  ? nil  : settings.last.value
  end


  private

  def self.by_object_and_name(object, name)
    ConfigurableSetting.where(:configurable_id => object.id) \
                        .where(:configurable_type => object.class.to_s) \
                        .where(:name => name.to_s)
  end

end
