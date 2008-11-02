class ExtendedFieldsController < ApplicationController
  
  helper ExtendedFieldsHelper
  
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index, :add_field_to_multiples]

  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :extended_field do |config|
    # Default columns and column exclusions
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms, :example, :multiple]
    config.list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type]
    
    # Description for ftype
    # config.columns[:ftype].description = "Field type. Options include \"text\", \"choice\". Must be set to \"choice\" for Choices (see below) to be selectable."
    
    # CRUD for adding/removing choices
    config.columns << [:pseudo_choices]
    config.columns[:pseudo_choices].label = "Available choices"
    config.columns[:pseudo_choices].description = "Ftype must be \"choice\" for these options to be available."
  end
  
  def add_field_to_multiples
    
    extended_field = ExtendedField.find(params[:extended_field_id])
    n = params[:n].to_i
    @item_type_for_params = params[:item_key]
    
    render :update do |page|
     
      # Remove the field adder control
      page.remove "#{qualified_name_for_field(extended_field)}_multis_extender"
      
      # Add a new field editor to the bottom of the set
      page.insert_html :bottom, "#{qualified_name_for_field(extended_field)}_multis", \
        :partial => 'search/extended_field_editor', \
        :locals => { :ef => extended_field, :content => [], :n => n }
        
      # Add the field adder control back to the bottom of the set
      page.insert_html :bottom, "#{qualified_name_for_field(extended_field)}_multis", \
        :partial => 'search/additional_extended_field_control', \
        :locals => { :ef => extended_field, :n => n.to_i + 1 }
    end
  end
  
end
