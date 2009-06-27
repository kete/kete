class ChoicesController < ApplicationController
  
  before_filter :login_required, :only => [ :list, :index ]

  before_filter :set_page_title

  permit "site_admin", :except => [ :categories_list ]
  
  active_scaffold :choices do |config|
    
    # Which columns to show
    config.columns = [:label, :value, :parent, :children]
    config.list.columns.exclude :updated_at, :created_at
    
    # Column overrides
    config.columns[:label].required = true
    config.columns[:value].description = I18n.t('choices_controller.label_example')
    
    # Subform column overrides
    # config.subform.columns = [:label]
  end
  
  # Ensure that the ROOT for better_nested_set isn't shown on activescaffold pages.
  def conditions_for_collection
    ['label != ?', 'ROOT']
  end

  def categories_list
  end

  private

  def set_page_title
    @title = t('choices_controller.title')
  end
end