# frozen_string_literal: true

class BasketSettings
  # ROB:  This class is here to remove settings stored in the acts_as_configurable
  #       table.
  #       This would be per-object settings with targetable_type = "basket"

  def self.get(name, *args)
    # EOIN: just while we are figuring out how this works
    raise "Woah, we expected just a name but we got the name #{name} and these extras: #{args}" unless args.empty?
    # p "called basket instance #setting. You passed #{name}"

    settings.fetch(name)
  rescue
    :basket_settings_did_not_know_about_setting
  end

  private

  def self.settings
    {
      show_discussion: 'all users',
      show_flagging: 'all users',
      theme: '',
      fully_moderated: false, # ROB: the default site-basket in non-moderated, but most of the others are.
      moderated_except: '',
      theme_font_family: '',
      header_image: '',
      browse_view_as: '',
      show_add_links: false,
      replace_existing_footer: false,
      additional_footer_content: '',

      # Possible values of memberlist_policy:
      #     'all users'
      #     'logged in'
      #     'at least member'
      #     'logged in'
      #     'at least member'
      #     'all users'
      memberlist_policy: 'at least member',

      show_action_menu: 'all users' # ROB: all users can see "Item Details"/"Edit"/... menu for items in a basket.
    }
  end
end
