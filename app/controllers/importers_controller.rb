# feature: import related set of items from uploaded archive file (zip, tar, gzip, tar/gzip)
# title is derived from file name with _ to spaces
# we use end description template to optionally add uniform description across imported items
# base_tags are tags to be added to every item imported
class ImportersController < ApplicationController
  include WorkerControllerHelpers

  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index, :new_related_set_from_archive_file]

  permit "site_admin or admin of :current_basket or tech_admin of :site", :except => [:new_related_set_from_archive_file, :create]

  permit "site_admin or admin of :current_basket or tech_admin of :site or member of :current_basket or moderater of :current_basket", :only => [:new_related_set_from_archive_file, :create]

  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce(:options => { :theme => 'advanced',
                  :mode => "textareas",
                  :convert_urls => false,
                  :content_css => "/stylesheets/kete.css",
                  :remove_script_host => true,
                  :theme_advanced_toolbar_location => "top",
                  :theme_advanced_toolbar_align => "left",
                  :theme_advanced_resizing => true,
                  :theme_advanced_resize_horizontal => false,
                  :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo code},
                  :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect pastetext pasteword selectall },
                  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
                  :editor_selector => 'mceEditor',
                  :paste_create_paragraphs => true,
                  :paste_create_linebreaks => true,
                  :paste_use_dialog => true,
                  :paste_auto_cleanup_on_paste => true,
                  :paste_convert_middot_lists => false,
                  :paste_unindented_list_class => "unindentedList",
                  :paste_convert_headers_to_strong => true,
                  :paste_insert_word_content_callback => "convertWord",
                  :plugins => %w{ contextmenu paste table fullscreen} },
                :only => [:new, :new_related_set_from_archive_file])
  ### end TinyMCE WYSIWYG editor stuff

  # Get the Privacy Controls helper
  helper :privacy_controls

  def  index
    list
  end

  def list
    @imports = @current_basket.imports.paginate(:page => params[:page],
                                                :per_page => 10,
                                                :order => 'updated_at desc')
  end

  def choose_contributing_user
    @potential_contributing_users = User.find(:all,
                                              :joins => "join roles_users on users.id = roles_users.user_id",
                                              :conditions => ["roles_users.role_id in (?) and users.id <> #{@current_user.id}",
                                                              @current_basket.accepted_roles])

    @user_options = @potential_contributing_users.map { |u| [u.user_name, u.id] }
  end

  def new
    @import = Import.new
    @import.interval_between_records = 15
  end

  def new_related_set_from_archive_file
    new
    @import.interval_between_records = 5
    @import.import_archive_file = ImportArchiveFile.new
    @related_topic = Topic.find(params[:relate_to_topic])
    @zoom_class = only_valid_zoom_class(params[:zoom_class]).name || 'StillImage'
  end

  def create
    @import = Import.new(params[:import])

    if !params[:import_archive_file].nil? && !params[:import_archive_file][:uploaded_data].blank? && !params[:related_topic].blank?
      # this a related set of items from archive file import
      # we decompress the files into a directory named after the timestamp
      # for example imports/20080509160835
      # prep the directory, but we'll decompress into it further down the track
      @related_topic = Topic.find(params[:related_topic])

      # we'll update this with actual directory after we unpack import_archive_file
      @import.xml_type = 'related_set_from_archive_file'
      @import.topic_type = @related_topic.topic_type
      @zoom_class = only_valid_zoom_class(params[:zoom_class]).name
    else
      params[:related_topic] = nil
    end

    if @import.save
      import_request = { :host => request.host,
        :protocol => request.protocol,
        :request_uri => request.request_uri }

      unless params[:import_archive_file].nil? || params[:import_archive_file][:uploaded_data].blank?
        @import.reload
        @import_archive_file = ImportArchiveFile.new(params[:import_archive_file].merge(:import_id => @import.id))
        # mkdir the target directory
        import_directory_path = ::Import::IMPORTS_DIR + @import.directory
        Dir.mkdir(import_directory_path) unless File.exist?(import_directory_path)
        @import_archive_file.save!
        # now that we have creatd the import_archive_file object, delete marshalled data from params
        # otherwise we can pass it to the import worker
        params.delete(:import_archive_file)
      end

      @worker_type = "#{@import.xml_type}_importer_worker".to_sym

      case @import.xml_type
      when 'past_perfect4'
        @zoom_class = 'StillImage'
      when 'fmpdsoresult_no_images'
        @zoom_class = 'Topic'
      when 'simple_topic'
        @zoom_class = 'Topic'
      end

      # only run one import at a time for the moment
      unless backgroundrb_is_running?(@worker_type)
        MiddleMan.new_worker( :worker => @worker_type, :worker_key => @worker_type.to_s )
        MiddleMan.worker(@worker_type, @worker_type.to_s).async_do_work( :arg => { :zoom_class => @zoom_class,
                                                                                   :import => @import.id,
                                                                                   :params => params,
                                                                                   :import_request => import_request } )

        # fixing failure due to unnecessary loading of tiny_mce
        @do_not_use_tiny_mce = true
      else
        flash[:notice] = 'There is another import of this type running at this time.  Please try again later.'
        if !params[:related_topic].blank?
          redirect_to_show_for(@related_topic)
        else
          redirect_to :action => 'list'
        end
      end
    else
      if !params[:related_topic].blank?
        render(:action => 'new_related_set_from_archive_file',
               :contributing_user => params[:import][:user_id],
               :related_topic => params[:related_topic],
               :zoom_class => params[:zoom_class]
               )
      else
        render :action => 'new', :contributing_user => params[:import][:user_id]
      end
    end
  end

  def get_progress
    if !request.xhr?
      flash[:notice] = 'Import failed. You need javascript enabled for this feature.'
      redirect_to :action => 'list'
    else
      @worker_type = params[:worker_type].to_sym
      status = MiddleMan.worker(@worker_type, @worker_type.to_s).ask_result(:results)
      begin
        if !status.blank?
          records_processed = status[:records_processed]
          related_topic = Topic.find(params[:related_topic]) unless params[:related_topic].blank?

          render :update do |page|

            if records_processed > 0
              page.replace_html 'report_records_processed', "#{records_processed} records processed"
            end

            if status[:done_with_do_work] == true or !status[:error].blank?
              done_message = "All records processed."

              if !status[:error].blank?
                done_message = "There was a problem with the import: #{status[:error]}<p><b>The import has been stopped</b></p>"
              end
              page.hide("spinner")
              page.replace_html 'done', done_message
              unless params[:related_topic].blank?
                page.replace_html('exit', '<p>' + link_to("Back to #{related_topic.title}",
                                                          :action => 'show',
                                                          :controller => 'topics',
                                                          :id => related_topic) + '</p>')
              else
                page.replace_html 'exit', '<p>' + link_to('Back to Imports', :action => 'list') + '</p>'
              end
            end
          end
          expire_related_caches_for(related_topic) if !params[:related_topic].blank? && (status[:done_with_do_work] == true or !status[:error].blank?)
        else
          message = "Import failed."
          flash[:notice] = message
          render :update do |page|
            page.hide("spinner")
            unless params[:related_topic].blank?
              page.replace_html 'done', '<p>' + message + ' ' + link_to("Return to related topic.",
                                                                        :action => 'show',
                                                                        :controller => 'topics',
                                                                        :id => params[:related_topic]) + '</p>'
            else
              page.replace_html 'done', '<p>' + message + ' ' + link_to('Return to Imports', :action => 'list') + '</p>'
            end
          end
        end
      rescue
        # we aren't getting to this point, might be nested begin/rescue
        # check background logs for error
        import_error = !status.blank? ? status[:error] : "import worker not running anymore?"
        logger.info(import_error)
        message = "Import failed. #{import_error}"
        message += " - #{$!}" unless $!.blank?
        flash[:notice] = message
        render :update do |page|
          page.hide("spinner")
          unless params[:related_topic].blank?
            page.replace_html 'done', '<p>' + message + ' ' + link_to("Return to related topic.",
                                                                      :action => 'show',
                                                                      :controller => 'topics',
                                                                      :id => params[:related_topic])  + '</p>'
          else
            page.replace_html 'done', '<p>' + message + ' ' + link_to('Return to Imports', :action => 'list') + '</p>'
          end
        end
      end
    end
  end

  def stop
    @worker_type = params[:worker_type].to_sym
    MiddleMan.worker(@worker_type, @worker_type.to_s).delete

    Import.find(params[:id]).update_attributes(:status => 'stopped')

    flash[:notice] = 'Import stopped.'
    redirect_to :action => 'list'
  end
end
