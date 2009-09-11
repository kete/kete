require "importer"
# generic simple topic importer
# must have xml_to_record_path specified
# in the Import object
# uses the default Importer methods
class RelatedSetFromArchiveFileImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :related_set_from_archive_file_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
  end

  # redefine do_work
  def do_work(args = nil)
    logger.info('in work')
    begin
      @zoom_class = args[:zoom_class]
      @import = Import.find(args[:import])
      @import_type = @import.xml_type
      @import_dir_path = ::Import::IMPORTS_DIR + @import.directory
      @contributing_user = @import.user
      @import_request = args[:import_request]
      @description_end_templates['default'] = @import.default_description_end_template
      @current_basket = @import.basket
      @import_topic_type = @import.topic_type
      @zoom_class_for_params = @zoom_class.tableize.singularize
      @xml_path_to_record ||= @import.xml_path_to_record
      @record_interval = @import.interval_between_records

      params = args[:params]
      @related_topic = Topic.find(params[:related_topic])

      # get files in directory
      # first figure out the name of the directory
      import_directory = ::Import::IMPORTS_DIR + @import.directory
      archive_filename_without_extension = File.basename(@import.import_archive_file.filename, File.extname(@import.import_archive_file.filename))
      base_directory = import_directory + '/' + archive_filename_without_extension

      # handle case where included directory name has spaces rather than underscores
      # won't handle case where mix of spaces and underscores is in directory name
      base_directory = import_directory + '/' + archive_filename_without_extension.gsub("_", " ") unless File.exist?(base_directory) && File.directory?(base_directory)

      # working instance when a containing directory isn't included in zip file
      # variations in zip programs seem to result in the directory being lots in uncompressing step
      # other times people just forget to do that step
      base_directory = import_directory unless File.exist?(base_directory) && File.directory?(base_directory)

      # variables assigned, files good to go, we're started
      @import.update_attributes(:status => 'in progress')

      # work through records and add topics for each
      # if they don't already exist
      @results[:records_processed] = 0
      Dir.foreach(base_directory) do |record|
        # only do files, not recursive
        full_path_to_record = base_directory + '/' + record
        # ignore directories and hidden files
        # shouldn't be necessary to handle __MACOSX because it is a directory, but...
        not_wanted = File.basename(full_path_to_record).first == "." || File.directory?(full_path_to_record) || record == '__MACOSX'
        importer_process(full_path_to_record, params) unless not_wanted
      end
      importer_update_processing_vars_at_end
    rescue
      importer_update_processing_vars_if_rescue
    end
  end

  # override of what is found in lib/importer
  # takes a file
  def importer_process(record, params)
    current_record = @results[:records_processed] + 1
    logger.info("starting record #{current_record}")

    placeholder_title = File.basename(record, File.extname(record)).gsub('_', ' ')
    # placeholder title will only be used if there isn't an embedded title
    record_hash = { 'placeholder_title' => placeholder_title, 'path_to_file' => record }
    reason_skipped = nil

    new_record = nil

    description_end_template = @description_end_templates['default']
    new_record = create_new_item_from_record(record, @zoom_class, {:params => params, :record_hash => record_hash, :description_end_template => description_end_template })

    if !new_record.nil? and !new_record.id.nil?
      logger.info("new record succeeded for insert")

      # add relation to related_topic
      ContentItemRelation.new_relation_to_topic(@related_topic.id, new_record)

      # update the last topic, since we are done adding things to it for now
      @related_topic.prepare_and_save_to_zoom

      # update the actual add record
      new_record.prepare_and_save_to_zoom
      importer_update_records_processed_vars
    end

    # if this record was skipped, add to skipped_records
    if !reason_skipped.blank?
      importer_log_to_skipped_records(title,reason_skipped)
    end
    # will this help memory leaks
    record = nil
    # give zebra and our server a small break
    sleep(@record_interval) if @record_interval > 0
  end

end
