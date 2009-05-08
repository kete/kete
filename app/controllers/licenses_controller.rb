require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

class LicensesController < ApplicationController

  before_filter :login_required
  before_filter :set_page_title
  permit "site_admin or admin of :site or tech_admin of :site"

  active_scaffold :license do |config|
    config.columns = [:name, :description, :url, :image_url, :metadata, :is_available, :is_creative_commons]
    list.columns.exclude [:updated_at, :created_at, :metadata, :description, :image_url, :is_available, :is_creative_commons, :users]
  end

  def install_license
    if params[:task]
      if LICENSE_TASKS.key?(params[:task])
        old_license_count = License.count
        ENV['RAILS_ENV'] = RAILS_ENV
        rake_result = Rake::Task["acts_as_licensed:#{params[:task]}"].execute(ENV)
        if rake_result || License.count > old_license_count
          flash[:notice] = "Successfully imported licenses."
        else
          flash[:error] = "There was a problem importing the licenses."
        end
      else
        flash[:error] = "Invalid license type."
      end
    else
      flash[:error] = "No licenses to import were selected."
    end
    redirect_to :urlified_name => 'site', :controller => 'licenses', :action => 'list'
  end

  private

  def set_page_title
    @title = 'Licenses'
  end
end
