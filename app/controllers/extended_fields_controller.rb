class ExtendedFieldsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :current_basket"

  active_scaffold :extended_field do |config|
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms]
    list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type]
  end
end
