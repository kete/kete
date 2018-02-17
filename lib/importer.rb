# -*- coding: utf-8 -*-
require 'tempfile'
require 'fileutils'
require 'mime/types'
require 'oai_dc_helpers'
require 'xml_helpers'
require 'zoom_helpers'
require 'zoom_controller_helpers'
require 'extended_content_helpers'
require 'kete_url_for'
# used by importer scripts  in lib/workers
module Importer
  unless included_modules.include? Importer
    def self.included(klass)
      klass.send :include, KeteUrlFor
      klass.send :include, OaiDcHelpers
      klass.send :include, ZoomHelpers
      klass.send :include, ZoomControllerHelpers
      klass.send :include, ExtendedContentHelpers
      klass.send :include, ActionController::UrlWriter
    end

    # nicked from attachment_fu and modified
    def copy_and_load_to_temp_file(file)
      # derive filename from file path passed in
      filename = File.basename(file)

      # derive content_type, too
      content_type = MIME::Types.type_for(filename).first.content_type

      returning Tempfile.new(filename) do |tmp|
        FileUtils.copy_file file, tmp.path
        (class << tmp; self; end;).class_eval do
          alias_method :local_path, :path
          define_method(:original_filename) { filename }
          define_method(:content_type) { content_type }
        end
      end
    end

    def importer_add_image(params, zoom_class)
      # add the image file and then close it
      if zoom_class == 'StillImage'
        logger.info('what is params[:image_file]: ' + params[:image_file].to_s)
        new_image_file = ImageFile.new(params[:image_file])
        new_image_file.save
        new_image_file
      end
    end

    def importer_add_still_image_to(new_image_file, new_record, zoom_class)
      # add the image file and then close it
      if zoom_class == 'StillImage'
        new_image_file.still_image_id = new_record.id
        new_image_file.save
        # attachment_fu doesn't insert our still_image_id into the thumbnails
        # automagically
        new_image_file.thumbnails.each do |thumb|
          thumb.still_image_id = new_record.id
          thumb.save!
        end
        logger.info('images done')
      end
    end

    def importer_simple_setup
      @successful = false
      @import_field_to_extended_field_map = {}
      @description_end_templates = {}
      @collections_to_skip = []
      @results = {
        do_work_time: Time.now.to_s,
        done_with_do_work: false,
        records_processed: 0
      }

      cache[:results] = @results
    end

    def importer_setup_initial_instance_vars(args)
      @zoom_class = args[:zoom_class]
      @import = Import.find(args[:import])
      @import_type = @import.xml_type
      @import_dir_path = ::Import::IMPORTS_DIR + @import.directory
      @contributing_user = @import.user
      @import_request = args[:import_request]
      @description_end_templates['default'] = @import.default_description_end_template
      @current_basket = @import.basket
      logger.info('what is current basket: ' + @current_basket.inspect)
      @import_topic_type = @import.topic_type
      @zoom_class_for_params = @zoom_class.tableize.singularize
      @xml_path_to_record ||= @import.xml_path_to_record.blank? ? 'records/record' : @import.xml_path_to_record
      @record_interval = @import.interval_between_records

      # These help prevent duplicate records
      # Use ||= so they are only assigned if the importer worker doesn't specify one already
      @record_identifier_xml_field ||= @import.record_identifier_xml_field
      @extended_field_that_contains_record_identifier ||= @import.extended_field_that_contains_record_identifier

      # Values for relating records.
      # Use ||= so they are only assigned if the importer worker doesn't specify one already
      @related_topics_reference_in_record_xml_field ||= @import.related_topics_reference_in_record_xml_field
      @related_topic_type ||= @import.related_topic_type
      @extended_field_that_contains_related_topics_reference ||= @import.extended_field_that_contains_related_topics_reference
    end

    # override this in your importer worker
    # if you need something more complex
    # this is what we call from the importers controller
    # for our particular importer worker
    # create method per importer worker
    # should do the setup specific to our type of importer
    # most importantly the @xml_path_to_record
    def do_work(args = nil)
      logger.info('in work')
      begin
        importer_setup_initial_instance_vars(args)

        params = args[:params]

        # some import types will take data in type specific format
        # and convert to standard records.xml that importer expects
        # this is done simply by defining a records_pre_processor method in worker class
        records_pre_processor if defined?(records_pre_processor)

        # work through records and add topics for each
        # if they don't already exist
        @results[:records_processed] = 0
        cache[:results] = @results

        # if there was an uploaded archive file (zip, tar, etc.)
        # process the extracted records
        # otherwise we expect a XML file describing the records
        if @import.import_archive_file.present? && params[:related_topic].present?

          @related_topic = Topic.find(params[:related_topic])

          # variables assigned, files good to go, we're started
          @import.update_attributes(status: I18n.t('importer_lib.do_work.in_progress'))

          importer_records_from_directory_at(@import_dir_path, params)

        else
          # trimming of file
          @path_to_trimmed_records = "#{@import_dir_path}/records_trimmed.xml"
          # @skip_trimming is set in records_pre_processor (or not if it is not run)
          # just use records.xml if we should skip trimming
          records_xml_path = "#{@import_dir_path}/records.xml"
          if @skip_trimming
            @path_to_trimmed_records = records_xml_path
          else
            @path_to_trimmed_records = importer_trim_fat_from_xml_import_file(records_xml_path, @path_to_trimmed_records)
          end

          @import_records_xml = Nokogiri::XML File.open(@path_to_trimmed_records)

          # variables assigned, files good to go, we're started
          @import.update_attributes(status: I18n.t('importer_lib.do_work.in_progress'))

          @import_records_xml.xpath(@xml_path_to_record).each do |record|
            importer_process(record, params) unless record.content.blank?
          end
        end

        importer_update_processing_vars_at_end
      rescue
        importer_update_processing_vars_if_rescue
      end
    end

    # recursively work through import directory
    # to find extracted files to be imported
    def importer_records_from_directory_at(path, params)
      # files or directories to ignore
      not_wanted_patterns = ['Thumbs.db', 'ehthumbs.db', '__MACOSX']
      Dir.foreach(path) do |record|
        full_path_to_record = path + '/' + record
        not_wanted = File.basename(full_path_to_record).first == '.' || not_wanted_patterns.include?(record)

        unless not_wanted
          # descend directories
          # else process files
          if File.directory?(full_path_to_record)
            importer_records_from_directory_at(full_path_to_record, params)
          else
            importer_process(full_path_to_record, params)
          end
        end
      end
    end

    def importer_fetch_related_topics(related_topic_identifier, params, options = {})
      related_topics = []

      related_topics += importer_locate_existing_items(options)

      if related_topics.blank? && !@record_identifier_xml_field.blank?
        # HACK, for horizons agency/series import, needs to be handled better
        return [] if @import_dir == 'series'
        matching_records = @import_records_xml.xpath("#{@xml_path_to_record}[#{@record_identifier_xml_field}='#{related_topic_identifier.strip}']")

        # if no matches, try downcase and upcase searches
        matching_records = @import_records_xml.xpath("#{@xml_path_to_record}[#{@record_identifier_xml_field}='#{related_topic_identifier.strip.downcase}']") unless matching_records.any?
        matching_records = @import_records_xml.xpath("#{@xml_path_to_record}[#{@record_identifier_xml_field}='#{related_topic_identifier.strip.upcase}']") unless matching_records.any?

        matching_records.each do |record|
          # HACK, for horizons agency/series import, needs to be handled better
          # remove agency.Successor and agency.Predecessor (causes infinite loop) for nodes for now
          record.search('//agency.Successor').each do |node|
            node.remove
          end
          record.search('//agency.Predecessor').each do |node|
            node.remove
          end

          related_topics << importer_process(record, params) unless record.blank? || record.content.blank?
        end
      end

      related_topics
    end

    def importer_prepare_extended_field(options = {})
      params = options[:params]
      field = options[:field]
      value = options[:value]
      zoom_class_for_params = options[:zoom_class_for_params]
      if !value.blank?
        # look up the synonym for the field
        # check if it's been mapped locally
        extended_field = ''
        if @import_field_to_extended_field_map[field].present?
          extended_field = @import_field_to_extended_field_map[field]
        else
          if @import_topic_type
            extended_fields = @import_topic_type.mapped_fields
          else
            extended_fields = ExtendedField.all(conditions: "import_synonyms like \'%#{field}%\'")
          end

          if extended_fields.present?
            extended_field = extended_fields.select { |ext_field| (ext_field.import_synonyms || '').split.include?(field) }.first
            @import_field_to_extended_field_map[field] = extended_field
          else
            logger.info('field in prepare: ' + field.inspect)
            @import_field_to_extended_field_map[field] = I18n.t('importer_lib.importer_prepare_extended_field.not_available')
          end
        end

        if extended_field.present? && (extended_field != I18n.t('importer_lib.importer_prepare_extended_field.not_available'))
          # add some smarts for handling fields that are multiple
          # assumes comma separated values

          params[zoom_class_for_params]['extended_content_values'] = {} if \
            params[zoom_class_for_params]['extended_content_values'].nil?

          if %w{choice autocomplete}.include?(extended_field.ftype)
            params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] ||= {}
            if extended_field.multiple
              value.split(',').each_with_index do |multiple_choice, multiple_index|
                params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params][(multiple_index + 1).to_s] ||= {}
                multiple_choice.strip.split('->').each_with_index do |choice, choice_index|
                  params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params][(multiple_index + 1).to_s][(choice_index + 1).to_s] = choice.strip
                end
              end
            else
              value.split('->').each_with_index do |choice, choice_index|
                params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params][(choice_index + 1).to_s] = choice.strip
              end
            end

          # Kieran Pilkington, 2009-10-28
          # The following code does not work yet
          # TODO: it looks like this still needs multiple support?
          elsif extended_field.ftype == 'topic_type' && @extended_field_that_contains_related_topics_reference.present?
            logger.info 'dealing with topic_type extended field'
            logger.info 'what is value? ' + value.inspect
            unless value =~ /http:\/\//
              logger.info 'value does not include http://'
              topic_type = TopicType.find_by_id(extended_field.topic_type)
              logger.info 'finding topic in topic type: ' + topic_type.inspect

              topics = importer_fetch_related_topics(
                value, params, {
                  item_type: 'topics',
                  topic_type: topic_type,
                  extended_field_data: {
                    label: @extended_field_that_contains_related_topics_reference.label_for_params,
                    value: value
                  }
                }
              )
              logger.info 'what is found topics? ' + topics.inspect
              return params if topics.blank?
              topic_url = url_for_dc_identifier(topics.first)
              value = { 'label' => value, 'value' => topic_url }
              logger.info 'what is resulting value? ' + value.inspect
            end
            params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] = value

          elsif extended_field.ftype == 'year'
            if extended_field.multiple
              multiple_values = value.split(',')
              m_field_count = 1
              params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] = {}
              multiple_values.each do |m_field_value|
                circa = m_field_value =~ /(circa|c.?\d+)/i # circa 2010, c 2010, c.2010
                m_field_value = (m_field_value =~ /(\d+)/ && $1) if circa
                params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params][m_field_count] = { value: m_field_value.to_s.strip, circa: (circa ? '1' : '0') }
                m_field_count += 1
              end
            else
              circa = value =~ /(circa|c.?\d+)/i # circa 2010, c 2010, c.2010
              value = (value =~ /(\d+)/ && $1) if circa
              params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] = { value: value.to_s.strip, circa: (circa ? '1' : '0') }
            end

          else
            if extended_field.multiple
              multiple_values = value.split(',')
              m_field_count = 1
              params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] = {}
              multiple_values.each do |m_field_value|
                params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params][m_field_count] = m_field_value.to_s.strip
                m_field_count += 1
              end
            else
              params[zoom_class_for_params]['extended_content_values'][extended_field.label_for_params] = value.to_s
            end
          end
        end
      end

      params
    end

    # populate extended_fields param with xml
    # based on params from the form
    def importer_extended_fields_update_hash_for_item(options = {})
      params = options[:params]
      item_key = options[:item_key].to_sym

      builder = Nokogiri::XML::Builder.new
      builder.root do |xml|
        @fields.each do |field_to_xml|
          field_name = field_to_xml.extended_field_label.downcase.tr(' ', '_')
          if field_to_xml.extended_field_multiple
            hash_of_values = params[item_key]['extended_content_values'][field_name] rescue nil
            if !hash_of_values.nil?
              xml.safe_send("#{field_name}_multiple") do
                hash_of_values.keys.each do |key|
                  xml.safe_send(key.to_s) do
                    logger.debug('inside hash: key: ' + key.to_s)
                    m_value = hash_of_values[key]
                    extended_content_field_xml_tag(
                      xml: xml,
                      field: field_name,
                      value: m_value,
                      xml_element_name: field_to_xml.extended_field_xml_element_name,
                      xsi_type: field_to_xml.extended_field_xsi_type,
                      extended_field: field_to_xml.extended_field
                    )
                  end
                end
              end
            end
          else
            value = (params[item_key]['extended_content_values'][field_name] || '') rescue ''
            extended_content_field_xml_tag(
              xml: xml,
              field: field_name,
              value: value,
              xml_element_name: field_to_xml.extended_field_xml_element_name,
              xsi_type: field_to_xml.extended_field_xsi_type,
              extended_field: field_to_xml.extended_field
            )
          end
        end
      end

      params[item_key][:extended_content] = builder.to_stripped_xml
      params
    end

    # strip out raw extended_fields and create a valid params hash for new/create/update
    def importer_extended_fields_replacement_params_hash(options = {})
      params = options[:params]
      item_key = options[:item_key].to_sym
      item_class = options[:item_class]

      extra_fields = options[:extra_fields] || []
      extra_fields << 'tag_list'
      extra_fields << 'uploaded_data'

      extra_fields << 'url'

      replacement_hash = {}

      params[item_key].keys.each do |field_key|
        # we only want real topic columns, not pseudo ones that are handled by extended_content xml
        if Module.class_eval(item_class).column_names.include?(field_key) || extra_fields.include?(field_key)
          replacement_hash = replacement_hash.merge(field_key => params[item_key][field_key])
        end
      end

      # imports aren't moderated, at least not for the time being
      replacement_hash[:do_not_moderate] = true

      replacement_hash
    end

    def importer_prepare_short_summary(source_string, length = 25, end_string = '')
      # length is how many words, rather than characters
      words = source_string.split
      words[0..(length - 1)].join(' ') + (words.length > length ? end_string : '')
    end

    def importer_prepare_path_to_image_file(image_file)
      image_path_array = image_file.split('\\')

      # prep alternative versions of the filename
      directories_up_to = @import_parent_dir_for_image_dirs + '/' + image_path_array[0] + '/'
      the_file_name = image_path_array[1]

      path_to_file_to_grab = directories_up_to + the_file_name

      # if we can't find the file, try downcasing or upcasing the extension
      # also try escaping any spaces

      if !File.exist?(path_to_file_to_grab)
        logger.debug('path_to_file_to_grab no match yet')

        # Try case insensitive check
        # this may not work on all systems, so falling back to only checking extensions after
        case_insensitive_matches = Dir.glob(path_to_file_to_grab, File::FNM_CASEFOLD)
        if case_insensitive_matches.any?
          path_to_file_to_grab = case_insensitive_matches.first
          logger.debug('path_to_file_to_grab is different by case: ' + path_to_file_to_grab)
        else

          file_name_array = the_file_name.scan(/(.+)(\.[^\d]+$)/)[0]
          file_name_no_extension = file_name_array[0]
          extension = file_name_array[1]

          downer = directories_up_to + file_name_no_extension + extension.downcase
          upper = directories_up_to + file_name_no_extension + extension.upcase

          if File.exist?(downer)
            path_to_file_to_grab = downer
            logger.debug('path_to_file_to_grab is downer: ' + path_to_file_to_grab)
          elsif File.exist?(upper)
            path_to_file_to_grab = upper
            logger.debug('path_to_file_to_grab is upper: ' + path_to_file_to_grab)
          end
        end
      end

      # make a copy of any files that have spaces in their name
      # a better formed name
      # to avoid problems later
      if !the_file_name.scan(' ').blank? && File.exist?(path_to_file_to_grab)
        the_new_file_name = the_file_name.tr(' ', "\.")
        new_file_path = directories_up_to + the_new_file_name

        if !File.exist?(new_file_path)
          FileUtils.copy_file path_to_file_to_grab, new_file_path
        end
        path_to_file_to_grab = new_file_path
      end

      path_to_file_to_grab
    end

    def importer_update_records_processed_vars
      @successful = true
      @results[:records_processed] += 1
      cache[:results] = @results
      @import.update_attributes(records_processed: @results[:records_processed])
    end

    def stop_worker
      exit
    end

    def importer_update_processing_vars_at_end
      if @successful
        @results[:notice] = I18n.t('importer_lib.importer_update_processing_vars_at_end.import_successful')
        @results[:done_with_do_work] = true
        @import.update_attributes(status: 'complete')
      else
        @results[:notice] = I18n.t('importer_lib.importer_update_processing_vars_at_end.import_failed')
        if !@results[:error].nil?
          logger.info("import error: #{@results[:error]}")
          @results[:notice] += @results[:error]
        end
        @results[:done_with_do_work] = true
        @import.update_attributes(status: I18n.t('importer_lib.importer_update_processing_vars_at_end.failed_status'))
      end
      cache[:results] = @results
      stop_worker
    end

    def importer_update_processing_vars_if_rescue
      @results[:error], @successful = $!.to_s, false
      @results[:done_with_do_work] = true
      cache[:results] = @results
      @import.update_attributes(status: I18n.t('importer_lib.importer_update_processing_vars_if_rescue.failed_status'))
      stop_worker
    end

    def importer_locate_existing_items(options = {})
      # not applicable to related_topic imports, at least for the moment
      return [] if @related_topic.present?

      options = {
        item_type: @zoom_class_for_params.pluralize,
        title: nil,
        topic_type: nil,
        extended_field_data: {},
        filename: nil
      }.merge(options)

      conditions = []
      params = {}

      if options[:title].present?
        conditions << '(LOWER(title) = :title)'
        params[:title] = options[:title].downcase
      end

      if options[:item_type] == 'topics' && options[:topic_type].present?
        conditions << '(topic_type_id = :topic_type_id)'
        params[:topic_type_id] = options[:topic_type].id
      end

      if options[:filename].present?
        # if zoom_class is StillImage
        # we need to do a join on ImageFile
        # to check filename
        filename_condition = 'LOWER(filename) = :filename'
        if options[:item_type] == 'still_images'
          image_file_conditions = "id IN (SELECT still_image_id FROM image_files WHERE #{filename_condition})"
        else
          conditions << "(#{filename_condition})"
        end
        params[:filename] = options[:filename].downcase
      end

      unless options[:extended_field_data].blank?
        regexp = ActiveRecord::Base.connection.adapter_name.downcase =~ /postgres/ ? '~*' : 'REGEXP'
        ext_field_label = options[:extended_field_data][:label]
        ext_field_value = options[:extended_field_data][:value]
        conditions << "(LOWER(extended_content) #{regexp} :ext_field_data)"
        params[:ext_field_data] = "<#{ext_field_label}[^>]*>#{ext_field_value}</#{ext_field_label}>".downcase
      end

      # Select all topics where the id is within a subselect of topic versions matching criteria
      # Adds a little complexity, but gets around privacy related import issues, as well as
      # no longer adds the topic if the first version was the same title but was later changed
      conditions = formulate_conditions(conditions.join(' AND '), options[:item_type].singularize)
      conditions = conditions + ' AND ' + image_file_conditions if options[:item_type] == 'still_images'
      conditions = [conditions, params] unless params.blank?
      logger.debug('what are conditions: ' + conditions.inspect)
      @current_basket.send(options[:item_type]).find(:all, conditions: conditions)
    end

    def formulate_conditions(conditions, item_type)
      "id IN (SELECT #{item_type}_id FROM #{item_type}_versions WHERE #{conditions})"
    end

    # override in your importer worker to customize
    # takes an xml element
    def importer_process(record, params)
      current_record = @results[:records_processed] + 1
      logger.info("starting record #{current_record}")

      record_hash = {}
      # if a file is passed in, we assume embedded metadata
      # (or filename and form settings)
      # will be what we derive our hash values from
      # otherwise, we expect xml to derive hash values from
      if File.exist?(record)
        record_hash['placeholder_title'] = File.basename(record, File.extname(record)).tr('_', ' ')
        record_hash['path_to_file'] = record
      else
        record_hash = importer_xml_record_to_hash(record)
      end

      reason_skipped = nil

      logger.info("record #{current_record} : looking for topic")

      # will only work with topics
      # we need a title attribute
      # if this is well set up there should only be one matching record_hash key
      # that is a title synonym, we go with last match just in case
      title = nil
      record_hash.keys.each do |field_name|
        title = record_hash[field_name].strip if field_name.casecmp('title').zero? || (SystemSetting.SystemSetting.title_synonyms && SystemSetting.SystemSetting.title_synonyms.include?(field_name))
      end

      logger.info('after record field_name loop')

      # In some cases, records may share the same name, but have a different code
      # In order to accomodate for that, we check both title, extended field data
      # and topic type if available
      # Otherwise, do a very basic check againts items with the same title and topic type
      options = {
        title: title,
        topic_type: @import_topic_type
      }

      if record_hash[@record_identifier_xml_field].present? && @extended_field_that_contains_record_identifier.present?
        options[:extended_field_data] = {
          label: @extended_field_that_contains_record_identifier.label_for_params,
          value: record_hash[@record_identifier_xml_field]
        }
      end

      # attachable classes may have an upload file specified in file xml element
      # if file exists, we know we are uploading files for an attachable class
      if record_hash['path_to_file'].present? &&
         File.exist?(record_hash['path_to_file'])
        logger.info('setting filename check')
        options[:filename] = File.basename(record_hash['path_to_file'])
      end
      logger.info('after path_to_file present')

      existing_item = importer_locate_existing_items(options).first

      new_record = nil
      if existing_item.blank?
        description_end_template = @description_end_templates['default']
        new_record = create_new_item_from_record(record, @zoom_class, { params: params, record_hash: record_hash, description_end_template: description_end_template })
      else
        logger.info('what is existing item: ' + existing_item.id.to_s)
        # record exists in kete already
        reason_skipped = I18n.t('importer_lib.importer_process.already_have_record')
      end

      if !new_record.nil? && !new_record.id.nil?
        logger.info('new record succeeded for insert')
        new_record.prepare_and_save_to_zoom
        importer_update_records_processed_vars
      end

      # if this record was skipped, add to skipped_records
      if !reason_skipped.blank?
        importer_log_to_skipped_records(title, reason_skipped)
      end
      # will this help memory leaks
      record = nil
      # give zebra and our server a small break
      sleep(@record_interval) if @record_interval > 0

      existing_item || new_record
    end

    # XPATH was proving too unreliable
    # switching to pulling record to a hash
    # and grabbing the specific fields
    # we need to check
    def importer_xml_record_to_hash(record, upcase = false)
      record_hash = Hash.from_xml(record.to_s)

      # HACK to go down one more level
      record_hash.keys.each do |record_field|
        record_hash = record_hash[record_field]
      end

      # move all hash keys to upcase
      # we use this to smooth some legacy code in past perfect import
      if upcase
        new_record_hash = {}
        record_hash.each do |key, value|
          key = key.upcase if key.is_a?(String)
          new_record_hash[key] = value
        end
        record_hash = new_record_hash
      end

      logger.info('record_hash inspect: ' + record_hash.inspect)
      record_hash
    end

    # copied and modified from http://www.broobles.com/eml2mbox/eml2mboxscript.html (GPL 2 or later)
    def remove_non_unix_new_lines(line)
      line = line[0..-3] + line[-1..-1] if line[-2] == 0xD
      line = line[0..-2] if line[-1] == 0xA
      # add a unix newline if not already there
      line = line + "\n" unless line.include?("\n")
    end

    # override in your importer worker to customize
    # takes a potentially huge xml file and strips out all the empty fields
    # so it much more manageable
    # output is to a tmp file
    # has commented out code for replacing macronized vowels
    # uncomment if you need them
    def importer_trim_fat_from_xml_import_file(path_to_original_file, path_to_output, accession = nil)
      fat_free_file = File.new(path_to_output, 'w+')

      fatty_re = Regexp.new("\/\>.*")

      accessno_re = Regexp.new(/ACCESSNO>(.*)</i)

      IO.foreach(path_to_original_file) do |line|
        line = remove_non_unix_new_lines(line)
        # HACK to seriously trim down accession records
        # and make them in a form we can search easily
        # only add non-fat to our fat_free_file
        #  && !line.blank?
        # keeping new lines only lines for redcloth formatting
        if !line.match(fatty_re)
          if accession.nil?
            # replace double dotted version of maori vowels
            # with macrons
            # replacements = { 'ä' => 'ā',
            #               'ë' => 'ē',
            #               'ï' => 'ī',
            #               'ö' => 'ō',
            #               'ü' => 'ū' }

            #             replacements.each do |old_style_vowel, macronized|
            #               line = line.gsub(old_style_vowel, macronized).gsub(old_style_vowel.upcase, macronized.upcase)
            #             end
            fat_free_file << line
          else
            # we only keep accessno and descrip
            # and their containing elements
            # but we change accessno to an attribute of record
            # rather than an element
            # this relies on the accessno line coming before the descrip line
            # it tosses the original <Record> or <export> line, so that it can be replaced
            # putting in both styles of records
            if line.include?('<ACCESSNO') || line.include?('<accessno') ||
               line.include?('<DESCRIP') || line.include?('<descrip') ||
               line.include?("<\/DESCRIP") || line.include?("<\/descrip") ||
               line.include?("<\/Record") || line.include?("<\/export") ||
               line.include?('<Information') || line.include?("<\/Information") ||
               line.include?('<Root') || line.include?('<VFPData') ||
               line.include?("<\/Root") || line.include?("<\/VFPData")

              # we expect accessno to be on one line, this will break if not
              if line.include?('<accessno') || line.include?('<ACCESSNO')
                accessno_match_result = line.match(accessno_re)
                accessno = !accessno_match_result.nil? && !accessno_match_result[1].nil? ? accessno_match_result[1] : nil

                new_start_record_line = '<'
                # if accessno is empty, we just open the export or Record so we have valid xml
                # otherwise set as appropriate to the source xml file's format
                if !@root_element_name.nil? && @root_element_name == 'Root'
                  new_start_record_line += 'Record'
                else
                  new_start_record_line += 'export'
                end

                unless accessno.blank?
                  new_start_record_line += " ACCESSNO=\'#{accessno}\'"
                end

                fat_free_file << new_start_record_line + ">\n"
              else
                fat_free_file << line
              end
            end
          end
        end
      end

      # add a blank line a the end
      fat_free_file << ''
      fat_free_file.close

      path_to_output
    end

    def assign_value_to_appropriate_fields(record_field, record_value, params, zoom_class)
      return if SystemSetting.import_fields_to_ignore.include?(record_field)
      logger.debug('record_field ' + record_field.inspect)

      zoom_class_for_params = zoom_class.tableize.singularize

      record_value = record_value.strip.tr("\r", "\n") if record_value.present?

      if record_value.present?
        # if it's mapped to an extended field, params are updated
        params = importer_prepare_extended_field(
          value: record_value,
          field: record_field,
          zoom_class_for_params: zoom_class_for_params,
          params: params
        )

        # the field may also be mapped to non-extended fields
        # such as tags, description, title
        # the value maybe used multiple times, so case isn't appropriate
        if record_field.casecmp('TITLE').zero? || (!SystemSetting.title_synonyms.blank? && SystemSetting.title_synonyms.include?(record_field))
          params[zoom_class_for_params][:title] = record_value
        end

        if !SystemSetting.description_synonyms.blank? && SystemSetting.description_synonyms.include?(record_field)
          if params[zoom_class_for_params][:description].nil?
            params[zoom_class_for_params][:description] = record_value
          else
            params[zoom_class_for_params][:description] += "\n\n" + record_value
          end
        end

        if !SystemSetting.short_summary_synonyms.blank? && SystemSetting.short_summary_synonyms.include?(record_field)
          if params[zoom_class_for_params][:short_summary].nil?
            params[zoom_class_for_params][:short_summary] = record_value
          else
            params[zoom_class_for_params][:short_summary] += "\n\n" + record_value
          end
        end

        if !SystemSetting.tags_synonyms.blank? && SystemSetting.tags_synonyms.include?(record_field)
          @tag_list_array += record_value.split(',').collect { |tag| tag.strip }
        end

        if zoom_class == 'WebLink' && record_field.casecmp('URL').zero?
          params[zoom_class_for_params][:url] = record_value
        end

        # path_to_file is special case, we know we have an associated file that goes in uploaded_data
        if record_field == 'path_to_file'
          logger.debug('in path_to_file')
          if ::Import::VALID_ARCHIVE_CLASSES.include?(zoom_class) && File.exist?(record_value)
            # we do a check earlier in the script for imagefile
            # so we should have something to work with here
            upload_hash = { uploaded_data: copy_and_load_to_temp_file(record_value) }
            if zoom_class == 'StillImage'
              logger.debug('in image')
              params[:image_file] = upload_hash
            else
              logger.debug('in not image')
              params[zoom_class_for_params] = params[zoom_class_for_params].merge(upload_hash)
            end
          end
        end
      end

      params
    end

    # override in your importer worker to customize
    # expects an xml element of our record or a file with a simple record_hash
    # TODO: add support for zoom_classes that may have attachments
    # steal from past perfect importer
    # record_hash has to have file key
    def create_new_item_from_record(record, zoom_class, options = {})
      zoom_class_for_params = zoom_class.tableize.singularize

      params = options[:params]

      # initialize the subhash in params
      # clears it out if it does already
      params[zoom_class_for_params] = {}

      if options[:basket_id].nil?
        params[zoom_class_for_params][:basket_id] = @current_basket.id
      else
        params[zoom_class_for_params][:basket_id] = options[:basket_id]
      end

      # check extended_field.import_field_synonyms
      # for which extended field to map the import_field to
      # special cases for title, short_summary, and description
      record_hash = {}
      if options[:record_hash].nil?
        record_hash = importer_xml_record_to_hash(record)
      else
        record_hash = options[:record_hash]
      end

      field_count = 1
      @tag_list_array = []
      # add support for all items during this import getting a set of tags
      # added to every item in addition to the specific ones for the item
      @tag_list_array = @import.base_tags.split(',').collect { |tag| tag.strip } if !@import.base_tags.blank?

      # Run each value through any importer field methods that exist
      # and get back the value plus any other fields needing setting
      import_field_methods_file = Rails.root.join('config/importers.yml').to_s
      if File.exist?(import_field_methods_file)
        importer_field_methods = (YAML.load(File.read(import_field_methods_file)) || {})[@import_type.to_s]

        if importer_field_methods.is_a?(Hash)
          additional_fields_derived_from_processing_values = {}
          record_hash.each do |record_field, record_value|
            if record_value.present? && importer_field_methods[record_field.downcase]
              field_modifier = eval(importer_field_methods[record_field.downcase])
              args = field_modifier.arity == 2 ? [record_value, record_hash] : [record_value]
              parsed_value = Array(field_modifier.call(*args))
              additional_fields_derived_from_processing_values.merge!(parsed_value.last) if parsed_value.last.is_a?(Hash)
              record_hash[record_field] = parsed_value.first
            end
          end

          # Loop over each result, add to record_hash if it doesn't exist yet,
          # or append the value to what already exists in record_hash
          additional_fields_derived_from_processing_values.each do |record_field, record_value|
            if record_hash[record_field].present?
              record_hash[record_field] += "\n\n" + record_value
            else
              record_hash[record_field] = record_value
            end
          end
        end
      end

      # Loops over each record value and assign the value to the appropriate fields
      record_hash.each do |record_field, record_value|
        params = assign_value_to_appropriate_fields(record_field, record_value, params, zoom_class)
        field_count += 1
      end

      logger.info('after fields')

      if !@import.description_beginning_template.blank?
        # append the citation to the description field
        if !params[zoom_class_for_params][:description].nil?
          params[zoom_class_for_params][:description] = @import.description_beginning_template + "\n\n" + params[zoom_class_for_params][:description]
        else
          params[zoom_class_for_params][:description] = @import.description_beginning_template
        end
      elsif !SystemSetting.description_template.blank?
        if !params[zoom_class_for_params][:description].nil?
          params[zoom_class_for_params][:description] = SystemSetting.description_template + "\n\n" + params[zoom_class_for_params][:description]
        else
          params[zoom_class_for_params][:description] = SystemSetting.description_template
        end
      end

      if !options[:description_end_template].nil?
        # append the description_end_template to the description field
        if !params[zoom_class_for_params][:description].nil?
          params[zoom_class_for_params][:description] += "\n\n" + options[:description_end_template]
        else
          params[zoom_class_for_params][:description] = options[:description_end_template]
        end
      end

      description = ''
      # used to give use better html output for descriptions
      if !params[zoom_class_for_params][:description].nil?
        description = RedCloth.new params[zoom_class_for_params][:description]
        params[zoom_class_for_params][:description] = description.to_html
      end

      params[zoom_class_for_params][:tag_list] = @tag_list_array.join(',')
      params[zoom_class_for_params][:raw_tag_list] = params[zoom_class_for_params][:tag_list]

      # set the chosen privacy
      private_setting = @import.private
      logger.debug('private = ' + private_setting.to_s)
      params[zoom_class_for_params][:private] = private_setting

      # set the chosen file privacy
      file_private_setting = @import.file_private
      params[zoom_class_for_params][:file_private] = file_private_setting

      # add the uniform license chosen at import to this item
      params[zoom_class_for_params][:license_id] = @import.license.id if !@import.license.blank?

      # clear any lingering values for @fields
      # and instantiate it, in case we need it
      @fields = nil

      if zoom_class == 'Topic'
        params[zoom_class_for_params][:topic_type_id] = @import_topic_type.id

        @fields = @import_topic_type.topic_type_to_field_mappings

        ancestors = TopicType.find(@import_topic_type).ancestors

        if ancestors.size > 0
          ancestors.each do |ancestor|
            @fields = @fields + ancestor.topic_type_to_field_mappings
          end
        end
      else
        content_type = ContentType.find_by_class_name(zoom_class)
        @fields = content_type.content_type_to_field_mappings
      end

      if @fields.size > 0
        logger.info('fields larger than 0')

        # we use our version of this method
        # that calls xml builder directly, rather than using partial template
        params[zoom_class_for_params.to_sym] = params[zoom_class_for_params]
        params = importer_extended_fields_update_hash_for_item(item_key: zoom_class_for_params, params: params)
      end

      logger.info('after field set up')

      # replace with something that isn't reliant on params
      replacement_zoom_item_hash = importer_extended_fields_replacement_params_hash(item_key: zoom_class_for_params, item_class: zoom_class, params: params)

      logger.info 'what is replacement_zoom_item_hash? ' + replacement_zoom_item_hash.inspect

      new_record = Module.class_eval(zoom_class).new(replacement_zoom_item_hash)

      # we need new_image_file's file, for our embedded metadata (if enabled)
      # thus we have to create it before the still image
      new_image_file = nil
      new_image_file = importer_add_image(params, zoom_class) unless params[:image_file].blank?

      # only necessary for still images, because attachment is in a child model
      # if we are allowing harvesting of embedded metadata from the image_file
      # we need to grab it from the image_file's file path
      if SystemSetting.enable_embedded_support && !new_image_file.nil? && zoom_class == 'StillImage'
        new_record.populate_attributes_from_embedded_in(new_image_file.full_filename)
      end

      # handle special case where title is derived from filename
      if new_record.title.blank?
        if SystemSetting.enable_embedded_support && zoom_class != 'StillImage' && ATTACHABLE_CLASSES.include?(zoom_class)
          new_record.title = '-replace-' + record_hash['placeholder_title']
        else
          new_record.title = record_hash['placeholder_title']
        end
      end

      # respect the Related Items Inset configurations
      if new_record.respond_to?(:related_items_position)
        new_record.related_items_position = (SystemSetting.related_items_position_default ? SystemSetting.related_items_position_default : 'inset')
      end

      # if still image and new_image failed, fail
      new_record_added = false
      unless zoom_class == 'StillImage'
        new_record_added = new_record.save
      else
        new_record_added = new_record.save unless new_image_file.nil?
      end

      if new_record_added
        importer_add_still_image_to(new_image_file, new_record, zoom_class) unless new_image_file.nil?

        new_record.creator = @contributing_user

        importer_build_relations_to(new_record, record_hash, options[:params])

        logger.info('in topic creation made it past creator')
      else
        # destroy images if the record wasn't added successfully
        new_image_file.destroy unless new_image_file.nil?

        logger.info('what are errors on save of new record: ' + new_record.errors.inspect)
      end

      new_record
    end

    def importer_build_relations_to(new_record, record_hash, params)
      logger.info('building relations for new record')

      if @related_topics_reference_in_record_xml_field.blank? && @related_topic.blank?
        logger.info('no relations to be made for new record')
        return
      end

      # two options to build relations
      # single @related_topic exists
      # or more complex mapping in the data to topic to relate to
      if @related_topic.present?
        # add relation to related_topic
        ContentItemRelation.new_relation_to_topic(@related_topic.id, new_record)

        # it would be faster to do this just once afte all new records
        # were related
        # but doing this for each new record
        # means that if import fails
        # each related record up to the failure is has relationship
        # reflected in related topic
        @related_topic.prepare_and_save_to_zoom
      else

        # We need an array to loop over, but we also allow single values as strings, so convert as needed
        # Split by commas incase mutliple ones are provided, and strip whitespace
        if @related_topics_reference_in_record_xml_field.is_a?(String)
          @related_topics_reference_in_record_xml_field = @related_topics_reference_in_record_xml_field.split(',').collect { |r| r.strip }
        end

        @related_topics_reference_in_record_xml_field.each do |related_topics_reference_in_record_xml_field|
          next if related_topics_reference_in_record_xml_field.blank?
          if record_hash[related_topics_reference_in_record_xml_field].blank?
            logger.info("no relational field found with name of #{related_topics_reference_in_record_xml_field}")
            next
          end

          record_hash[related_topics_reference_in_record_xml_field].split(',').each do |related_topic_identifier|
            related_topic_identifier = related_topic_identifier.strip

            if @last_related_topic_identifier.blank? || @last_related_topic_identifier != related_topic_identifier
              related_topics = importer_fetch_related_topics(
                related_topic_identifier, params, {
                  item_type: 'topics',
                  topic_type: @related_topic_type,
                  extended_field_data: {
                    label: @extended_field_that_contains_related_topics_reference.label_for_params,
                    value: related_topic_identifier
                  }
                }
              ) if @extended_field_that_contains_related_topics_reference.present?
            else
              related_topics = @last_related_topics
            end

            next if related_topics.blank?

            related_topics.uniq.flatten.compact.each do |related_topic|
              next if related_topic == new_record
              ContentItemRelation.new_relation_to_topic(related_topic, new_record)
            end

            @last_related_topic_identifier = related_topic_identifier
            @last_related_topics = related_topics
          end
        end
      end
      logger.info('finished building relations for new record')
    end

    # override in your importer worker to customize
    def importer_log_to_skipped_records(identifier, reason_skipped)
      logger.info("#{identifier}: #{reason_skipped}")
    end

    def importer_create_related_topic(topic_params)
      # clear any lingering values for @fields
      # and instantiate it, in case we need it
      @fields = nil

      @fields = @related_topic_type.topic_type_to_field_mappings

      ancestors = @related_topic_type.ancestors

      if ancestors.size > 1
        ancestors.each do |ancestor|
          @fields = @fields + ancestor.topic_type_to_field_mappings
        end
      end

      # we use our version of this method
      # that calls xml builder directly, rather than using partial template
      # HACK, conflict with symbol vs string for hash key
      # duplicate
      temp_params = {}
      temp_params[:topic] = topic_params['topic']
      topic_params = importer_extended_fields_update_hash_for_item(item_key: 'topic', params: temp_params)

      topic_params[:topic][:basket_id] = @current_basket.id

      # add the uniform license chosen at import to this item
      if !@import.license.blank?
        topic_params[:topic][:license_id] = @import.license.id
      else
        topic_params[:topic][:license_id] = nil
      end

      # replace with something that isn't reliant on params
      # replacement_topic_hash = pp4_importer_extended_fields_replacement_params_hash(:item_key => "topic", :item_class => 'Topic', :params => topic_params)

      # we set the virtual attribute, do_not_moderate to true
      # so that our imported topics go live right away
      # and thus can be found (since then they won't have blank attributes)
      related_topic = Topic.create!(
        title: topic_params[:topic][:title],
        description: topic_params[:topic][:description],
        short_summary: topic_params[:topic][:short_summary],
        extended_content: topic_params[:topic][:extended_content],
        basket_id: topic_params[:topic][:basket_id],
        license_id: topic_params[:topic][:license_id],
        topic_type_id: topic_params[:topic][:topic_type_id],
        do_not_moderate: true,
        related_items_position: (SystemSetting.related_items_position_default ? SystemSetting.related_items_position_default : 'inset')
      )

      related_topic.creator = @contributing_user
      related_topic
    end
  end
end
