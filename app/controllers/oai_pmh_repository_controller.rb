require 'oai_pmh_provider'
class OaiPmhRepositoryController < ApplicationController
  before_filter :set_page_title

  def index
    if IS_CONFIGURED && defined?(PROVIDE_OAI_PMH_REPOSITORY) && PROVIDE_OAI_PMH_REPOSITORY
      # Remove controller and action from the options.  Rails adds them automatically.
      options = params.delete_if { |k,v| %w{controller action}.include?(k) }
      provider = OaiPmhRepositoryProvider.new
      response =  provider.process_request(options)
      render :text => response, :content_type => 'text/xml'
    else
      render :text => "OAI PMH Repository not available at this time."
    end
  end

  private

  def set_page_title
    @title = 'Oai Pmh Repository'
  end
end
