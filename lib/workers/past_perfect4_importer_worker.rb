require 'tempfile'
require 'fileutils'
require 'mime/types'
require 'rexml/document'
require 'builder'
require 'redcloth'
require "oai_dc_helpers"
require "zoom_helpers"
require "extended_content_helpers"
# past perfect 4 xml output importer
# only handling photos for the moment
# needs accompanying archives.xml file
# to create topics to group photos by
# review http://development.kete.net.nz/kete/tickets/66 for details
# right now we create a topic for the collection (ACCESSNO from image)
# and add related images to it
# see OBJECTID goes to user_reference
class PastPerfect4ImporterWorker < BackgrounDRb::Worker::RailsBase
  # can only use the methods that don't render
  # aren't overly dependent on params hash
  include OaiDcHelpers

  include ZoomHelpers

  include ExtendedContentHelpers

  def do_work(args)
    logger.info('PastPerfect4ImporterWorker do work')
    results[:do_work_time] = Time.now.to_s
    results[:done_with_do_work] = false
    begin
      @zoom_class = args[:zoom_class]
      @import_topic_type_for_related_topic = args[:import_topic_type_for_related_topic]
      @import_type = args[:import_type]
      @import_dir_path = args[:import_dir_path]
      @path_to_skipped_records = args[:path_to_skipped_records]
      @import_parent_dir_for_image_dirs = args[:import_parent_dir_for_image_dirs]
      @contributing_user = User.find(args[:contributing_user])
      @import_request = args[:import_request]

      @zoom_class_for_params = @zoom_class.tableize.singularize

      @import_field_to_extended_field_map = Hash.new

      @import_photos_file_path = "#{@import_dir_path}/photos.xml"

      # this may not work because of scope
      params = args[:params]

      @path_to_trimmed_photos = trim_fat_from_pp4_xml_import_file(@import_photos_file_path,"#{RAILS_ROOT}/tmp/trimmed_photos_pp4.xml")
      @import_photos_xml = REXML::Document.new File.open(@path_to_trimmed_photos)

      @import_accessions_file_path = "#{@import_dir_path}/accessions.xml"
      @path_to_trimmed_accessions = trim_fat_from_pp4_xml_import_file(@import_accessions_file_path,"#{RAILS_ROOT}/tmp/trimmed_accessions_pp4.xml",true)

      # open the accessions xml to search for a matching record later
      @import_accessions_xml = REXML::Document.new File.open(@path_to_trimmed_accessions)
      # this gets the first matching accession record
      logger.debug("opened accession")

      @import_accessions_xml_root = @import_accessions_xml.root

      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])

      @successful = false

      @related_topic_type = TopicType.find_by_name(@import_topic_type_for_related_topic)

      @last_related_topic = nil

      @last_related_topic_pp4_objectid = nil

      # we work from the photos
      # and grab information from the accessions file
      # bases on ACCESSNO as a kind of forein key
      # as we need it
      results[:records_processed] = 0
      @import_photos_xml.elements.each("Root/Information/Record") do |record|
        current_record = results[:records_processed] + 1
        logger.info("starting record #{current_record}")

        # clear this out so last related_topic
        # doesn't persist
        related_topic = nil
        related_topic_pp4_objectid = nil
        existing_item = nil
        image_file = nil
        image_objectid = nil
        objectid = nil

        # XPATH was proving too unreliable
        # switching to pulling record to a hash
        # and grabbing the specific fields
        # we need to check
        record_hash = Hash.from_xml(record.to_s)

        # HACK to go down one more level
        record_hash.keys.each do |record_field|
          record_hash = record_hash[record_field]
        end

        # make sure there is a imagefile value
        # if not, log record to skipped photos file with reason skipped
        image_file = record_hash["IMAGEFILE"]

        logger.debug("what is image_file: " + image_file)

        image_objectid = record_hash["OBJECTID"]

        reason_skipped = nil

        path_to_file_to_grab = prepare_path_to_image_file(image_file)

        if image_file.nil? or !File.exists?(path_to_file_to_grab)
          reason_skipped =  'no image file specified or the image file isn\'t available'
          logger.debug("record #{current_record} : reason skipped image")
        else
          logger.debug("record #{current_record} : looking for topic")
          # grab the relate_to_topic_id
          # by getting the ACCESSNO field's value
          # see if there is a matching topic already
          # if not, create one from match in @import_accessions_xml
          # no match, log record to skipped photos file with reason skipped
          related_topic_pp4_objectid = record_hash["ACCESSNO"]

          if related_topic_pp4_objectid.nil?
            # see if we can derive the accessno from the objectid
            # if we can't derive the accessno, just stick it in without
            # related topic
            objectid_parts = image_objectid.split(".")
            if objectid_parts.size > 2
              related_topic_pp4_objectid = objectid_parts[0] + "." + objectid_parts[1]
            else
              related_topic_pp4_objectid = 0
              related_topic = 0
              # reason_skipped.add_text 'no ACCESSNO specified'
              # logger.debug("record #{current_record} : reason skipped no ACCESSNO")
            end
          end

          if related_topic_pp4_objectid != 0
            # this item has the same related_topic as the last
            # don't bother looking it up again
            if !@last_related_topic_pp4_objectid.nil? and related_topic_pp4_objectid == @last_related_topic_pp4_objectid
              related_topic = @last_related_topic
            else
              related_topic = Topic.find(:first,
                                         :conditions => "extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{related_topic_pp4_objectid}</user_reference>%\' AND topic_type_id = #{@related_topic_type.id}")

            end

            related_accession_record = nil

            # no existing related topic
            # find the record in accessions
            # and create topic from it
            if related_topic.nil?
              logger.debug("record #{current_record} : no kete topic found")

              logger.debug("in creation of accession record")

              logger.debug("accession we are looking for: " + related_topic_pp4_objectid)

              if record_hash["COLLECTION"] != "HHS Photograph Collection"
                # file may time out
                related_accession_record = nil

                related_accession_record = @import_accessions_xml_root.elements["Information/Record[@ACCESSNO=\'#{related_topic_pp4_objectid}\']"]
                # we have some accesion record's that are mangled
                # by being three sections
                # rather than two
                # grab only the first two elements
                # and try again before giving up
                if related_accession_record.blank?
                  cleaned_accessno_array = related_topic_pp4_objectid.split(".")
                  cleaned_up_accessno = cleaned_accessno_array[0] + "." + cleaned_accessno_array[1]

                  logger.debug("looking for cleaned up accession: " + cleaned_up_accessno)

                  if !@last_related_topic_pp4_objectid.nil? and  cleaned_up_accessno == @last_related_topic_pp4_objectid
                    logger.debug("looking for cleaned up accession: last accessno match")
                    related_topic = @last_related_topic
                  else
                    logger.debug("looking for cleaned up accession: looking for existing topic")
                    related_topic = Topic.find(:first,
                                               :conditions => "extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{cleaned_up_accessno}</user_reference>%\' AND topic_type_id = #{@related_topic_type.id}")

                  end

                  if related_topic.nil?
                    related_accession_record = @import_accessions_xml_root.elements["Information/Record[@ACCESSNO=\'#{cleaned_up_accessno}\']"]
                  end
                  related_topic_pp4_objectid = cleaned_up_accessno
                end

                if !related_accession_record.blank? and related_topic.nil?
                  accession_record_hash = Hash.from_xml(related_accession_record.to_s)

                  # HACK to go down one more level
                  accession_record_hash.keys.each do |record_field|
                    accession_record_hash = accession_record_hash[record_field]
                  end

                  # create a new topic from related_accession_record
                  # prepare user_reference for extended_content
                  accession_topic = { "topic" => { :topic_type_id => @related_topic_type.id,
                      :title => record_hash["COLLECTION"]} }

                  descrip = RedCloth.new accession_record_hash['DESCRIP']
                  accession_topic["topic"][:description] = descrip.to_html
                  accession_topic["topic"][:short_summary] = prepare_short_summary(descrip)


                  topic_params = prepare_extended_field(:value => related_topic_pp4_objectid, :field => 'OBJECTID', :zoom_class_for_params => 'topic', :params => accession_topic)

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

                  if @fields.size > 0
                    # we use our version of this method
                    # that calls xml builder directly, rather than using partial template
                    # HACK, conflict with symbol vs string for hash key
                    # duplicate
                    temp_params = Hash.new
                    temp_params[:topic] = topic_params["topic"]
                    topic_params = pp4_extended_fields_update_hash_for_item(:item_key => 'topic', :params => temp_params)
                  end

                  topic_params[:topic][:basket_id] = @current_basket.id

                  # replace with something that isn't reliant on params
                  # replacement_topic_hash = pp4_extended_fields_replacement_params_hash(:item_key => "topic", :item_class => 'Topic', :params => topic_params)

                  related_topic = Topic.create!(:title => topic_params[:topic][:title],
                                                :description => topic_params[:topic][:description],
                                                :short_summary => topic_params[:topic][:short_summary],
                                                :extended_content => topic_params[:topic][:extended_content],
                                                :basket_id => topic_params[:topic][:basket_id],
                                                :topic_type_id => topic_params[:topic][:topic_type_id]
                                                )

                  related_topic.creators << @contributing_user
                  logger.debug("after related topic creation")
                end
              end
            end
          end

          # TODO: if there is an object with a matching exactly user_reference,
          # and the modified date of the import record is later
          # do an update instead

          # base our check on OBJECTID
          objectid = record_hash["OBJECTID"]

          logger.debug("what is objectid: " + objectid)

          # this relies on user_reference extended_field
          # being mapped to the particular kete content type (not content type in mime sense)
          existing_item = Module.class_eval(@zoom_class).find(:first,
                                                              :conditions => "extended_content like \'%<user_reference xml_element_name=\"dc:identifier\">#{objectid}</user_reference>%\'")

          new_record = nil
          if existing_item.nil?
            # figure out the citation based on the objectid
            citation = "Any use of this image must be accompanied by the credit \"Horowhenua Historical Society Inc.\""
            if !image_objectid.scan(/f\d/).blank?
              # this is a foxton entry
              citation = "Any use of this image must be accompanied by the credit \"Foxton Historical Society\""
            elsif !image_objectid.scan("2000\.000\.")
              citation = "Any use of this image must be accompanied by the credit \"Horowhenua District Council\""
            end

            new_record = create_new_item_from_pp4_record(record, @zoom_class, {:params => params, :record_hash => record_hash, :citation => citation })
          else
            logger.debug("what is existing item: " + existing_item.id.to_s)
            # record exists in kete already
            reason_skipped = 'kete already has a copy of this record'
          end

          if !new_record.nil? and !new_record.id.nil?
            # we may not have a related topic, only add the relation if we do
            if !related_topic.nil? and related_topic != 0
              ContentItemRelation.new_relation_to_topic(related_topic.id, new_record)

              if @last_related_topic.nil? or related_topic.id != @last_related_topic.id
                # update the last topic, since we are done adding things to it for now
                pp4_prepare_and_save_to_zoom(related_topic)
                sleep(5)
              end
            end

            pp4_prepare_and_save_to_zoom(new_record)
            sleep(3)

            # now that we know that we have a valid related_topic
            # update @last_related_topic and @last_related_topic_pp4_objectid
            @last_related_topic = related_topic
            @last_related_topic_pp4_objectid = related_topic_pp4_objectid

            @successful = true
            results[:records_processed] += 1
          end
        end
        # if this record was skipped, add to skipped_records
        if !reason_skipped.blank?
          log_to_skipped_records(image_file,reason_skipped)
        end
        # will this help memory leaks
        record = nil
      end

      if @successful
        results[:notice] = 'Import was successful.'
        results[:done_with_do_work] = true
      else
        results[:notice] = 'Import failed. '
        if  !results[:error].nil?
          logger.info("import error: #{results[:error]}")
          results[:notice] += results[:error]
        end
        results[:done_with_do_work] = true
      end
    rescue
      results[:error], @successful  = $!.to_s, false
      results[:done_with_do_work] = true
    end
    # ActiveRecord::Base.connection.disconnect!
    # ::BackgrounDRb::MiddleMan.instance.delete_worker @_job_key
  end

  def prepare_extended_field(options = {})
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
        params[zoom_class_for_params][extended_field.label_for_params] = value
      end
    end
    return params
  end

  # takes the huge pp4 xml file and strips out all the empty fields
  # so it much more manageable
  # output is to a tmp file
  def trim_fat_from_pp4_xml_import_file(path_to_original_pp4_file,path_to_output,accession = nil)
    fat_free_file = File.new(path_to_output,'w+')

    fatty_re = Regexp.new("\/\>.*")

    accessno_re = Regexp.new("ACCESSNO>(.*)<")

    IO.foreach(path_to_original_pp4_file) do |line|
      # HACK to seriously trim down accession records
      # and make them in a form we can search easily
        # only add non-fat to our fat_free_file
        if !line.match(fatty_re) and !line.blank?
          if accession.nil?
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

  # expects an xml element of our record
  def create_new_item_from_pp4_record(record, zoom_class, options = {})
    zoom_class_for_params = zoom_class.tableize.singularize

    params = options[:params]

    # initialize the subhash in params
    # clears it out if it does already
    params[zoom_class_for_params] = Hash.new

    params[zoom_class_for_params][:basket_id] = @current_basket

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

    record_hash.keys.each do |record_field|
      value = record_hash[record_field]
      if !value.nil?
        value = value.strip
        # replace \r with \n
        value.gsub(/\r/, "\n")
      end

      if !value.blank?

        case record_field
        when "TITLE"
          params[zoom_class_for_params][:title] = value
        when *DESCRIPTION_SYNONYMS
          if params[zoom_class_for_params][:description].nil?
            params[zoom_class_for_params][:description] = value
          else
            params[zoom_class_for_params][:description] += "\n\n" + value
          end
        when *TAGS_SYNONYMS
          if record_field == "PEOPLE"
            # each person is in the form: last name, first names
            # one name per line
            # it may have things in parentheses which we ignore
            people_in_lines = value.split("\n")
            people_in_lines.each do |person|
              names_array = person.split(",")
              first_names = String.new
              if !names_array[1].nil?
                first_names = names_array[1].split("(")[0].strip
              end
              last_names = names_array[0].strip
              name = first_names + " " + last_names
              tag_list_array << name.strip
            end
          else
            tag_list_array << value.gsub("\n", " ")
          end
        when "ADMIN"
          if zoom_class == 'Topic' or zoom_class == 'Document'
            params[zoom_class_for_params][:short_summary] = value
          else
            if params[zoom_class_for_params][:description].nil?
              params[zoom_class_for_params][:description] = value
            else
              params[zoom_class_for_params][:description] += "\n" + value
            end
          end
        when "IMAGEFILE"
          if zoom_class == 'StillImage'
            # we do a check earlier in the script for imagefile
            # so we should have something to work with here
            params[:image_file] = { :uploaded_data => copy_and_load_to_temp_file(prepare_path_to_image_file(value)) }
          end
        when "OBJECTID"
          if zoom_class == 'Topic'
            value = record_hash["ACCESSNO"]
          end
          params = prepare_extended_field(:value => value, :field => record_field, :zoom_class_for_params => zoom_class_for_params, :params => params)
        else
          params = prepare_extended_field(:value => value, :field => record_field, :zoom_class_for_params => zoom_class_for_params, :params => params)
        end
      end
      field_count += 1
    end

    logger.debug("after fields")


    if !options[:citation].nil?
      # append the citation to the description field
      if !params[zoom_class_for_params][:description].nil?
        params[zoom_class_for_params][:description] += "\n\n" + options[:citation]
      else
        params[zoom_class_for_params][:description] = options[:citation]
      end
    end

    logger.debug("after citation")

    description = String.new
    # used to give use better html output for descriptions
    if !params[zoom_class_for_params][:description].nil?
      description = RedCloth.new params[zoom_class_for_params][:description]
      params[zoom_class_for_params][:description] = description.to_html
    end

    logger.debug("after redcloth")

    if zoom_class == 'Topic' or zoom_class == 'Document' && params[zoom_class_for_params][:short_summary].nil?
      if !description.blank?
        params[zoom_class_for_params][:short_summary] = prepare_short_summary(description)
      end
    end

    logger.debug("after short summary")

    params[zoom_class_for_params][:tag_list] = tag_list_array.join(",")

    logger.debug("after tag list")

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
      params = pp4_extended_fields_update_hash_for_item(:item_key => zoom_class_for_params, :params => params)
    end

    logger.debug("after field set up")

    # replace with something that isn't reliant on params
    replacement_zoom_item_hash = pp4_extended_fields_replacement_params_hash(:item_key => zoom_class_for_params, :item_class => zoom_class, :params => params)

    new_record = Module.class_eval(zoom_class).new(replacement_zoom_item_hash)
    new_record_added = new_record.save

    # add the image file and then close it
    if !params[:image_file].nil? and zoom_class == 'StillImage'
      logger.debug("what is params[:image_file]: " + params[:image_file].to_s)
      new_image_file = ImageFile.new(params[:image_file])
      new_image_file.still_image_id = new_record.id
      new_image_file.save
      # attachment_fu doesn't insert our still_image_id into the thumbnails
      # automagically
      new_image_file.thumbnails.each do |thumb|
        thumb.still_image_id = new_record.id
        thumb.save!
      end
    end

    new_record.creators << @contributing_user

    return new_record
  end

  def log_to_skipped_records(image_file,reason_skipped)
    # TODO: make this log to file that was specified
    logger.info("#{image_file}: #{reason_skipped}")
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

  # populate extended_fields param with xml
  # based on params from the form
  def pp4_extended_fields_update_hash_for_item(options = {})
    params = options[:params]
    item_key = options[:item_key].to_sym

    xml = Builder::XmlMarkup.new

    @fields.each do |field_to_xml|
      field_name = field_to_xml.extended_field_label.downcase.gsub(/ /, '_')
      if field_to_xml.extended_field_multiple
        xml.tag!("#{field_name}_multiple") do
          hash_of_values = params[item_key][field_name]
          hash_of_values.keys.each do |key|
            xml.tag!(key) do
              extended_content_field_xml_tag(:xml => xml,
                                             :field => field_name,
                                             :value => params[item_key][field_name][key],
                                             :xml_element_name => field_to_xml.extended_field_xml_element_name,
                                             :xsi_type => field_to_xml.extended_field_xsi_type)
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
  def pp4_extended_fields_replacement_params_hash(options = {})
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

    return replacement_hash
  end

  def pp4_oai_record_xml(options = { })
    item = options[:item]
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.tag!("OAI-PMH", "xmlns:xsi".to_sym => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation".to_sym => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd", "xmlns" => "http://www.openarchives.org/OAI/2.0/") do
      xml.responseDate(Time.now.to_s(:db))
      oai_dc_xml_request(xml,item,@import_request)
      xml.GetRecord do
        xml.record do
          xml.header do
            oai_dc_xml_oai_identifier(xml,item)
            xml.datestamp(Time.now.to_s(:db))
          end
          xml.metadata do
            xml.tag!("oai_dc:dc", "xmlns:oai_dc".to_sym => "http://www.openarchives.org/OAI/2.0/oai_dc/", "xmlns:xsi".to_sym => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/", "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/", "xsi:schemaLocation".to_sym => "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd") do
              pp4_oai_dc_xml_dc_identifier(xml,item,@import_request)
              oai_dc_xml_dc_title(xml,item)
              oai_dc_xml_dc_publisher(xml,@import_request[:host])
              # topic specific
              if item.class.name == 'Topic' || item.class.name == 'Document'
                oai_dc_xml_dc_description(xml,item.short_summary)
              end

              oai_dc_xml_dc_description(xml,item.description)

              oai_dc_xml_dc_creators_and_date(xml,item)

              oai_dc_xml_dc_contributors_and_modified_dates(xml,item)

              # all types at this point have an extended_content attribute
              oai_dc_xml_dc_extended_content(xml,item)

              # related topics and items should have dc:subject elem here with their title
              pp4_oai_dc_xml_dc_relations_and_subjects(xml,item,@import_request)

              oai_dc_xml_dc_type(xml,item)

              oai_dc_xml_tags_to_dc_subjects(xml,item)

              # this is mime type
              oai_dc_xml_dc_format(xml,item)
            end
          end
        end
      end
    end
    record = xml.to_s
    return record.gsub("<to_s\/>","")
  end

  def pp4_prepare_zoom(item)
    # only do this for members of ZOOM_CLASSES
    if ZOOM_CLASSES.include?(item.class.name)
      begin
        item.oai_record = pp4_oai_record_xml(:item => item)
        item.basket_urlified_name = @current_basket.urlified_name
      rescue
        logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
      end
    end
  end

  def pp4_prepare_and_save_to_zoom(item)
    pp4_prepare_zoom(item)
    item.zoom_save
  end

  def pp4_item_url(options = {})
    host = options[:host]
    item = options[:item]
    controller = options[:controller]
    urlified_name = options[:urlified_name]
    "http://#{host}/#{urlified_name}/#{controller}/show/#{item.to_param}"
  end

  def pp4_oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
    if !passed_request.nil?
      host = passed_request[:host]
    else
      host = request.host
    end
    # HACK, brittle, but can't use url_for here
    xml.tag!("dc:identifier", pp4_item_url(:host => host, :controller => zoom_class_controller(item.class.name), :item => item, :urlified_name => @current_basket.urlified_name))
  end

  def pp4_oai_dc_xml_dc_relations_and_subjects(xml,item,passed_request = nil)
    if !passed_request.nil?
      host = passed_request[:host]
    else
      host = request.host
    end

    if item.class.name == 'Topic'
      ZOOM_CLASSES.each do |zoom_class|
        related_items = ''
        if zoom_class == 'Topic'
          related_items = item.related_topics
        else
          related_items = item.send(zoom_class.tableize)
        end
        related_items.each do |related|
          xml.tag!("dc:subject", related.title)
          xml.tag!("dc:relation", pp4_item_url(:host => host, :controller => zoom_class_controller(zoom_class), :item => related, :urlified_name => related.basket.urlified_name))
        end
      end
    else
      item.topics.each do |related|
        xml.tag!("dc:subject", related.title)
        xml.tag!("dc:relation", pp4_item_url(:host => host, :controller => :topics, :item => related, :urlified_name => related.basket.urlified_name))
      end
    end
  end
  def prepare_short_summary(source_string, length = 25, end_string = '')
    # length is how many words, rather than characters
    words = source_string.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

  def prepare_path_to_image_file(image_file)
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
end
PastPerfect4ImporterWorker.register
