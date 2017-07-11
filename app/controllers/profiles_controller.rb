# Site Administrators only, for setting up profiles
# currently only used for basket profiles
# (i.e. setting what basket options a basket admin can change)
class ProfilesController < ApplicationController
  before_filter :login_required, only: [ :list, :index ]

  before_filter :set_page_title

  permit "site_admin"

  # active_scaffold :profiles do |config|
  #
  #   # Which columns to show
  #   config.columns = [:name]
  #
  #   config.columns[:name].required = true
  #
  #   # the parent field for the individual forms
  #   config.columns << [:rules]
  #   config.columns[:rules].required = true
  #   config.columns[:rules].label = I18n.t('profiles_controller.fields_available')
  #
  # end

  # make the render_to_string method public and available as a helper
  # so we can render forms inline in the profile rules column
  public :render_to_string
  helper_method :render_to_string

  private

  # A method used by active scaffold before saving a record
  # we have to set the rules here ourselves because either rails or
  # active scaffold does not set rules automatically when it is a hash
  def before_create_save(record)
    record.rules = params[:record][:rules]
  end

  def set_page_title
    @title = t('profiles_controller.title')
  end
end
