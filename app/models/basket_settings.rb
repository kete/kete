class BasketSettings

  def self.get(name)
    settings.fetch(name)
  rescue
    :basket_settings_did_not_know_about_setting
  end

  private

  def self.settings
    {
      theme: "",
      fully_moderated: true,
      moderated_except: "",
      theme_font_family: "",
      header_image: "",
      browse_view_as: "",
      show_add_links: false,
      replace_existing_footer: false,
      additional_footer_content: ""
    }
  end
end
