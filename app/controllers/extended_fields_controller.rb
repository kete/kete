class ExtendedFieldsController < ApplicationController
  
  helper ExtendedFieldsHelper
  
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :extended_field do |config|
    # Default columns and column exclusions
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms, :example, :multiple]
    config.list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type]
    
    # Description for ftype
    config.columns[:ftype].description = "Field type. Options include \"text\", \"choice\". Must be set to \"choice\" for Choices (see below) to be selectable."
    
    # CRUD for adding/removing choices
    config.columns << [:pseudo_choices]
    config.columns[:pseudo_choices].label = "Available choices"
    config.columns[:pseudo_choices].description = "Ftype must be \"choice\" for these options to be available."
  end
end
