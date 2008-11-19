class ExtendedFieldsController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]
  before_filter :set_page_title

  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :extended_field do |config|
    config.columns = [:label, :description, :xml_element_name, :ftype, :import_synonyms, :example, :multiple]
    list.columns.exclude [:updated_at, :created_at, :topic_type_id, :xsi_type]
  end

  private

  def set_page_title
    @title = 'Extended Fields'
  end
end
