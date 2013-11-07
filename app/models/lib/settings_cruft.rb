# There are many system settings in Kete which make the system hard to work with.
# These are being moved here--hopefully to enable simplifying or removal.
#
# System settings are in the system_settings table using the nove-system-setting gem.
#
# Per-object settings are in the configurable_settings table using the acts_as_configurable gem.

module SettingsCruft 

  class Application
    def initialize(current_basket, site_basket)
      @current_basket = current_basket
      @site_basket = site_basket
    end

    def theme
      @current_basket.setting(:theme) || @site_basket.setting(:theme) || 'default'
    end

    def theme_font_family
      @current_basket.setting(:theme_font_family) || @site_basket.setting(:theme_font_family) || 'sans-serif'
    end

    def header_image
      @current_basket.setting(:header_image) || @site_basket.setting(:header_image) || nil
    end
  end


  class Basket
    def self.setting(object,name)
      setting = ConfigurableSetting.object_setting(object, name)
      if setting.nil?
        nil
      elsif setting.respond_to?(:value)
        setting.value
      else
        setting
      end
    end

    def self.set_setting(object, name, value)
      ConfigurableSetting.set_setting(object, name, value)
    end
  end
end
