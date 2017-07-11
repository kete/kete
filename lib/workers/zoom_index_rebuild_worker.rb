require 'zoom_controller_helpers'
class ZoomIndexRebuildWorker < BackgrounDRb::MetaWorker
  set_worker_name :zoom_index_rebuild_worker
  set_no_auto_load true

  # for prepare_to_zoom, etc.
  include ZoomControllerHelpers

  def create(args = nil)
    results = { do_work_time: Time.now.utc.to_s,
      done_with_do_work: false,
      done_with_do_work_time: nil,
      records_processed: 0,
      records_skipped: 0,
      records_failed: 0 }

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

      @public_zoom_db = ZoomDb.find_by_database_name('public')
      @private_zoom_db = @skip_private ? nil : ZoomDb.find_by_database_name('private')

      if args[:use_zebraidx]
        @use_zebraidx = args[:use_zebraidx]
      else
        if @public_zoom_db.host == 'localhost' &&
            (@skip_private ||
             (@private_zoom_db &&
              @private_zoom_db.host == 'localhost'))
          @use_zebraidx = true
        else
          @use_zebraidx = false
        end
      end

      ENV['SKIP_PRIVATE'] = 'true' if @skip_private && @use_zebraidx

      # a bit of a misnomer
      # but will allow us to use importer lib oai record rendering unaltered
      @import_request = args[:import_request]

      classes_to_rebuild = @zoom_class != 'all' ? @zoom_class.to_a : ZOOM_CLASSES

      if @zoom_class == 'all'
        raise 'Specifying a start id is not supported when you are rebuilding all types of items.' if @start_id != 'first'
        raise 'Specifying an end id is not supported when you are rebuilding all types of items.' if @end_id != 'last'
      end

      raise 'Specifying skip existing records is not supported when you are using the faster rebuild option.' if @skip_existing && @use_zebraidx

      raise 'Erasing all existing search records is only allowed when you are starting from first record and ending with last record.' if @clear_zebra && @start_id != 'first' || @end_id != 'last'
      raise 'Start must be a valid item id number.' if @start_id != 'first' && @start_id.to_i == 0
      raise 'End must be a valid item id number.' if @end_id != 'last' && @end_id.to_i ==  0

      # Rake::Task is available inside Rails, but not backgroundrb workers
      # so we need to include rake and load the task(s) we need to use
      require 'rake'
      load File.join(Rails.root, 'lib', 'tasks', 'zebra.rake')

      # reset the zebra dbs to no records
      # the zebra:stop task is problematic on some platforms (known issue with solaris 10)
      # so you may want to do this bit by hand (before you request that this worker starts)
      # Note: this step is delayed when @use_zebraidx is true
      # until just before indexing, so that users can use search/browsing for longest time
      use_rake_to_clear_zebra if @clear_zebra

      # add the bootstrap records
      # we always do this to handle upgrades (before the bootstrap records existed)
      # the rake task will skip the records if they already exist
      Rake::Task['zebra:load_initial_records'].execute(ENV)

      clause = 'id >= :start_id'
      clause_values = Hash.new

      unless @start_id.to_s == 'first'
        clause_values[:start_id] = @start_id
      end

      unless @end_id.to_s == 'last'
        clause += ' and id <= :end_id'
        clause_values[:end_id] = @end_id
      end

      # we wait to open the connection to last reasonable moment
      unless @use_zebraidx
        @public_zoom_connection = @public_zoom_db.open_connection
        @private_zoom_connection = @skip_private ? nil : @private_zoom_db.open_connection
      end

      classes_to_rebuild.each do |class_name|
        logger.info("Starting #{class_name}")

        @results[:current_zoom_class] = class_name
        cache[:results] = @results

        the_class = only_valid_zoom_class(class_name)
        the_class_count = the_class.count
        # skip to next class if there are no items
        if the_class_count == 0
          next
          logger.info("Done with #{class_name}")
        end

        clause_values[:start_id] = the_class.find(:first, select: 'id').id if @start_id.to_s == 'first'

        # this will only load up to 1k results into memory at a time
        batch_count = 1
        batch_size = 500 # 1000 is default in find_in_batches

        # find_in_batches messes up oai_record call for some reason, cobblying our own offset system
        class_count_so_far = 0
        while the_class_count > class_count_so_far
          if class_count_so_far > 0
            clause_values[:start_id] = the_class.find(:first,
                                                     select: 'id',
                                                     conditions: "id > #{@last_id}").id
          end


        # the_class.find_in_batches(:conditions => [clause, clause_values]) do |batch_of_the_class|
          # batch_of_the_class.each do |item|
        the_class.find(:all, conditions: [clause, clause_values], limit: batch_size, order: 'id').each do |item|
            class_count_so_far += 1
            logger.info(item.id.to_s)

            if @skip_existing
              # test if it's in there first
              # set virtual attribute that is is need by zoom_id call
              if @public_zoom_db.has_zoom_record?(item.zoom_id, @public_zoom_connection) || (@skip_private == false && @private_zoom_db.has_zoom_record?(item.zoom_id, @private_zoom_connection))
                @skipped_record_count += 1
                @results[:records_skipped] = @skipped_record_count
                cache[:results] = @results
                logger.info('skipped')
                next
              end
            end

            unless @use_zebraidx
              item.prepare_and_save_to_zoom(public_existing_connectiond: @public_zoom_connection,
                                            private_existing_connectiond: @private_zoom_connection,
                                            import_private: false,
                                            skip_private: @skip_private,
                                            import_request: @import_request)

              if @public_zoom_db.has_zoom_record?(item.zoom_id, @public_zoom_connection) || (@skip_private == false && @private_zoom_db.has_zoom_record?(item.zoom_id, @private_zoom_connection))
                @record_count += 1
                @results[:records_processed] = @record_count
                cache[:results] = @results
                logger.info('added')
              else
                @failed_record_count += 1
                @results[:records_failed] = @failed_record_count
                cache[:results] = @results
                logger.info('failed: ' + item.inspect)
              end
            else
              item.prepare_and_save_to_zoom(write_files: true,
                                            import_private: false,
                                            skip_private: @skip_private,
                                            import_request: @import_request)
            end

            # do any work necessary by being at end of batch
            # note we repeat these steps after the_classes records
            # are done, to catch a batch less than batch_size
            if batch_count < batch_size
              # track count of where we are in the batch
              batch_count += 1
            elsif batch_count == batch_size
              if @use_zebraidx
                # trigger zebraidx and capture results for reporting
                zebraidx_message = Rake::Task['zebra:index'].execute(ENV)

                # rm data subdirectories now that we are done zebraidx batch processing
                FileUtils.rm_r("#{Rails.root}/zebradb/public/data/#{class_name.tableize}", force: true)
                FileUtils.rm_r("#{Rails.root}/zebradb/private/data/#{class_name.tableize}", force: true) unless @skip_private

                # TODO: more reporting on failed records?
                @record_count += batch_size
                @results[:records_processed] = @record_count
                cache[:results] = @results

                # TODO: skip the standard process startup lines, just grab errors
                logger.info("zebraidx at #{@record_count.to_s} says: #{zebraidx_message}")
              end
              # reset the next record to first in batch
              batch_count = 1
            end

            @last_id = item.id
            @results[:last_id] = @last_id
            cache[:results] = @results
          end
        end # end batch

        if batch_count < batch_size && batch_count != 1
          if @use_zebraidx
            # trigger zebraidx and capture results for reporting
            zebraidx_message = Rake::Task['zebra:index'].execute(ENV)

            # rm data subdirectories now that we are done zebraidx batch processing
            FileUtils.rm_r("#{Rails.root}/zebradb/public/data/#{class_name.tableize}", force: true)
            FileUtils.rm_r("#{Rails.root}/zebradb/private/data/#{class_name.tableize}", force: true) unless @skip_private

            # TODO: more reporting on failed records?
            @record_count += batch_count
            @results[:records_processed] = @record_count
            cache[:results] = @results

            # TODO: skip the standard process startup lines, just grab errors
            logger.info("zebraidx at #{@record_count.to_s} says: #{zebraidx_message}")
          end
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

  def stop_worker
    exit
  end

  private

  def use_rake_to_clear_zebra
    logger.info('in clear zebra')
    Rake::Task['zebra:init'].execute(ENV)
    # do the private zebra db, too if we should`rake zebra:init`
    unless @skip_private
      ENV['ZEBRA_DB'] = 'private'
      Rake::Task['zebra:init'].execute(ENV)
    end

    # we stop and start zebra so that any changes to configuration files
    # (maybe the case with upgrades)
    # are loaded
    Rake::Task['zebra:stop'].execute(ENV)
    Rake::Task['zebra:start'].execute(ENV)
  end
end
