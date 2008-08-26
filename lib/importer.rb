require 'rexml/document'
require 'tempfile'
require 'fileutils'
require 'mime/types'
require 'builder'
require "oai_dc_helpers"
require "xml_helpers"
require "importer_zoom"
require "zoom_helpers"
require "zoom_controller_helpers"
require "extended_content_helpers"
# used by importer scripts  in lib/workers
module Importer
  unless included_modules.include? Importer
    def self.included(klass)
      klass.send :include, OaiDcHelpers
      klass.send :include, ZoomHelpers
      klass.send :include, ZoomControllerHelpers
      klass.send :include, ImporterZoom
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
          alias local_path path
          define_method(:original_filename) {  filename }
          define_method(:content_type) {  content_type }
        end
      end
    end

    def importer_add_image_to(new_record, params, zoom_class)
      # add the image file and then close it
      if zoom_class == 'StillImage'
        logger.info("what is params[:image_file]: " + params[:image_file].to_s)
        new_image_file = ImageFile.new(params[:image_file])
        new_image_file.still_image_id = new_record.id
        new_image_file.save
        # attachment_fu doesn't insert our still_image_id into the thumbnails
        # automagically
        new_image_file.thumbnails.each do |thumb|
          thumb.still_image_id = new_record.id
          thumb.save!
        end
        logger.info("images done")
      end
    end

    def importer_simple_setup
      @successful = false
      @import_field_to_extended_field_map = Hash.new
      @description_end_templates = Hash.new
      @collections_to_skip = Array.new
      @results = { :do_work_time => Time.now.to_s,
        :done_with_do_work => false,
        :records_processed => 0 }

      cache[:results] = @results
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
        @zoom_class = args[:zoom_class]
        @import = Import.find(args[:import])
        @import_type = @import.xml_type
        @import_dir_path = ::Import::IMPORTS_DIR + @import.directory
        @contributing_user = @import.user
        @import_request = args[:import_request]
        @description_end_templates['default'] = @import.default_description_end_template
        @current_basket = @import.basket
        logger.info("what is current basket: " + @current_basket.inspect)
        @import_topic_type = @import.topic_type
        @zoom_class_for_params = @zoom_class.tableize.singularize
        @xml_path_to_record ||= @import.xml_path_to_record
        @record_interval = @import.interval_between_records

        params = args[:params]

        # trimming of file
        @path_to_trimmed_records = "#{@import_dir_path}/records_trimmed.xml"
        @path_to_trimmed_records = importer_trim_fat_from_xml_import_file("#{@import_dir_path}/records.xml",@path_to_trimmed_records)
        @import_records_xml = REXML::Document.new File.open(@path_to_trimmed_records)

        # variables assigned, files good to go, we're started
        @import.update_attributes(:status => 'in progress')

        # work through records and add topics for each
        # if they don't already exist
        @results[:records_processed] = 0
        cache[:results] = @results
        @import_records_xml.elements.each(@xml_path_to_record) do |record|
          importer_process(record, params)
        end
        importer_update_processing_vars_at_end
      rescue
        importer_update_processing_vars_if_rescue
      end
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
        if !@import_field_to_extended_field_map[field].nil?
          extended_field = @import_field_to_extended_field_map[field]
        else
          extended_field = ExtendedField.find(:first,
                                              :conditions => "import_synonyms like \'%#{field}%\'")
          if !extended_field.nil?
            @import_field_to_extended_field_map[field] = extended_field
          else
            @import_field_to_extended_field_map[field] = 'not available'
          end
        end

        if !extended_field.nil? and extended_field != 'not available'
          # add some smarts for handling fields that are multiple
          # assumes comma separated values
          if extended_field.multiple
            multiple_values = value.split(",")
            m_field_count = 1
            params[zoom_class_for_params][extended_field.label_for_params] = Hash.new
            multiple_values.each do |m_field_value|
              params[zoom_class_for_params][extended_field.label_for_params][m_field_count] = m_field_value.strip
              m_field_count += 1
            end
          else
            params[zoom_class_for_params][extended_field.label_for_params] = value
          end
        end
      end
      return params
    end

    # populate extended_fields param with xml
    # based on params from the form
    def importer_extended_fields_update_hash_for_item(options = {})
      params = options[:params]
      item_key = options[:item_key].to_sym

      xml = Builder::XmlMarkup.new

      @fields.each do |field_to_xml|
        field_name = field_to_xml.extended_field_label.downcase.gsub(/ /, '_')
        if field_to_xml.extended_field_multiple
          hash_of_values = params[item_key][field_name]
          if !hash_of_values.nil?
            xml.tag!("#{field_name}_multiple") do
              hash_of_values.keys.each do |key|
                xml.tag!(key.to_s) do
                  logger.debug("inside hash: key: " + key.to_s)
                  m_value = hash_of_values[key].to_s
                  extended_content_field_xml_tag(:xml => xml,
                                                 :field => field_name,
                                                 :value => m_value,
                                                 :xml_element_name => field_to_xml.extended_field_xml_element_name,
                                                 :xsi_type => field_to_xml.extended_field_xsi_type)
                end
              end
            end
          end
        else
          extended_content_field_xml_tag(:xml => xml,
                                         :field => field_name,
                                         :value => params[item_key][field_name],
                                         :xml_element_name => field_to_xml.extended_field_xml_element_name,
                                         :xsi_type => field_to_xml.extended_field_xsi_type)
        end
      end

      extended_content = xml.to_s
      params[item_key][:extended_content] = extended_content.gsub("<to_s\/>","")
      return params
    end

    # strip out raw extended_fields and create a valid params hash for new/create/update
    def importer_extended_fields_replacement_params_hash(options = {})
      params = options[:params]
      item_key = options[:item_key].to_sym
      item_class = options[:item_class]

      extra_fields = options[:extra_fields] || Array.new
      extra_fields << 'tag_list'
      extra_fields << 'uploaded_data'

      replacement_hash = Hash.new

      params[item_key].keys.each do |field_key|
        # we only want real topic columns, not pseudo ones that are handled by extended_content xml
        if Module.class_eval(item_class).column_names.include?(field_key) || extra_fields.include?(field_key)
          replacement_hash = replacement_hash.merge(field_key => params[item_key][field_key])
        end
      end

      # imports aren't moderated, at least not for the time being
      replacement_hash[:do_not_moderate] = true

      return replacement_hash
    end

    def importer_prepare_short_summary(source_string, length = 25, end_string = '')
      # length is how many words, rather than characters
      words = source_string.split()
      words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    end

    def importer_prepare_path_to_image_file(image_file)
      image_path_array = image_file.split("\\")

      # prep alternative versions of the filename
      directories_up_to = @import_parent_dir_for_image_dirs + "/" + image_path_array[0] + "/"
      the_file_name = image_path_array[1]

      path_to_file_to_grab = directories_up_to + the_file_name

      # if we can't find the file, try downcasing or upcasing the extension
      # also try escaping any spaces

      if !File.exists?(path_to_file_to_grab)
        logger.debug("path_to_file_to_grab no match yet")

        file_name_array = the_file_name.scan(/(.+)(\.[^\d]+$)/)[0]
        file_name_no_extension = file_name_array[0]
        extension = file_name_array[1]

        downer = directories_up_to + file_name_no_extension + extension.downcase
        upper = directories_up_to + file_name_no_extension + extension.upcase

        if File.exists?(downer)
          path_to_file_to_grab = downer
          logger.debug("path_to_file_to_grab is downer: " + path_to_file_to_grab)
        elsif File.exists?(upper)
          path_to_file_to_grab = upper
          logger.debug("path_to_file_to_grab is upper: " + path_to_file_to_grab)
        end
      end

      # make a copy of any files that have spaces in their name
      # a better formed name
      # to avoid problems later
      if !the_file_name.scan(" ").blank? and  File.exists?(path_to_file_to_grab)
        the_new_file_name = the_file_name.gsub(" ", "\.")
        new_file_path = directories_up_to + the_new_file_name

        if !File.exists?(new_file_path)
          FileUtils.copy_file path_to_file_to_grab, new_file_path
        end
        path_to_file_to_grab = new_file_path
      end

      return path_to_file_to_grab
    end

    def importer_update_records_processed_vars
      @successful = true
      @results[:records_processed] += 1
      cache[:results] = @results
      @import.update_attributes(:records_processed => @results[:records_processed])
    end

    def stop_worker
      exit
    end

    def importer_update_processing_vars_at_end
      if @successful
        @results[:notice] = 'Import was successful.'
        @results[:done_with_do_work] = true
        @import.update_attributes(:status => 'complete')
      else
        @results[:notice] = 'Import failed. '
        if !@results[:error].nil?
          logger.info("import error: #{@results[:error]}")
          @results[:notice] += @results[:error]
        end
        @results[:done_with_do_work] = true
        @import.update_attributes(:status => 'failed')
      end
      cache[:results] = @results
      stop_worker
    end

    def importer_update_processing_vars_if_rescue
      @results[:error], @successful  = $!.to_s, false
      @results[:done_with_do_work] = true
      cache[:results] = @results
      @import.update_attributes(:status => 'failed')
      stop_worker
    end

    # override in your importer worker to customize
    # takes an xml element
    def importer_process(record, params)
      current_record = @results[:records_processed] + 1
      logger.info("starting record #{current_record}")

      record_hash = importer_xml_record_to_hash(record)
      reason_skipped = nil

      logger.info("record #{current_record} : looking for topic")

      # will only work with topics
      # we need a title attribute
      # if this is well set up there should only be one matching record_hash key
      # that is a title synonym, we go with last match just in case
      title = nil
      record_hash.keys.each do |field_name|
        title = record_hash[field_name].strip if TITLE_SYNONYMS.include?(field_name)
      end
      existing_item = @current_basket.topics.find_by_title(title)

      new_record = nil
      if existing_item.nil?
        description_end_template = @description_end_templates['default']
        new_record = create_new_item_from_record(record, @zoom_class, {:params => params, :record_hash => record_hash, :description_end_template => description_end_template })
      else
        logger.info("what is existing item: " + existing_item.id.to_s)
        # record exists in kete already
        reason_skipped = 'kete already has a copy of this record'
      end

      if !new_record.nil? and !new_record.id.nil?
        logger.info("new record succeeded for insert")
        importer_prepare_and_save_to_zoom(new_record)
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

    # XPATH was proving too unreliable
    # switching to pulling record to a hash
    # and grabbing the specific fields
    # we need to check
    def importer_xml_record_to_hash(record)
      record_hash = Hash.from_xml(record.to_s)

      # HACK to go down one more level
      record_hash.keys.each do |record_field|
        record_hash = record_hash[record_field]
      end
      logger.info("record_hash inspect: " + record_hash.inspect)
      record_hash
    end

    # override in your importer worker to customize
    # takes a potentially huge xml file and strips out all the empty fields
    # so it much more manageable
    # output is to a tmp file
    # has commented out code for replacing macronized vowels
    # uncomment if you need them
    def importer_trim_fat_from_xml_import_file(path_to_original_file,path_to_output,accession = nil)
      fat_free_file = File.new(path_to_output,'w+')

      fatty_re = Regexp.new("\/\>.*")

      accessno_re = Regexp.new("ACCESSNO>(.*)<")

      IO.foreach(path_to_original_file) do |line|
        # HACK to seriously trim down accession records
        # and make them in a form we can search easily
        # only add non-fat to our fat_free_file
        if !line.match(fatty_re) and !line.blank?
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
            if line.include?("ACCESSNO") or line.include?("DESCRIP") or line.include?("\/Record") or line.include?("Information") or line.include?("Root")
              if line.include?("ACCESSNO")
                accessno = line.match(accessno_re)[1]
                new_start_record_line = "<Record ACCESSNO=\'#{accessno}\'>\n"
                fat_free_file << new_start_record_line
              else
                fat_free_file << line
              end
            end
          end
        end
      end

      fat_free_file.close

      return path_to_output
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
      params[zoom_class_for_params] = Hash.new

      if options[:basket_id].nil?
        params[zoom_class_for_params][:basket_id] = @current_basket.id
      else
        params[zoom_class_for_params][:basket_id] = options[:basket_id]
      end

      # check extended_field.import_field_synonyms
      # for which extended field to map the import_field to
      # special cases for title, short_summary, and description
      record_hash = Hash.new
      if options[:record_hash].nil?
        record_hash = importer_xml_record_to_hash(record)
      else
        record_hash = options[:record_hash]
      end

      field_count = 1
      tag_list_array = Array.new
      # add support for all items during this import getting a set of tags
      # added to every item in addition to the specific ones for the item
      tag_list_array = @import.base_tags.split(",") if !@import.base_tags.blank?

      record_hash.keys.each do |record_field|
        logger.debug("record_field " + record_field.inspect)
        unless IMPORT_FIELDS_TO_IGNORE.include?(record_field)
          value = record_hash[record_field]
          if !value.nil?
            value = value.strip
            # replace \r with \n
            value.gsub(/\r/, "\n")
          end

          if !value.blank?
            # if it's mapped to an extended field, params are updated
            params = importer_prepare_extended_field(:value => value,
                                                     :field => record_field,
                                                     :zoom_class_for_params => zoom_class_for_params,
                                                     :params => params)

            # the field may also be mapped to non-extended fields
            # such as tags, description, title
            # the value maybe used multiple times, so case isn't appropriate
            if record_field.upcase == 'TITLE' || (!TITLE_SYNONYMS.blank? && TITLE_SYNONYMS.include?(record_field))
              params[zoom_class_for_params][:title] = value
            end

            if !DESCRIPTION_SYNONYMS.blank? && DESCRIPTION_SYNONYMS.include?(record_field)
              if params[zoom_class_for_params][:description].nil?
                params[zoom_class_for_params][:description] = value
              else
                params[zoom_class_for_params][:description] += "\n\n" + value
              end
            end

            if !SHORT_SUMMARY_SYNONYMS.blank? && SHORT_SUMMARY_SYNONYMS.include?(record_field)
              if params[zoom_class_for_params][:short_summary].nil?
                params[zoom_class_for_params][:short_summary] = value
              else
                params[zoom_class_for_params][:short_summary] += "\n\n" + value
              end
            end

            if !TAGS_SYNONYMS.blank? && TAGS_SYNONYMS.include?(record_field)
              tag_list_array << value.gsub("\n", " ")
            end

            # path_to_file is special case, we know we have an associated file that goes in uploaded_data
            if record_field == 'path_to_file'
              logger.debug("in path_to_file")
              if ::Import::VALID_ARCHIVE_CLASSES.include?(zoom_class)
                # we do a check earlier in the script for imagefile
                # so we should have something to work with here
                upload_hash = { :uploaded_data => copy_and_load_to_temp_file(value) }
                if zoom_class == 'StillImage'
                  logger.debug("in image")
                  params[:image_file] = upload_hash
                else
                  logger.debug("in not image")
                  params[zoom_class_for_params] = params[zoom_class_for_params].merge(upload_hash)
                end
              end
            end
          end
          field_count += 1
        end
      end

      logger.info("after fields")


      if !@import.description_beginning_template.blank?
        # append the citation to the description field
        if !params[zoom_class_for_params][:description].nil?
          params[zoom_class_for_params][:description] = @import.description_beginning_template + "\n\n" + params[zoom_class_for_params][:description]
        else
          params[zoom_class_for_params][:description] = @import.description_beginning_template
        end
      elsif !DESCRIPTION_TEMPLATE.blank?
        if !params[zoom_class_for_params][:description].nil?
          params[zoom_class_for_params][:description] = DESCRIPTION_TEMPLATE + "\n\n" + params[zoom_class_for_params][:description]
        else
          params[zoom_class_for_params][:description] = DESCRIPTION_TEMPLATE
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

      description = String.new
      # used to give use better html output for descriptions
      if !params[zoom_class_for_params][:description].nil?
        description = RedCloth.new params[zoom_class_for_params][:description]
        params[zoom_class_for_params][:description] = description.to_html
      end

      params[zoom_class_for_params][:tag_list] = tag_list_array.join(",")

      # set the chosen privacy
      private_setting = @import.private
      logger.debug("private = " + private_setting.to_s)
      params[zoom_class_for_params][:private] = private_setting

      # add the uniform license chosen at import to this item
      params[zoom_class_for_params][:license_id] = @import.license.id if !@import.license.blank?

      # clear any lingering values for @fields
      # and instantiate it, in case we need it
      @fields = nil

      if zoom_class == 'Topic'
        params[zoom_class_for_params][:topic_type_id] = @import_topic_type.id

        @fields = @import_topic_type.topic_type_to_field_mappings

        ancestors = TopicType.find(@import_topic_type).ancestors

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
        logger.info("fields larger than 0")

        # we use our version of this method
        # that calls xml builder directly, rather than using partial template
        params[zoom_class_for_params.to_sym] = params[zoom_class_for_params]
        params = importer_extended_fields_update_hash_for_item(:item_key => zoom_class_for_params, :params => params)
      end

      logger.info("after field set up")

      # replace with something that isn't reliant on params
      replacement_zoom_item_hash = importer_extended_fields_replacement_params_hash(:item_key => zoom_class_for_params, :item_class => zoom_class, :params => params)

      new_record = Module.class_eval(zoom_class).new(replacement_zoom_item_hash)
      new_record_added = new_record.save

      if new_record_added
        importer_add_image_to(new_record, params, zoom_class) unless params[:image_file].blank?
        new_record.creator = @contributing_user
        logger.info("in topic creation made it past creator")
      else
        logger.info("what are errors on save of new record: " + new_record.errors.inspect)
      end

      return new_record
    end

    # override in your importer worker to customize
    def importer_log_to_skipped_records(identifier,reason_skipped)
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
      temp_params = Hash.new
      temp_params[:topic] = topic_params["topic"]
      topic_params = importer_extended_fields_update_hash_for_item(:item_key => 'topic', :params => temp_params)

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
      related_topic = Topic.create!(:title => topic_params[:topic][:title],
                                    :description => topic_params[:topic][:description],
                                    :short_summary => topic_params[:topic][:short_summary],
                                    :extended_content => topic_params[:topic][:extended_content],
                                    :basket_id => topic_params[:topic][:basket_id],
                                    :license_id => topic_params[:topic][:license_id],
                                    :topic_type_id => topic_params[:topic][:topic_type_id],
                                    :do_not_moderate => true
                                    )

      related_topic.creator =  @contributing_user
      related_topic
    end
  end
end
