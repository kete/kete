require 'rake'
# require 'rake/rdoctask'
# require 'rake/testtask'
# require 'tasks/rails'

class LicensesController < ApplicationController
  before_filter :login_required
  before_filter :set_page_title
  before_filter :prepare_available_licenses
  permit 'site_admin or admin of :site or tech_admin of :site'

  active_scaffold :license do |config|
    config.columns = [:name, :description, :url, :image_url, :metadata, :is_available, :is_creative_commons]
    config.list.columns = [:id, :name, :url]

    config.columns[:metadata].options = { rows: 5 }
  end

  def install_license
    if params[:task]
      if @available_licenses.include?(params[:task])
        old_license_count = License.count
        ENV['RAILS_ENV'] = Rails.env
        rake_result = Rake::Task["acts_as_licensed:import:#{params[:task]}"].execute(ENV)
        if rake_result || License.count > old_license_count
          flash[:notice] = t('licenses_controller.install_license.imported')
        else
          flash[:error] = t('licenses_controller.install_license.problem_importing')
        end
      else
        flash[:error] = t('licenses_controller.install_license.invalid_import')
      end
    else
      flash[:error] = t('licenses_controller.install_license.no_import')
    end
    redirect_to urlified_name: @site_basket.urlified_name, controller: 'licenses', action: 'list'
  end

  private

  def set_page_title
    @title = t('licenses_controller.title')
  end

  def prepare_available_licenses
    @available_licenses = Rake.application.tasks
                              .collect { |task| task.name =~ /acts_as_licensed:import:(\w+)$/ ? $1 : nil }.compact
  end
end
