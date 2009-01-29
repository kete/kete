class ExtendedFieldsController < ApplicationController
  
  helper ExtendedFieldsHelper
  
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index, :add_field_to_multiples]

  before_filter :set_page_title

  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :extended_field do |config|
    # Default columns and column exclusions
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms, :example, :multiple, :user_choice_addition]
    config.list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type, :user_choice_addition]
    
    config.columns << [:base_url]
    config.columns[:base_url].label = "Base URL"
    config.columns[:base_url].description = "Whatever the user inputs will be appended to this base url (e.g. http://site.com/~[user_input])"

    # CRUD for adding/removing choices
    config.columns << [:pseudo_choices]
    config.columns[:pseudo_choices].label = "Available choices"
    config.columns[:pseudo_choices].description = "Ftype must be a \"choices\" option for these options to be available to users."
    config.columns[:user_choice_addition].label = nil
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
        :partial => 'extended_fields/extended_field_editor', \
        :locals => { :ef => extended_field, :content => [], :n => n, :multiple => true }
        
      # Add the field adder control back to the bottom of the set
      page.insert_html :bottom, "#{qualified_name_for_field(extended_field)}_multis", \
        :partial => 'extended_fields/additional_extended_field_control', \
        :locals => { :ef => extended_field, :n => n.to_i + 1 }
    end
  end
  
  # Fetch subchoices for a choice. 
  def fetch_subchoices

    extended_field = ExtendedField.find(params[:options][:extended_field_id])
    
    # Find the current choice
    current_choice = params[:value].blank? ? \
      Choice.find_by_label(params[:label]) : Choice.find_by_value(params[:value])
    
    choices = current_choice ? current_choice.children.select { |c| extended_field.choices.member?(c) } : []
    
    options = {
      :choices => choices,
      :level => params[:for_level].to_i + 1,
      :extended_field => extended_field
    }
    
    # Ensure we have a standard environment to work with. Some parts of the helpers (esp. ID and NAME 
    # attribute generation rely on these.
    @item_type_for_params = params[:item_type_for_params]
    @field_multiple_id = params[:field_multiple_id]
      
    
    render :update do |page|
      
      # Generate the DOM ID
      dom_id = "#{id_for_extended_field(options[:extended_field])}__level_#{params[:for_level]}"
      
      if options[:choices].empty?
        page.replace_html dom_id, ""
      else
        page.replace_html dom_id,
          :partial => "extended_fields/choice_#{params[:editor]}_editor",
          :locals => params[:options].merge(options)
      end
    end
  end

  private

  def set_page_title
    @title = 'Extended Fields'
  end
end
