# lib/tasks/redirects.rb
#
# utitlities for importing redirect_registrations
#
# Walter McGinnis, 2012-06-21

namespace :redirects do
  namespace :imports do
    desc 'Create RedirectRegistration instances based on Excel XML file (EXCEL_FILE=path_to_file_relative_to_calling_dir).'
    task excel: :environment do
      source_file = pwd + '/' + ENV['EXCEL_FILE']

      records = ExcelPreProcessor.new(source_file).records

      records.each do |record|
        RedirectRegistration.create! record
      end
      p "Added #{records.count} redirect registrations."
    end
  end
end

require 'logger'
require 'nokogiri'
class ExcelPreProcessor < Nokogiri::XML::SAX::Document
  def initialize(path_to_xl_xml_file, options = {})
    excel_xml = File.read(path_to_xl_xml_file)

    # Wrap all data in CData tags to prevent parsing issues unless they already have one
    excel_xml.gsub!(/<(?:ss\:)?Data[^>]*>(.*)<\/(?:ss\:)?Data>/i) do |match|
      value = $1
      value = "<![CDATA[#{value.gsub('&amp;', '&')}]]>" unless value =~ /^<\!\[CDATA\[/i
      "<Data>#{value}</Data>"
    end

    parser = Nokogiri::XML::SAX::Parser.new(self)
    parser.parse(excel_xml)
    self
  end

  attr_accessor :column_headers
  attr_accessor :records
  attr_accessor :within_table
  attr_accessor :within_row, :current_row
  attr_accessor :within_cell
  attr_accessor :within_data, :current_cell

  def start_document
    self.column_headers = Array.new
    self.records = Array.new
    self.within_table = false
    self.within_row = false
    self.current_row = 0
    self.current_cell = 0
    self.within_data = false
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
      self.within_cell = true
      attributes_and_values = attributes.flatten
      if self.current_row > 1 && attributes_and_values.include?('ss:HRef')
        href = attributes_and_values[attributes_and_values.index('ss:HRef') + 1]
        element_name = column_headers[self.current_cell - 1]
        records.last[element_name] = href.strip
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
    when :Cell, :"ss:Cell"
      self.within_cell = false
    when :Data, :"ss:Data"
      self.within_data = false
    end
  end

  private

  # we assume href is set as an attribute on the cell, so do nothing with value
  # unless we are on the first row
  # in which case we set column headers
  def process_value(value)
    return unless within_table && within_data

    if self.current_row == 1
      column_headers << (value.strip.empty? ? '__No_Name__' : value.strip)
    # else
#       return if value.strip.empty?
#       element_name = self.column_headers[self.current_cell - 1]
#       return unless element_name
#       element_name = element_name.gsub(' ', '_').strip

#       # self.records.last[element_name] = value.strip
    end
  end
end
