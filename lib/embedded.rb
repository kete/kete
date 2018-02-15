require 'mini_exiftool'
# Read (and perhaps later write) embedded metadata from binary files
# and make a new embedded object (of class MiniExiftool) available
# so that it can be mapped to attributes of our model
# requires mini_exiftool gem
# which in turn requires the exiftool command line utility (http://www.sno.phy.queensu.ca/~phil/exiftool/index.html)
# written by Phil Harvey
# we also rely on attachment_fu attributes to access the binary file
# and attachment_fu's workflow on uploaded files
module Embedded
  unless included_modules.include? Embedded
    def self.included(klass)
      # declare the virtual attribute that we can stuff the embedded metadata into
      klass.send :attr_accessor, :embedded

      klass.send :before_validation, :harvest_embedded_metadata_to_attributes unless klass.name == 'StillImage'
    end

    include LatitudeLongitudeConvertors

    # this does the bulk of the work
    def populate_attributes_from_embedded_in(file_path)
      # if there is no file we just leave it up to validation
      # to sort out what needs doing
      return unless File.exist?(file_path)

      # read the metadata from the file and load it into embedded attribute
      # mini_exiftool may not recognize all our acceptable file types, if it fails, log it, but return
      # so that the calling process can continue its merry way
      begin
        mini_exiftool = MiniExiftool.new(file_path)
      rescue
        logger.info('Embedded metadata harvesting skipped.  Details are: ' + $!.message)
        return
      end
      embedded_hash = Hash.new
      mini_exiftool.tags.collect { |tag_name| embedded_hash[tag_name] = mini_exiftool[tag_name] }
      embedded = embedded_hash

      # look at the mappings between
      # either default fields (title, short_summary, tags, etc.)
      # or extended fields

      # get constants and values from system settings that end with "synonyms"
      # to get standard fields that to match against

      # TODO: this may be MySQL specific, test with PostgreSQL
      conditions = "name LIKE '%Synonyms'"
      conditions += " AND name NOT LIKE 'Short Summary%'" unless %w[Topic Document].include?(self.class.name)

      relevant_settings = SystemSetting.find(:all, conditions: conditions)

      # work through the settings and get their derived constant name
      standard_attribute_synonyms = Hash.new
      relevant_settings.each do |setting|
        # this will make the key the attribute name as a string
        # and the value corresponding array for synonyms
        # we add the variants of the attribute name, too
        # TODO: wrap this handling of name variants
        # being added to import synonyms up for reuse in importers
        raw_attribute_name = setting.name.gsub(' Synonyms', '')
        attribute_name = raw_attribute_name.downcase.tr(' ', '_')

        name_variants = [
          attribute_name.upcase,
          attribute_name.humanize,
          attribute_name.camelize,
          attribute_name,
          raw_attribute_name]

        attribute_synonyms = name_variants + Object.const_get(setting.constant_name).to_a

        standard_attribute_synonyms[attribute_name] = attribute_synonyms
      end

      embedded.each do |key, value|
        # get rid of any extra white space at beginning or end of value
        value = value.strip if value.is_a?(String)

        # accept ; as demarkation of separate values
        # Adobe's Bridge software doesn't use commas
        if value.is_a?(String) && key.downcase == 'subject'
          value = value.split(';').collect { |i| i.strip }
        end

        # get rid of nil, empty, or whitespace only items in array
        value = value.reject { |i| i.blank? } if value.is_a?(Array)

        standard_attribute_synonyms.each do |a_name, synonyms|
          # if the embedded key in the list of the attribute's synonyms
          # we have a match and should assign the value of the embedded key's value
          if synonyms.include?(key)
            case a_name
            when 'description'
              value.to_a.each do |value|
                embedded_description = RedCloth.new value
                self.description += embedded_description.to_html
              end
            when 'tags'
              all_tags = tag_list.split(',')
              all_tags = all_tags + value.to_a

              all_tags = all_tags.reject { |i| i.blank? }

              self.tag_list = all_tags.join(',')
              # since embedded harvesting happens after the controller before filter
              # on create and update
              # we have to do this by hand here
              self.raw_tag_list = all_tags.join(',')
            else
              # if the current value is prefixed with "-replace-"
              # we know it is a placeholder
              # and we should overwrite it
              # else we will append any previous value for the field
              # to preserve the value that may have been added in the form
              current_value = send(a_name)

              if current_value.blank? || current_value =~ /^-replace-/
                send("#{a_name}=", value)
              else
                if current_value.is_a?(String)
                  current_value += ' '
                  value = value.to_s
                end
                send("#{a_name}=", current_value + value)
              end
            end
          end
        end

        # limit scope to only those extended fields mapped to the item's content type
        matching_extended_fields = ContentType.find_by_class_name(self.class.name).form_fields.find(:all, conditions: "import_synonyms like \'%#{key}%\'")

        matching_extended_fields.each do |field|
          if %( map map_address ).include?(field.ftype)
            unless SystemSetting.enable_maps?
              raise 'Error: Trying to use Google Maps without configuation (config/google_map_api.yml)'
            end
            coords = convert_dms_to_decimal_degree(value)
            value = { 
              'zoom_lvl' => SystemSetting.default_zoom_level.to_s,
              'no_map' => '0',
              'coords' => "#{coords[:latitude]},#{coords[:longitude]}" 
            }
            send("#{field.label_for_params}=", value)
          else
            send("#{field.label_for_params}+=", value)
          end
        end
      end
    end

    # note, this isn't meant for StillImage
    # StillImage case where actually it is still_image's original ImageFile
    # we need to grab the data from and then pass up to the still_image object
    # THIS HANDLES SIMPLE CASE, for audio, video, documents where they DO NOT have a separate model
    # of attachments
    # we only want to do this once, otherwise each edit
    # the metadata will be harvested and appended to existing records
    def harvest_embedded_metadata_to_attributes
      populate_attributes_from_embedded_in(temp_path) if new_record?
    end

    private :harvest_embedded_metadata_to_attributes
  end
end
