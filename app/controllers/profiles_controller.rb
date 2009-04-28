# Site Administrators only, for setting up profiles
# currently only used for basket profiles
# (i.e. setting what basket options a basket admin can change)
class ProfilesController < ApplicationController
  before_filter :login_required, :only => [ :list, :index ]

  before_filter :set_page_title

  permit "site_admin"

  helper :baskets

  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce :options => DEFAULT_TINYMCE_SETTINGS,
                :only => VALID_TINYMCE_ACTIONS
  ### end TinyMCE WYSIWYG editor stuff

  active_scaffold :profiles do |config|

    # Which columns to show
    config.columns = [:name]

    config.columns[:name].required = true

    # the parent field for the individual forms
    config.columns << [:rules]
    config.columns[:rules].required = true
    config.columns[:rules].label = "Fields Available"

  end

  public :render_to_string
  helper_method :render_to_string

  private

  def before_create_save(record)
    record.rules = params[:record][:rules]
  end

  def set_page_title
    @title = 'Basket Profiles'
  end
end
