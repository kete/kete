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

    xl_xml = Nokogiri::XML(File.read(path_to_dfc_xml_file))
    rows = xl_xml.search("metadata/asset")

    output = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.records do
        rows.each do |row|
          xml.record do
            titles = Hash.new
            is_accession_record = false
            row.search("field").each do |field|
              value = field.inner_text.strip
              next if value.blank?
              field_name = field.attributes['name'].to_s || '__No_Name__'
              xml.send(field_name, value)
              titles[field_name] = value if %w{ Title Item_Listing Filename }.include?(field_name)
              is_accession_record = true if field_name == 'Record_Type' && value.downcase == 'accession'
              # we use "path_to_file" internally, but "Filename" is the column name we get
              xml.path_to_file(@import_dir_path + '/files/' + value) if field_name == 'Filename'
            end
            xml.Title(titles['Filename'] || 'Untitled') if titles['Title'].nil? || titles['Title'].blank?
            xml.Record_Identifier($1.strip.to_i) if is_accession_record && titles['Filename'] =~ /(\d+)/
          end
        end
      end
    end

    File.open(path_to_records_file_output, 'w') {|f| f.write(output.to_xml) }
  end

end
