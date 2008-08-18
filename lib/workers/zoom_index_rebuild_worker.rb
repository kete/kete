require "importer_zoom"
class ZoomIndexRebuildWorker < BackgrounDRb::MetaWorker
  set_worker_name :zoom_index_rebuild_worker
  set_no_auto_load true

  # for prepare_to_zoom, etc.
  include ImporterZoom

  def create(args = nil)
    @results = { :do_work_time => Time.now.to_s,
      :done_with_do_work => false,
      :records_processed => 0,
      :records_failed => 0 }

    cache[:results] = @results
  end

  def do_work(args = nil)
    # start from scratch
    @last_id = nil
    @done = false
    @record_count = 0
    @failed_record_count = 0

    @zoom_class = args[:zoom_class]
    @start_id = args[:start_id]
    @end_id = args[:end_id]
    @skip_existing = args[:skip_existing]
    @skip_private = args[:skip_private]

    @public_zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')
    @private_zoom_db = @skip_private ? nil : ZoomDb.find_by_host_and_database_name('localhost','public')

    # a bit of a misnomer
    # but will allow us to use importer lib oai record rendering unaltered
    @import_request = args[:import_request]

    classes_to_rebuild = @zoom_class != 'all' ? @zoom_class.to_a : ZOOM_CLASSES

    if @zoom_class == 'all'
      raise "Specifying a start id is not supported when you are rebuilding all types of items." if @start_id != 'first'
      raise "Specifying an end id is not supported when you are rebuilding all types of items." if @end_id != 'end'
    end

    clause = "id >= :start_id"
    unless @start_id.to_s == 'first'
      clause_values[:start_id] = @start_id
    end

    unless @end_id.to_s == 'end'
      clause += " and id <= :end_id"
      clause_values[:end_id] = @end_id
    end

    # don't include items that are flagged pending or placeholder public versions
    clause += " and title != :pending_title"
    clause_values[:pending_title] = BLANK_TITLE

    # we wait to open the connection to last reasonable moment
    @public_zoom_connection = @public_zoom_db.open_connection
    @private_zoom_connection = @skip_private ? nil : @private_zoom_db.open_connection

    classes_to_rebuild.each do |class_name|
      logger.info("Starting #{class_name}")

      the_class = only_valid_zoom_class(class_name)

      clause_values[:start_id] = the_class.find(:first, :select => 'id').id if clause_values[:start_id].blank?

      the_class.find(:all, :conditions => [clause, clause_values], :order => 'id').each do |item|

        @result_message = zoom_update_and_test(@item,@zoom_db)

        @record_count += 1
        cache[:results][:records_processed] = @record_count

        @failed_record_count += 1
        cache[:results][:records_failed] = @failed_record_count

        @last_id = item.id
        cache[:results][:last_id] = @last_id
        logger.info(id.to_s)
      end

      logger.info("Done with #{class_name}")
    end

    cache[:results][:done_with_do_work] = true
  end

  def zoom_update_and_test(item,zoom_connection)
    item_class = item.class.name

    if @skip_existing.nil? and @skip_existing == true
      # test if it's in there first
      if @public_zoom_db.has_zoom_record?(item.zoom_id, @public_zoom_connection) || @private_zoom_db.has_zoom_record?(item.zoom_id, @private_zoom_connection)
        return "skipping existing: search record exists: #{item_class} : #{item.id}"
      end
    end

    # if not, add it
    importer_prepare_zoom(item)

    prepare_and_save_to_zoom(item)

    # confirm that it's now available
    if item.has_appropriate_zoom_records?
      return "successfully updated search: #{item_class} : #{item.id}"
    else
      return "failed to add to search: #{item_class} : #{item.id} not found in search index or perhaps the item is pending."
    end
  end

end
