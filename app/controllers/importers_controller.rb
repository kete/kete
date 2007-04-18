class ImportersController < ApplicationController
  permit "site_admin or admin of :current_basket"

  # fields to add
  # type of import which equates to an action
  # import_file_path
  # attachment_files_directory?
  # zoom_class to import
  def  index
  end

  # pp4 xml import for archives
  # steps:
  # grab fields xml
  # grab records
  # foreach record create content_item_hash
  # populate params item_key subhash with values from content_item_hash
  # if there is an attachment, copy file to tmp/attachment_for_imported_record
  # and add uploaded_data with that path to params
  # check if matching record exists
  # run create or update method for zoom_class
  # update creators/contributors
  # add to queue to add/update zoom
  def import
    # TODO: switch contributing user to choice
    @import_topic_type_for_related_topic = params[:import_topic_type_for_related_topic]
    @import_type = params[:import_type]
    @import_dir_path = params[:import_dir_path]
    @import_parent_dir_for_image_dirs = @import_dir_path + '/images'
    @contributing_user = User.find(1)

    case @import_type
    when 'pp4_xml'
      @zoom_class = 'StillImage'

      # prevents more than one instance of this worker from getting run
      logger.debug("what are params :" + params.to_s)
      logger.debug("what is contributing_user :" + @contributing_user.login)
      import_request = { :host => request.host,
        :protocol => request.protocol,
        :request_uri => request.request_uri }

      unless MiddleMan[:importer]
        MiddleMan.new_worker( :class => :past_perfect4_importer_worker,
                              :args => {  :zoom_class => @zoom_class,
                                :import_topic_type_for_related_topic => @import_topic_type_for_related_topic,
                                :import_type => @import_type,
                                :import_dir_path => @import_dir_path,
                                :import_parent_dir_for_image_dirs => @import_parent_dir_for_image_dirs,
                                :params => params,
                                :import_request => import_request,
                                :contributing_user => @contributing_user.id
                              },
                              :job_key => :importer )
      end
    when 'adopt_an_anzac'
      @contributing_user = User.find_by_login('anzac')
      @zoom_class = 'Topic'

      # prevents more than one instance of this worker from getting run
      logger.debug("what are params :" + params.to_s)
      logger.debug("what is contributing_user :" + @contributing_user.login)
      import_request = { :host => request.host,
        :protocol => request.protocol,
        :request_uri => request.request_uri }

      unless MiddleMan[:importer]
        MiddleMan.new_worker( :class => :adopt_an_anzac_importer_worker,
                              :args => {  :zoom_class => @zoom_class,
                                :import_topic_type_for_related_topic => @import_topic_type_for_related_topic,
                                :import_type => @import_type,
                                :import_dir_path => @import_dir_path,
                                :import_parent_dir_for_image_dirs => @import_parent_dir_for_image_dirs,
                                :params => params,
                                :import_request => import_request,
                                :contributing_user => @contributing_user.id
                              },
                              :job_key => :importer )
      end
    else
      flash[:notice] = 'Creation failed. No matching import type.'
      redirect_to :action => 'index'
    end
  end

  def get_progress
    begin
      if request.xhr?
        logger.debug("inside js")
        import_worker = MiddleMan.worker(:importer)
        if !import_worker.nil?
          records_processed = import_worker.results[:records_processed]
          render :update do |page|

            if records_processed > 0
              page.replace_html 'report_records_processed', "#{records_processed} records processed"
            end

            if import_worker.results[:done_with_do_work]
              page.replace_html 'done', "All records processed"
            end
          end
        else
          flash[:notice] = 'Import failed.'
          redirect_to :action => 'index'
        end
      else
         flash[:notice] = 'Import failed. You need javascript enabled for this feature.'
        redirect_to :action => 'index'
      end
    rescue
      # TODO: get redirect to work
      # we aren't getting to this point, might be nested begin/rescue
      # check background logs for error
      logger.info(MiddleMan.worker(:importer).results[:error])
      flash[:notice] = "Import failed. #{MiddleMan.worker(:importer).results[:error]}"
      redirect_to :action => 'index'
    end
  end
end
