require "importer_zoom"
class ZoomIndexRebuildWorker < BackgrounDRb::MetaWorker
  set_worker_name :zoom_index_rebuild_worker
  set_no_auto_load true

  # for prepare_to_zoom, etc.
  include ImporterZoom

  def create(args = nil)
    results = { :do_work_time => Time.now.utc.to_s,
      :done_with_do_work => false,
      :done_with_do_work_time => nil,
      :records_processed => 0,
      :records_skipped => 0,
      :records_failed => 0 }

    cache[:results] = results
  end

  def do_work(args = nil)
    begin
      # start from scratch
      @last_id = nil
      @done = false
      @record_count = 0
      @skipped_record_count = 0
      @failed_record_count = 0

      # this is what we update status with
      @results = cache[:results]

      @zoom_class = args[:zoom_class]
      @start_id = args[:start_id]
      @end_id = args[:end_id]
      @skip_existing = args[:skip_existing]
      @skip_private = args[:skip_private]
      @clear_zebra = args[:clear_zebra]

      @public_zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')
      @private_zoom_db = @skip_private ? nil : ZoomDb.find_by_host_and_database_name('localhost','private')

      # a bit of a misnomer
      # but will allow us to use importer lib oai record rendering unaltered
      @import_request = args[:import_request]

      classes_to_rebuild = @zoom_class != 'all' ? @zoom_class.to_a : ZOOM_CLASSES

      if @zoom_class == 'all'
        raise "Specifying a start id is not supported when you are rebuilding all types of items." if @start_id != 'first'
        raise "Specifying an end id is not supported when you are rebuilding all types of items." if @end_id != 'last'
      end

      raise "Erasing all existing search records is only allowed when you are starting from first record and ending with last record." if @clear_zebra && @start_id != 'first' || @end_id != 'last'
      raise "Start must be a valid item id number." if @start_id != 'first' && @start_id.to_i == 0
      raise "End must be a valid item id number." if @end_id != 'last' && @end_id.to_i ==  0

      # reset the zebra dbs to no records
      # the zebra:stop task is problematic on some platforms (known issue with solaris 10)
      # so you may want to do this bit by hand (before you request that this worker starts)
      if @clear_zebra
        logger.info("in clear zebra")
        `rake zebra:init`
        # do the private zebra db, too if we should
        `rake zebra:init ZEBRA_DB=private` unless @skip_private

        # we stop and start zebra so that any changes to configuration files
        # (maybe the case with upgrades)
        # are loaded
        `rake zebra:stop`
        `rake zebra:start`
      end

      # add the bootstrap records
      # we always do this to handle upgrades (before the bootstrap records existed)
      # the rake task will skip the records if they already exist
      `rake zebra:load_initial_records`

      clause = "id >= :start_id"
      clause_values = Hash.new

      unless @start_id.to_s == 'first'
        clause_values[:start_id] = @start_id
      end

      unless @end_id.to_s == 'last'
        clause += " and id <= :end_id"
        clause_values[:end_id] = @end_id
      end

      # we wait to open the connection to last reasonable moment
      @public_zoom_connection = @public_zoom_db.open_connection
      @private_zoom_connection = @skip_private ? nil : @private_zoom_db.open_connection

      classes_to_rebuild.each do |class_name|
        logger.info("Starting #{class_name}")

        @results[:current_zoom_class] = class_name
        cache[:results] = @results

        the_class = only_valid_zoom_class(class_name)

        # skip to next class if there are no items
        if the_class.count == 0
          next
          logger.info("Done with #{class_name}")
        end

        clause_values[:start_id] = the_class.find(:first, :select => 'id').id if @start_id.to_s == 'first'

        the_class.find(:all, :conditions => [clause, clause_values], :order => 'id').each do |item|
          logger.info(item.id.to_s)

          if @skip_existing
            # test if it's in there first
            # set virtual attribute that is is need by zoom_id call
            item.basket_urlified_name = item.basket.urlified_name
            if @public_zoom_db.has_zoom_record?(item.zoom_id, @public_zoom_connection) || (@skip_private == false && @private_zoom_db.has_zoom_record?(item.zoom_id, @private_zoom_connection))
              @skipped_record_count += 1
              @results[:records_skipped] = @skipped_record_count
              cache[:results] = @results
              logger.info("skipped")
              next
            end
          end

          prepare_and_save_to_zoom(item)

          if @public_zoom_db.has_zoom_record?(item.zoom_id, @public_zoom_connection) || (@skip_private == false && @private_zoom_db.has_zoom_record?(item.zoom_id, @private_zoom_connection))
            @record_count += 1
            @results[:records_processed] = @record_count
            cache[:results] = @results
            logger.info("added")
          else
            @failed_record_count += 1
            @results[:records_failed] = @failed_record_count
            cache[:results] = @results
            logger.info("failed: " + item.inspect)
          end

          @last_id = item.id
          @results[:last_id] = @last_id
          cache[:results] = @results
        end

        logger.info("Done with #{class_name}")
      end
      @results[:done_with_do_work] = true
      @results[:done_with_do_work_time] = Time.now.utc.to_s
      cache[:results] = @results
      logger.info("what is cache[:results]: #{cache[:results].inspect}")
      stop_worker
    rescue
      error_message = $!.to_s
      logger.info("rebuild failed: #{error_message}")
      @results[:error] = error_message
      @results[:done_with_do_work] = true
      @results[:done_with_do_work_time] = Time.now.utc.to_s
      cache[:results] = @results
      stop_worker
    end
  end

  def prepare_and_save_to_zoom(item)
    # This is always the public version..
    unless item.already_at_blank_version? || item.at_placeholder_public_version?
      importer_prepare_zoom(item)
      item.zoom_save(@public_zoom_connection) unless item.is_a?(Comment) && item.commentable_private
    end

    # Redo the save for the private version
    if @skip_private == false &&
        (item.respond_to?(:private) && item.has_private_version? && !item.private?) ||
        (item.is_a?(Comment) && item.commentable_private)

      item.private_version do
        unless item.already_at_blank_version?
          importer_prepare_zoom(item)
          item.zoom_save(@private_zoom_connection)
        end
      end

      raise "Could not return to public version" if item.private? && !item.is_a?(Comment)

    end
  end

  def stop_worker
    exit
  end

end
