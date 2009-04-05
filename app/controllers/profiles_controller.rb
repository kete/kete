# Site Administrators only, for setting up profiles
# currently only used for basket profiles
# (i.e. setting what basket options a basket admin can change)
class ProfilesController < ApplicationController
  before_filter :login_required, :only => [ :list, :index ]

  permit "site_admin"

  active_scaffold :profiles do |config|

    # Which columns to show
    config.columns = [:name]
    config.list.columns.exclude :updated_at, :created_at

    # the parent field for the individual forms
    config.columns << [:rules]
    config.columns[:rules].label = "Fields Available to Basket Administrators"
    config.columns[:rules].description = ""

  end

  public :render_to_string
  helper_method :render_to_string
end
