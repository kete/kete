require "importer"
class ExcelBasedImporterWorker < BackgrounDRb::MetaWorker
  set_worker_name :excel_based_importer_worker
  set_no_auto_load true

  # importer has the version of methods that will work in the context
  # of backgroundrb
  include Importer

  # do_work method is defined in Importer module
  def create(args = nil)
    importer_simple_setup
  end
  
  # this takes excel's standard xml export format
  # stored in the file records.xl.xml
  # and converts it to Kete's standard format
  # that we will store in records.xml
  # expects that first row is column names
  def records_pre_processor
    path_to_records_file_output = @import_dir_path + '/records.xml'
    path_to_xl_xml_file = @import_dir_path + '/records.xl.xml'

    return if File.exist?(path_to_records_file_output)

    xl_xml = Nokogiri::XML(File.read(path_to_xl_xml_file))
    rows = xl_xml.root.search("Table/Row")
    
    # grab the spec 
    names_row = rows.first

    # create an array of column names
    # column name's array index will be used to name output XML element
    # to data rows' data value
    # empty cells will be called __No_Name__
    # they likely hold empty values (one assumes spacers columns or perhaps undetected end of row columns)
    names_array = Array.new
    names_row.search("Cell").each do |cell|
      data = cell.at("Data")
      if data
        names_array << data.text
      else
        names_array << "__No_Name__"
      end
    end

    # and pop spec row off rows
    # so that rows are only data rows from here on out
    rows.shift

    # set up our XML builder and start adding to it
    output = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.records do
        rows.each do |row|
          xml.record do
            cell_index = 0
            row.search("Cell").each do |cell|
              value = Array.new

              cell.search("Data").each do |data|
                value << data.inner_text
              end
              
              element_name = names_array[cell_index].gsub(' ', '_')

              # we use "path_to_file" internally, but "File" or "file" are likely the column name
              # change those to path_to_file element_name
              element_name = 'path_to_file' if element_name == 'File' || element_name == 'file'

              # resolve the absolute path of file
              if element_name == 'path_to_file'
                value = @import_dir_path + '/files/' + value[0]
                value.to_a
              end

              # add an element to our output XML for the value
              xml.send(element_name, value) unless value.empty?

              cell_index += 1
            end
          end
        end
      end
    }
    # write the file out
    File.open(path_to_records_file_output, 'w') {|f| f.write(output.to_xml) }
  end

end
