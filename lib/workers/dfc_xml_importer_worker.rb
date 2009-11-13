require "importer"
class DfcXmlImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :dfc_xml_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
    @related_topic_key_field = "Accession"
  end

  # this takes dfc's standard xml export format
  # stored in the file records.dfc.xml
  # and converts it to Kete's standard format
  # that we will store in records.xml
  # expects that first row is column names
  def records_pre_processor
    path_to_records_file_output = @import_dir_path + '/records.xml'
    path_to_dfc_xml_file = @import_dir_path + '/records.dfc.xml'

    # we don't need a separate trimming of fat from the xml file
    # as Nokogiri does that for use in XML building process
    @skip_trimming = true

    return if File.exist?(path_to_records_file_output)

    dfc_xml = Nokogiri::XML(File.read(path_to_dfc_xml_file))
    rows = dfc_xml.search("metadata/asset")

    output = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.records do
        rows.each do |row|
          xml.record do
            is_accession_record, titles, descriptions = false, Hash.new, Hash.new

            row.search("field").each do |field|
              value = field.inner_text.strip
              field_name = field.attributes['name'].to_s
              next if value.blank? || field_name.blank?
              xml.send(field_name, value)

              case field_name
              when 'Title', 'Filename'
                titles[field_name] = value
              when 'Description', 'Comments', 'Item_Listing', 'History'
                descriptions[field_name] = value
              when 'Record_Type'
                is_accession_record = true if value.downcase == 'accession'
              when 'Filename'
                # we use "path_to_file" internally, but "Filename" is the column name we get
                xml.path_to_file(@import_dir_path + '/files/' + value)
              end
            end

            xml.Record_Identifier($1.strip.to_i) if is_accession_record && titles['Filename'] =~ /(\d+)/

            # If more than one record exists without a title, it'll be skipped
            # So add code to skip topic check if the title is Untitled?
            xml.Record_Title(titles['Title'] || titles['Filename'] || 'Untitled')

            # For each description part, append data below a heading
            # We run the description through redcloth, so use it's formatting
            xml.Record_Description(descriptions.collect { |k, v| "h3. #{k.humanize}\n\n#{v}\n\n" }.join)
          end
        end
      end
    end

    File.open(path_to_records_file_output, 'w') {|f| f.write(output.to_xml) }
  end

end
