require 'rexml/document'
require 'redcloth'
require 'importer'
# past perfect 4 xml output importer
# only handling photos for the moment
# needs accompanying archives.xml file
# to create topics to group photos by
# review http://development.kete.net.nz/kete/tickets/66 for details
# right now we create a topic for the collection (ACCESSNO from image)
# and add related images to it
# see OBJECTID goes to user_reference
class PastPerfect4ImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :past_perfect4_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  def create(args = nil)
    importer_simple_setup

    @last_related_topic = nil
    @last_related_topic_pp4_objectid = nil
  end

  def do_work(args = nil)
    logger.info('in worker')
    begin
      @zoom_class = args[:zoom_class]
      @import = Import.find(args[:import])
      @related_topic_type = @import.topic_type
      @import_type = @import.xml_type
      @import_dir_path = ::Import::IMPORTS_DIR + @import.directory
      @import_parent_dir_for_image_dirs = @import_dir_path + '/images'
      @contributing_user = @import.user
      @import_request = args[:import_request]
      @current_basket = @import.basket
      @description_end_templates['default'] = @import.default_description_end_template
      @record_interval = @import.interval_between_records

      logger.info('after description_end_template and var assigns')
      # legacy support for kete horowhenua
      if !@import_request[:host].scan('horowhenua').blank?
        @description_end_templates['default'] = 'Any use of this image must be accompanied by the credit "Horowhenua Historical Society Inc."'
        @description_end_templates[/^f\d/] = 'Any use of this image must be accompanied by the credit "Foxton Historical Society"'
        @description_end_templates["2000\.000\."] = 'Any use of this image must be accompanied by the credit "Horowhenua District Council"'

        @collections_to_skip << 'HHS Photograph Collection'
      end

      logger.info('after description_end_template reassign')

      @zoom_class_for_params = @zoom_class.tableize.singularize

      # this may not work because of scope
      params = args[:params]

      logger.info('params: ' + params.inspect)

      @import_photos_file_path = "#{@import_dir_path}/records.xml"

      # this sets the instance vars that tell us what xml element paths we are using
      # old style or new style
      determine_elements_used(@import_photos_file_path)

      # this gets rid of xml elements that have empty values
      @path_to_trimmed_photos = importer_trim_fat_from_xml_import_file(@import_photos_file_path, "#{RAILS_ROOT}/tmp/trimmed_photos_pp4.xml")
      @import_photos_xml = REXML::Document.new File.open(@path_to_trimmed_photos)

      logger.info('after first trim')

      # TODO: test what happens when there isn't an accessions.xml file
      @import_accessions_file_path = "#{@import_dir_path}/accessions.xml"
      @path_to_trimmed_accessions = importer_trim_fat_from_xml_import_file(@import_accessions_file_path, "#{RAILS_ROOT}/tmp/trimmed_accessions_pp4.xml", true)

      # open the accessions xml to search for a matching record later
      @import_accessions_xml = REXML::Document.new File.open(@path_to_trimmed_accessions)
      # this gets the first matching accession record
      logger.info('opened accession')

      @import_accessions_xml_root = @import_accessions_xml.root

      @import.update_attributes(status: 'in progress')

      # we work from the photos
      # and grab information from the accessions file
      # bases on ACCESSNO as a kind of forein key
      # as we need it
      @import_photos_xml.elements.each(@root_element_name + '/' + @record_element_path) do |record|
        # we override this locally for our customizations
        importer_process(record, params)
      end
      importer_update_processing_vars_at_end
    rescue
      importer_update_processing_vars_if_rescue
    end
  end

  def importer_process(record, params)
    current_record = @results[:records_processed] + 1
    logger.info("starting record #{current_record}")

    # clear this out so last related_topic
    # doesn't persist
    related_topic = nil
    related_topic_pp4_objectid = nil
    existing_item = nil
    image_file = nil
    image_objectid = nil
    objectid = nil

    record_hash = importer_xml_record_to_hash(record, true)

    # make sure there is a imagefile value
    # if not, log record to skipped photos file with reason skipped
    image_file = record_hash['IMAGEFILE']

    logger.info('what is image_file: ' + image_file)

    image_objectid = record_hash['OBJECTID']

    reason_skipped = nil

    path_to_file_to_grab = importer_prepare_path_to_image_file(image_file)

    logger.info("record #{current_record} : path_to_file_to_grab : " + path_to_file_to_grab)

    if image_file.blank? || !File.exist?(path_to_file_to_grab)
      # TODO: add check to see if image_file has a, b, c, versions associated with it
      # and add them is if they exist
      # change record imagefile accordingly for each and call importer_process on each
      reason_skipped = 'no image file specified or the image file isn\'t available'
      logger.info("record #{current_record} : reason skipped image")
    else
      logger.info("record #{current_record} : looking for topic")
      # grab the relate_to_topic_id
      # by getting the ACCESSNO field's value
      # see if there is a matching topic already
      # if not, create one from match in @import_accessions_xml
      # no match, log record to skipped photos file with reason skipped
      related_topic_pp4_objectid = record_hash['ACCESSNO']

      if related_topic_pp4_objectid.nil?
        # see if we can derive the accessno from the objectid
        # if we can't derive the accessno, just stick it in without
        # related topic
        objectid_parts = image_objectid.split('.')
        if objectid_parts.size > 2
          related_topic_pp4_objectid = objectid_parts[0] + '.' + objectid_parts[1]
        else
          related_topic_pp4_objectid = 0
          related_topic = 0
          # reason_skipped.add_text 'no ACCESSNO specified'
          # logger.info("record #{current_record} : reason skipped no ACCESSNO")
        end
      end

      if related_topic_pp4_objectid != 0
        # this item has the same related_topic as the last
        # don't bother looking it up again
        if !@last_related_topic_pp4_objectid.nil? && (related_topic_pp4_objectid == @last_related_topic_pp4_objectid)
          related_topic = @last_related_topic
        else
          related_topic = Topic.find(
            :first,
            conditions: "extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{related_topic_pp4_objectid}</user_reference>%\' AND topic_type_id = #{@related_topic_type.id}"
          )

        end

        related_accession_record = nil

        # no existing related topic
        # find the record in accessions
        # and create topic from it
        if related_topic.nil?
          logger.info("record #{current_record} : no kete topic found")

          logger.info('in creation of accession record')

          logger.info('accession we are looking for: ' + related_topic_pp4_objectid)

          if !@collections_to_skip.include?(record_hash['COLLECTION'])
            # file may time out
            related_accession_record = nil

            related_accession_record = @import_accessions_xml_root.elements["#{@record_element_path}[@ACCESSNO=\'#{related_topic_pp4_objectid}\']"]
            # we have some accesion record's that are mangled
            # by being three sections
            # rather than two
            # grab only the first two elements
            # and try again before giving up
            if related_accession_record.blank?
              cleaned_accessno_array = related_topic_pp4_objectid.split('.')
              cleaned_up_accessno = cleaned_accessno_array[0] + '.' + cleaned_accessno_array[1]

              logger.info('looking for cleaned up accession: ' + cleaned_up_accessno)

              if !@last_related_topic_pp4_objectid.nil? && (cleaned_up_accessno == @last_related_topic_pp4_objectid)
                logger.info('looking for cleaned up accession: last accessno match')
                related_topic = @last_related_topic
              else
                logger.info('looking for cleaned up accession: looking for existing topic')
                related_topic = Topic.find(
                  :first,
                  conditions: "extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{cleaned_up_accessno}</user_reference>%\' AND topic_type_id = #{@related_topic_type.id}"
                )

              end

              if related_topic.nil?
                related_accession_record = @import_accessions_xml_root.elements["#{@record_element_path}[@ACCESSNO=\'#{cleaned_up_accessno}\']"]
              end
              related_topic_pp4_objectid = cleaned_up_accessno
            end

            if !related_accession_record.blank? && related_topic.nil?
              accession_record_hash = importer_xml_record_to_hash(related_accession_record, true)

              # create a new topic from related_accession_record
              # prepare user_reference for extended_content
              accession_topic = { 'topic' => {
                topic_type_id: @related_topic_type.id,
                title: record_hash['COLLECTION']
              } }

              descrip = RedCloth.new accession_record_hash['DESCRIP']
              accession_topic['topic'][:description] = descrip.to_html
              accession_topic['topic'][:short_summary] = importer_prepare_short_summary(descrip)

              topic_params = importer_prepare_extended_field(value: related_topic_pp4_objectid, field: 'OBJECTID', zoom_class_for_params: 'topic', params: accession_topic)

              related_topic = importer_create_related_topic(topic_params)
              logger.info('after related topic creation')
            end
          end
        end
      end

      # TODO: if there is an object with a matching exactly user_reference,
      # and the modified date of the import record is later
      # do an update instead

      # base our check on OBJECTID
      objectid = record_hash['OBJECTID']

      logger.info('what is objectid: ' + objectid)

      # this relies on user_reference extended_field
      # being mapped to the particular kete content type (not content type in mime sense)
      # Walter McGinnis, 2008-10-10
      # User Reference may be used by multiple images (all under same parent record)
      # they will have different filenames, but same user reference...
      # so adding filename check as criteria
      existing_item = StillImage.find(
        :first, joins: 'join image_files on still_images.id = image_files.still_image_id',
                conditions: "filename = \'#{File.basename(path_to_file_to_grab)}\' and extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{objectid}</user_reference>%\'"
      )

      new_record = nil
      if existing_item.nil?
        # figure out the description_end_template based on the objectid
        description_end_template = @description_end_templates['default']
        @description_end_templates.each do |pattern, text|
          if pattern != 'default'
            description_end_template = text if !image_objectid.scan(pattern).blank?
          end
        end

        new_record = create_new_item_from_record(record, @zoom_class, params: params, record_hash: record_hash, description_end_template: description_end_template)
      else
        logger.info('what is existing item: ' + existing_item.id.to_s)
        # record exists in kete already
        reason_skipped = 'kete already has a copy of this record'
      end

      if !new_record.nil? && !new_record.id.nil?
        # we may not have a related topic, only add the relation if we do
        if !related_topic.nil? && (related_topic != 0)
          ContentItemRelation.new_relation_to_topic(related_topic.id, new_record)
          if @last_related_topic.nil? || (related_topic.id != @last_related_topic.id)
            # update the last topic, since we are done adding things to it for now
            related_topic.prepare_and_save_to_zoom
          end
        end

        new_record.prepare_and_save_to_zoom
        sleep(@record_interval) if @record_interval > 0

        # now that we know that we have a valid related_topic
        # update @last_related_topic and @last_related_topic_pp4_objectid
        @last_related_topic = related_topic
        @last_related_topic_pp4_objectid = related_topic_pp4_objectid

        importer_update_records_processed_vars
      end
    end
    # if this record was skipped, add to skipped_records
    if !reason_skipped.blank?
      importer_log_to_skipped_records(image_file, reason_skipped)
    end
    # will this help memory leaks
    record = nil
    # give zebra and our server a small break
    sleep(@record_interval) if @record_interval > 0
  end

  # customized in this worker to override importer module version
  # expects an xml element of our record
  def create_new_item_from_record(record, zoom_class, options = {})
    zoom_class_for_params = zoom_class.tableize.singularize

    params = options[:params]

    # initialize the subhash in params
    # clears it out if it does already
    params[zoom_class_for_params] = Hash.new

    params[zoom_class_for_params][:basket_id] = @current_basket.id

    # check extended_field.import_field_synonyms
    # for which extended field to map the import_field to
    # special cases for title, short_summary, and description
    record_hash = Hash.new
    if options[:record_hash].nil?
      record_hash = Hash.from_xml(record.to_s)

      # HACK to go down one more level
      record_hash.keys.each do |record_field|
        record_hash = record_hash[record_field]
      end
    else
      record_hash = options[:record_hash]
    end

    field_count = 1
    tag_list_array = Array.new
    # add support for all items during this import getting a set of tags
    # added to every item in addition to the specific ones for the item
    tag_list_array = @import.base_tags.split(',') if !@import.base_tags.blank?

    record_hash.keys.each do |record_field|
      value = record_hash[record_field]
      if !value.nil?
        value = value.strip
        # replace \r with \n
        value.tr("\r", "\n")
      end

      if !value.blank?

        case record_field
        when 'TITLE'
          params[zoom_class_for_params][:title] = value
        when 'ADMIN'
          if (zoom_class == 'Topic') || (zoom_class == 'Document')
            params[zoom_class_for_params][:short_summary] = value
          else
            if params[zoom_class_for_params][:description].nil?
              params[zoom_class_for_params][:description] = value
            else
              params[zoom_class_for_params][:description] += "\n" + value
            end
          end
        when 'IMAGEFILE'
          if zoom_class == 'StillImage'
            # we do a check earlier in the script for imagefile
            # so we should have something to work with here
            params[:image_file] = { uploaded_data: copy_and_load_to_temp_file(importer_prepare_path_to_image_file(value)) }
          end
        when 'OBJECTID'
          if zoom_class == 'Topic'
            value = record_hash['ACCESSNO']
          end
          params = importer_prepare_extended_field(value: value, field: record_field, zoom_class_for_params: zoom_class_for_params, params: params)
        when *SystemSetting.description_synonyms
          if params[zoom_class_for_params][:description].nil?
            params[zoom_class_for_params][:description] = value
          else
            params[zoom_class_for_params][:description] += "\n\n" + value
          end
        when *SystemSetting.tags_synonyms
          if record_field == 'PEOPLE'
            # each person is in the form: last name, first names
            # one name per line
            # it may have things in parentheses which we ignore
            people_in_lines = value.split("\n")
            people_in_lines.each do |person|
              names_array = person.split(',')
              first_names = String.new
              if !names_array[1].nil?
                first_names = names_array[1].split('(')[0].strip
              end
              last_names = names_array[0].strip
              name = first_names + ' ' + last_names
              tag_list_array << name.strip
            end
          else
            tag_list_array << value.tr("\n", ' ')
          end
        else
          params = importer_prepare_extended_field(value: value, field: record_field, zoom_class_for_params: zoom_class_for_params, params: params)
        end
      end
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

    logger.info('after description_end_template')

    description = String.new
    # used to give use better html output for descriptions
    if !params[zoom_class_for_params][:description].nil?
      description = RedCloth.new params[zoom_class_for_params][:description]
      params[zoom_class_for_params][:description] = description.to_html
    end

    logger.info('after redcloth')

    if (zoom_class == 'Topic') || zoom_class == 'Document' && params[zoom_class_for_params][:short_summary].nil?
      if !description.blank?
        params[zoom_class_for_params][:short_summary] = importer_prepare_short_summary(description)
      end
    end

    logger.info('after short summary')

    params[zoom_class_for_params][:tag_list] = tag_list_array.join(',')

    logger.info('after tag list')

    # add the uniform license chosen at import to this item
    params[zoom_class_for_params][:license_id] = @import.license.id if !@import.license.blank?

    logger.info('after license')

    # clear any lingering values for @fields
    # and instantiate it, in case we need it
    @fields = nil

    if zoom_class == 'Topic'
      params[zoom_class_for_params][:topic_type_id] = @related_topic_type.id

      @fields = @related_topic_type.topic_type_to_field_mappings

      ancestors = TopicType.find(@related_topic_type).ancestors

      if ancestors.size > 1
        ancestors.each do |ancestor|
          @fields = @fields + ancestor.topic_type_to_field_mappings
        end
      end
    else
      content_type = ContentType.find_by_class_name(zoom_class)
      @fields = content_type.content_type_to_field_mappings
    end

    if @fields.size > 0
      # we use our version of this method
      # that calls xml builder directly, rather than using partial template
      params[zoom_class_for_params.to_sym] = params[zoom_class_for_params]
      params = importer_extended_fields_update_hash_for_item(item_key: zoom_class_for_params, params: params)
    end

    logger.info('after field set up')

    # replace with something that isn't reliant on params
    replacement_zoom_item_hash = importer_extended_fields_replacement_params_hash(item_key: zoom_class_for_params, item_class: zoom_class, params: params)

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

      logger.info('new_record: ' + new_record.inspect)
      return new_record
    else
      # destroy images if the record wasn't added successfully
      new_image_file.destroy unless new_image_file.nil?

      logger.info('new_record not added - save failed:')
      logger.info('what are errors on save of new record: ' + new_record.errors.inspect)
      return nil
    end
  end

  # set up the correct xml paths to use
  # based on what is in the source file
  def determine_elements_used(in_file)
    # assume original style root element and paths
    @root_element_name = 'Root'
    @record_element_path = 'Information/Record'
    # this should tell us what we need to know by around the second line
    IO.foreach(in_file) do |line|
      # if exported directly from Past Perfect, should match this
      # empty means no match
      if line.include?('<VFPData>')
        @root_element_name = 'VFPData'
        @record_element_path = 'ppdata'
        return
      else
        # we have matched the previous style, return without resetting vars
        return if line.include?('<Record>')
      end
    end
  end
end
