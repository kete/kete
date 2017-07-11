# require 'oai_pmh_provider'
class OaiPmhRepositoryController < ApplicationController
  before_filter :set_page_title

  def index
    if SystemSetting.is_configured? && defined?(SystemSetting.provide_oai_pmh_repository) && SystemSetting.provide_oai_pmh_repository
      # Remove controller and action from the options.  Rails adds them automatically.
      options = params.delete_if { |k, v| %w{controller action}.include?(k) }
      provider = OaiPmhRepositoryProvider.new
      response = provider.process_request(options)
      render text: response, content_type: 'text/xml'
    else
      render text: t('oai_pmh_repository_controller.not_available')
    end
  end

  private

  def set_page_title
    @title = t('oai_pmh_repository_controller.title')
  end
end
