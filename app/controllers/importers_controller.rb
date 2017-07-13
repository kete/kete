# feature: import related set of items from uploaded archive file (zip, tar, gzip, tar/gzip)
# title is derived from file name with _ to spaces
# we use end description template to optionally add uniform description across imported items
# base_tags are tags to be added to every item imported
class ImportersController < ApplicationController
  include WorkerControllerHelpers

  # everything else is handled by application.rb
  before_filter :login_required, only: %i[list index new_related_set_from_archive_file]

  permit 'site_admin or admin of :current_basket or tech_admin of :site', except: %i[new_related_set_from_archive_file create]

  before_filter :permitted_to_create_imports, only: %i[new_related_set_from_archive_file create]

  ### TinyMCE WYSIWYG editor stuff
  # uses_tiny_mce :only => VALID_TINYMCE_ACTIONS
  ### end TinyMCE WYSIWYG editor stuff

  # Get the Privacy Controls helper
  helper :privacy_controls

  # action menu uses a basket helper we need
  helper :baskets

  def index
    list
  end

  def list
    @imports = @current_basket.imports.paginate(page: params[:page],
                                                per_page: 10,
                                                order: 'updated_at desc')
  end

  def choose_contributing_user
    @potential_contributing_users = User.joins(:roles_user).where('roles_users.role_id in (?)', @current_basket.accepted_roles)
    @user_options = @potential_contributing_users.map { |u| [u.user_name, u.id] }
  end

  def new
    @import = Import.new
    @import.interval_between_records = 15
  end

  def new_related_set_from_archive_file
    @import = Import.new
    @import.import_archive_file = ImportArchiveFile.new

    @related_topic = Topic.find(params[:relate_to_topic])
  end

  def create
    @import = Import.new(params[:import])
    @import.basket_id = @current_basket.id

    if importing_archive_file?
      # this a related set of items from archive file import so set some defaults
      @related_topic = Topic.find(params[:related_topic])
      @import.topic_type_id = @related_topic.topic_type_id
      @import.xml_type = 'related_set_from_archive_file'
      @import.directory = Time.now.utc.xmlschema
      @import.interval_between_records = 5
    end

    # because the import archive file import can be used non-admins with cetain settings
    # we cannot simply rely on what we get in params, we need to check/override it
    @import.user_id = (@site_admin && params[:contributing_user].present?) ? User.find(params[:contributing_user]).id : current_user.id
    @import.private = false unless @import.private.present? && @current_basket.show_privacy_controls_with_inheritance?

    @import.file_private = false unless @import.file_private.present? && @current_basket.show_privacy_controls_with_inheritance?

    if @import.save
      if importing_archive_file?
        # mkdir the target directory
        # we decompress the files into a directory named after the timestamp
        # for example imports/20080509160835
        import_directory_path = ::Import::IMPORTS_DIR + @import.directory
        Dir.mkdir(import_directory_path) unless File.exist?(import_directory_path)

        @import.reload
        @import_archive_file = ImportArchiveFile.create!(params.delete(:import_archive_file).merge(import_id: @import.id))
      end

      @worker_type = "#{@import.xml_type}_importer_worker".to_sym
      @worker_key = worker_key_for(@worker_type)

      @zoom_class = case @import.xml_type
                    when 'past_perfect4'          then 'StillImage'
                    when 'fmpdsoresult_no_images' then 'Topic'
                    else
                      (only_valid_zoom_class(params[:zoom_class]).name || 'StillImage')
                    end

      # only run one import at a time for the moment
      unless backgroundrb_is_running?(@worker_type)
        MiddleMan.new_worker(worker: @worker_type, worker_key: @worker_key)
        import_request = { host: request.host, protocol: request.protocol, request_uri: request.original_url }
        MiddleMan.worker(@worker_type, @worker_key).async_do_work(arg: { zoom_class: @zoom_class,
                                                                         import: @import.id,
                                                                         params: params,
                                                                         import_request: import_request })

        # fixing failure due to unnecessary loading of tiny_mce
        @do_not_use_tiny_mce = true
      else
        flash[:notice] = t('importers_controller.create.already_running')
        if @related_topic
          redirect_to_show_for(@related_topic)
        else
          redirect_to action: 'list'
        end
      end
    else
      if importing_archive_file?
        render action: 'new_related_set_from_archive_file'
      else
        render action: 'new'
      end
    end
  end

  def get_progress
    if !request.xhr?
      flash[:notice] = t('importers_controller.get_progress.import_failed')
      redirect_to action: 'list'
    else
      @worker_type = params[:worker_type].to_sym
      @worker_key = worker_key_for(@worker_type)
      status = MiddleMan.worker(@worker_type, @worker_key).ask_result(:results)
      begin
        if !status.blank?
          records_processed = status[:records_processed]
          related_topic = Topic.find(params[:related_topic]) unless params[:related_topic].blank?

          render :update do |page|
            if records_processed > 0
              page.replace_html 'report_records_processed', t('importers_controller.get_progress.amount_processed',
                                                              records_processed: records_processed)
            end

            if status[:done_with_do_work] == true or !status[:error].blank?
              done_message = t('importers_controller.get_progress.all_processed')

              if !status[:error].blank?
                done_message = t('importers_controller.get_progress.error_message', error: status[:error].gsub("\n", '<br />'))
              end
              page.hide('spinner')
              page.replace_html 'done', done_message
              unless params[:related_topic].blank?
                page.replace_html('exit', '<p>' + link_to(t('importers_controller.get_progress.back_to', item_title: related_topic.title),
                                                          action: 'show',
                                                          controller: 'topics',
                                                          id: related_topic) + '</p>')
              else
                page.replace_html 'exit', '<p>' + link_to(t('importers_controller.get_progress.to_imports'), action: 'list') + '</p>'
              end
            end
          end
        else
          message = t('importers_controller.get_progress.import_failed')
          flash[:notice] = message
          render :update do |page|
            page.hide('spinner')
            unless params[:related_topic].blank?
              page.replace_html 'done', '<p>' + message + ' ' + link_to(t('importers_controller.get_progress.to_related_topics'),
                                                                        action: 'show',
                                                                        controller: 'topics',
                                                                        id: params[:related_topic]) + '</p>'
            else
              page.replace_html 'done', '<p>' + message + ' ' + link_to(t('importers_controller.get_progress.to_imports'), action: 'list') + '</p>'
            end
          end
        end
      rescue
        # we aren't getting to this point, might be nested begin/rescue
        # check background logs for error
        import_error = !status.blank? ? status[:error] : t('importers_controller.get_progress.not_running')
        logger.info(import_error)
        message = t('importers_controller.get_progress.import_failed', error: import_error)
        message += " - #{$!}" unless $!.blank?
        flash[:notice] = message
        render :update do |page|
          page.hide('spinner')
          unless params[:related_topic].blank?
            page.replace_html 'done', '<p>' + message + ' ' + link_to(t('importers_controller.get_progress.to_related_topics'),
                                                                      action: 'show',
                                                                      controller: 'topics',
                                                                      id: params[:related_topic]) + '</p>'
          else
            page.replace_html 'done', '<p>' + message + ' ' + link_to(t('importers_controller.get_progress.to_imports'), action: 'list') + '</p>'
          end
        end
      end
    end
  end

  def stop
    @worker_type = params[:worker_type].to_sym
    MiddleMan.worker(@worker_type, @worker_type.to_s).delete

    Import.find(params[:id]).update_attributes(status: 'stopped')

    flash[:notice] = t('importers_controller.stop.import_stopped')
    redirect_to action: 'list'
  end

  def fetch_applicable_extended_fields
    render partial: 'extended_field_selection', locals: {
      id: params[:id],
      zoom_class: params[:zoom_class],
      topic_type_id: params[:topic_type_id]
    }
  end

  private

  def importing_archive_file?
    (params[:related_topic].present? && params[:import_archive_file].present? && params[:import_archive_file][:uploaded_data].present?)
  end

  def permitted_to_create_imports
    if params[:action] == 'create' && !importing_archive_file?
      # if we aren't creating an import for archive sets, the rules of who can access the 'new' action apply
      user_is_authorized = permit?('site_admin or admin of :current_basket or tech_admin of :site')
    else
      user_is_authorized = current_user_can_import_archive_sets?
    end

    unless user_is_authorized
      flash[:error] = t('importers_controller.permitted_to_create_imports.not_authorized')
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end
end
