# frozen_string_literal: true

require 'importer'

require 'nokogiri'
require 'logger'
class ExcelPreProcessor < Nokogiri::XML::SAX::Document
  def initialize(path_to_xl_xml_file, options = {})
    # maybe TODO: refactor assignment from options
    # this fixes cut and paste error when code was moved to separate class
    # but ExcelPreProcessor may know too much about the calling environment
    @zoom_class = options[:zoom_class]
    @import_dir_path = options[:import_dir_path]
    @record_interval = options[:record_interval]

    @logger = Logger.new('/home/kete/excel-parse.log')
    excel_xml = File.read(path_to_xl_xml_file)

    # Wrap all data in CData tags to prevent parsing issues unless they already have one
    excel_xml.gsub!(/<(?:ss\:)?Data[^>]*>(.*)<\/(?:ss\:)?Data>/i) do |match|
      value = $1
      value = "<![CDATA[#{value.gsub('&amp;', '&')}]]>" unless value =~ /^<\!\[CDATA\[/i
      "<Data>#{value}</Data>"
    end

    parser = Nokogiri::XML::SAX::Parser.new(self)
    @logger.info 'after new sax parser'
    parser.parse(excel_xml)
    @logger.info 'after parsing'
    self
  end

  attr_accessor :column_headers
  attr_accessor :records
  attr_accessor :within_table
  attr_accessor :within_row, :current_row
  attr_accessor :within_data, :current_cell
  attr_accessor :has_path_to_file

  def start_document
    self.column_headers = Array.new
    self.records = Array.new
    self.within_table = false
    self.within_row = false
    self.current_row = 0
    self.current_cell = 0
    self.within_data = false
    self.has_path_to_file = false
  end

  def start_element(name, attributes = [])
    case name.to_sym
    when :Table
      self.within_table = true
    when :Row
      self.within_row = true
      self.current_row += 1
      records << Hash.new
    when :Cell
      # ss:Index helps compact filesize but causes issues with our column header
      # allocation so make use of it to prevent any issues from popping up
      if attributes.include?('ss:Index')
        self.current_cell = attributes[attributes.index('ss:Index') + 1].to_i
      else
        self.current_cell += 1
      end
    when :Data, :"ss:Data"
      self.within_data = true
    end
  end

  def cdata_block(string)
    process_value(string)
  end

  def characters(string)
    process_value(string)
  end

  def end_element(name)
    case name.to_sym
    when :Table
      self.within_table = false
      self.current_row = 0
    when :Row
      self.within_row = false
      self.current_cell = 0
      records.pop if records.last.empty?
    when :Data, :"ss:Data"
      self.within_data = false
    end
  end

  private

  def process_value(value)
    @logger.info "in process_value: #{value}"
    return unless within_table && within_data

    if self.current_row == 1
      column_headers << (value.strip.empty? ? '__No_Name__' : value.strip)
    else
      return if value.strip.empty?
      element_name = column_headers[self.current_cell - 1]
      return unless element_name
      element_name = element_name.tr(' ', '_').strip

      unless has_path_to_file
        case element_name.downcase
        when 'file'
          # we use "path_to_file" internally, but "File" or "file" are likely the column name
          # change those to path_to_file element_name. Resolve the absolute path of file too
          element_name = 'path_to_file'
          value = value[0] if value.is_a?(Array)
          value = @import_dir_path + '/files/' + value
          has_path_to_file = true
        when 'folder'
          if @zoom_class == 'Document'
            pdfs_path = "#{@import_dir_path}/pdfs"
            pdf_file = "#{pdfs_path}/#{value[0]}.pdf"
            unless File.exist?(pdf_file)
              images_path = "#{@import_dir_path}/files/#{value[0]}"
              if File.directory?(images_path)
                begin
                  require 'prawn'
                  images = Dir["#{images_path}/*"]
                  FileUtils.mkdir_p pdfs_path unless File.directory?(pdfs_path)
                  Prawn::Document.generate(pdf_file, page_layout: :landscape) do
                    images.each_with_index do |file, index|
                      start_new_page unless index == 0
                      image file
                    end
                  end
                  # give the server a break (esp when pdfs with thousands of images are created)
                  sleep(@record_interval) if @record_interval > 0
                rescue
                  msg = "PDF Generation failed in #{value[0]}. Are you using image types besides JPG or PNG?\n"
                  msg += "Here's what the server tells us is the problem:\n" + $!.to_s
                  logger.info msg
                  raise msg
                end
              else
                msg = "The directory #{images_path} does not exist, but was expected to be there."
                logger.info msg
                raise msg
              end
            end

            element_name = 'path_to_file'
            value = pdf_file
            self.has_path_to_file = true
          end
        end
      end
      records.last[element_name] = value.strip
    end
  end
end

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

    # we don't need a separate trimming of fat from the xml file
    # as Nokogiri does that for use in XML building process
    @skip_trimming = true

    return if File.exist?(path_to_records_file_output)

    rows = ExcelPreProcessor.new(path_to_xl_xml_file, zoom_class: @zoom_class, import_dir_path: @import_dir_path, record_interval: @record_interval).records

    builder =
      Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.records do
          rows.each do |row|
            xml.record do
              row.each do |element_name, value|
                xml.safe_send(element_name, value)
              end
            end
          end
        end
      end

    File.open(path_to_records_file_output, 'w') { |f| f.write(builder.to_xml) }
  end
end
