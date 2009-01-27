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
    # declare the virtual attribute that we can stuff the embedded metadata into
    attr_accessor :embedded

    before_validation :harvest_embedded_metadata_to_attributes unless self.class.is_a?(StillImage)

    # note, this isn't meant for StillImage
    # StillImage case where actually it is still_image's original ImageFile
    # we need to grab the data from and then pass up to the still_image object
    # THIS HANDLES SIMPLE CASE, for audio, video, documents where they DO NOT have a separate model
    # of attachments
    def harvest_embedded_metadata_to_attributes
      # read the metadata from the file and load it into embedded attribute
      self.embedded = MiniExiftool.new(self.full_filename)

      # look at the mappings between
      # either default fields (title, short_summary, tags, etc.)
      # or extended fields

      # get constants and values from system settings that end with "synonyms"
      # to get standard fields that to match against

      # TODO: this may be MySQL specific, test with PostgreSQL
      conditions = "name LIKE '%Synonyms'"
      conditions += " AND name NOT LIKE 'Short Summary%'" unless %w(Topic Document).include?(self.class.name)

      relevant_settings = SystemSetting.find(:all, :conditions => conditions)

      # work through the settings and get their derived constant name
      standard_attribute_synonyms = Hash.new
      relevant_settings.each do |setting|
        # this will make the key the attribute name as a string
        # and the value corresponding array for synonyms
        standard_attribute_synonyms[setting.name.gsub(' Synonyms', '').downcase.gsub(' ', '_')] = Object.const_get(setting.constant_name)
      end

      embedded.each do |key, value|
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
              all_tags = self.tag_list.split(',')
              all_tags = all_tags + value.to_a

              self.tag_list = all_tags.to_sentence
            else
              # will append any previous value for the field
              # to preserve the value that may have been added in the form
              self.send("#{a_name}+=", value)
            end
          end
          matching_extended_fields = ExtendedField.find(:all, :conditions => "import_synonyms like \'%#{key}%\'")

          matching_extended_fields.each do |field|
            self.send("#{field.label_to_param}+=", value)
          end
        end
      end

    end

    private :harvest_embedded_metadata_to_attributes
  end
end
