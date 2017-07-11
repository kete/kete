# frozen_string_literal: true

class ChoicesController < ApplicationController
  before_action :login_required, only: %i[list index]

  before_action :set_page_title

  # TODO: need to re-implemnet the intention of this
  permit 'site_admin', except: [:categories_list]

  active_scaffold :choice do |config|
    # Which columns to show
    config.columns = %i[label value parent children]
    config.list.columns.exclude :updated_at, :created_at

    # Column overrides
    config.columns[:label].required = true
    config.columns[:value].description = I18n.t('choices_controller.label_example')
  end

  # Ensure that the ROOT for better_nested_set isn't shown on activescaffold pages.
  def conditions_for_collection
    ['label != ?', 'ROOT']
  end

  def categories_list; end

  private

  def set_page_title
    @title = t('choices_controller.title')
  end
end
