class ImportersController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :current_basket or tech_admin of :site"

  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce(:options => { :theme => 'advanced',
                  :browsers => %w{ msie gecko safaris},
                  :mode => "textareas",
                  :cleanup => false,
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
                :only => [:new])
  ### end TinyMCE WYSIWYG editor stuff

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

  def create
    @import = Import.new(params[:import])
    if @import.save
      import_request = { :host => request.host,
        :protocol => request.protocol,
        :request_uri => request.request_uri }

      case @import.xml_type
      when 'past_perfect4'
        @worker_type = :past_perfect4_importer_worker
        @zoom_class = 'StillImage'
      when 'fmpdsoresult_no_images'
        @worker_type = :fmpdsoresult_no_images_importer_worker
        @zoom_class = 'Topic'
      when 'simple_topic'
        @worker_type = :simple_topic_importer_worker
        @zoom_class = 'Topic'
      else
        flash[:notice] = 'Creation failed. No matching import type.'
        redirect_to :action => 'index'
      end

      worker_name_with_job_key = @worker_type.to_s + '_importer'
      worker_name_with_job_key = worker_name_with_job_key.to_sym

      if !MiddleMan.query_all_workers.keys.include?(worker_name_with_job_key)
        MiddleMan.new_worker(:worker => @worker_type, :job_key => :importer)
        MiddleMan.ask_work( :worker => @worker_type,
                            :job_key => :importer,
                            :worker_method => :do_work,
                            :data => {
                              :zoom_class => @zoom_class,
                              :import => @import.id,
                              :params => params,
                              :import_request => import_request } )

      else
        flash[:notice] = 'There is another import running at this time.  Please try back later.'
        redirect_to :action => 'list'
      end
    else
      render :action => 'new', :contributing_user => params[:import][:user_id]
    end
  end

  def get_progress
    begin
      status = MiddleMan.ask_status(:worker => params[:worker_type].to_sym, :job_key => :importer)
      if !status.nil?
        logger.debug("status: " + status.inspect)
        if request.xhr?
          logger.debug("inside js")
          records_processed = status[:records_processed]
          render :update do |page|

            if records_processed > 0
              page.replace_html 'report_records_processed', "#{records_processed} records processed"
            end

            if status[:done_with_do_work] == true or !status[:error].blank?
              done_message = "All records processed."

              # delete worker and redirect to results in basket
              MiddleMan.delete_worker(:worker => params[:worker_type].to_sym, :job_key => :importer)

              if !status[:error].blank?
                done_message = "There was a problem with the import: #{status[:error]}<p><b>The import has been stopped</b></p>"
              end
              page.hide("spinner")
              page.replace_html 'done', done_message
              page.replace_html 'exit', '<p>' + link_to('Back to Imports', :action => 'list') + '</p>'
            end
          end
        else
          flash[:notice] = 'Import failed. You need javascript enabled for this feature.'
          redirect_to :action => 'list'
        end
      else
        flash[:notice] = 'Import failed.'
        redirect_to :action => 'list'
      end
    rescue
      # TODO: get redirect to work
      # we aren't getting to this point, might be nested begin/rescue
      # check background logs for error
      import_error = !status.nil? ? status[:error] : "import worker not running anymore?"
      logger.info(import_error)
      flash[:notice] = "Import failed. #{import_error}"
      redirect_to :action => 'index'
    end
  end

  def stop
    # TODO: this doesn't quite do the job, not sure why
    @worker_type = params[:worker_type]
    @worker_type = @worker_type.to_sym
    MiddleMan.delete_worker(:worker => @worker_type , :job_key => :importer)

    Import.find(params[:id]).update_attributes(:status => 'stopped')

    flash[:notice] = 'Import stopped.'
    redirect_to :action => 'list'
  end
end
