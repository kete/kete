require 'importer'
class DfcXmlImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :dfc_xml_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
    @record_identifier_xml_field = 'Record_Identifier'
    @related_topics_reference_in_record_xml_field = 'Accession'
  end

  # this takes dfc's standard xml export format
  # stored in the file records.dfc.xml
  # and converts it to Kete's standard format
  # that we will store in records.xml
  # expects that first row is column names
  def records_pre_processor
    path_to_records_file_output = @import_dir_path + '/records.xml'
    path_to_dfc_xml_file = @import_dir_path + '/records.dfc.xml'
    path_to_dfc_convertor_log = @import_dir_path + '/convert.log'

    File.open(path_to_dfc_convertor_log, 'w') do |log|
      # we don't need a separate trimming of fat from the xml file
      # as Nokogiri does that for use in XML building process
      @skip_trimming = true

      return if File.exist?(path_to_records_file_output)

      dfc_xml = Nokogiri::XML(File.read(path_to_dfc_xml_file))
      rows = dfc_xml.search('metadata/asset')

      output = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.records do
          rows.each do |row|
            fields = Hash.new

            row.search('field').each do |field|
              value = field.inner_text.strip
              field_name = field.attributes['name'].to_s.gsub(/\s/, '_')
              next if value.blank? || field_name.blank?
              fields[field_name] = value
            end

            unless fields['Filename'].blank?
              # we use "path_to_file" internally, but "Filename" is the column name we get
              file_path = @import_dir_path + '/files/' + fields['Filename']
              fields['path_to_file'] = file_path if File.exists?(file_path)
            end

            if @zoom_class == 'StillImage' && !fields['path_to_file']
              log.write("Photograph #{fields['Filename']} not found at #{@import_dir_path}. Skipping record.\n")
              next
            end

            xml.record do
              fields.each do |field_name, value|
                xml.safe_send(field_name, value)
              end

              title_parts, filename_without_ext = Array.new, fields['Filename'].split('.').first

              case (fields['Record_Type'] || '').downcase
              when 'archives', 'publication'
                title_parts << "Collection Title: #{fields['Collection_Title']}" unless fields['Collection_Title'].blank?
                title_parts << "Reference: #{fields['Archive_Reference']}" unless fields['Archive_Reference'].blank?
                title_parts << "Part #{$1.strip}" if filename_without_ext =~ /([a-z])$/
              when 'photograph'
                title_parts << "Collection Title: #{fields['Collection_Title']}" unless fields['Collection_Title'].blank?
                title_parts << "Reference: #{fields['Photograph_Reference']}" unless fields['Photograph_Reference'].blank?
                title_parts << "Part #{$1.strip}" if filename_without_ext =~ /([a-z])$/
              else
                xml.Record_Identifier($1.strip.to_i) if fields['Filename'] =~ /(\d+)/
              end

              # If we don't have an title parts at this point, make one up based on the filename
              title_parts << filename_without_ext if title_parts.blank?

              xml.Record_Title(title_parts.join(' - '))
            end
          end
        end
      end

      File.open(path_to_records_file_output, 'w') { |f| f.write(output.to_xml) }
    end
  end
end
