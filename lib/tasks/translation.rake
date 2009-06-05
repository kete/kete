# lib/tasks/translation.rake
#
# export/import translations
#
# Kieran Pilkington, 2009-06-04
#
namespace :kete do
  namespace :translation do

    namespace :excel_2003 do

      desc 'Export translation to Microsoft Excel 2003 compatible format (pass in LOCALE key)'
      task :export do
        ensure_locale_present

        translation_hash = YAML.load(IO.read(@translation_file))

        write '<?xml version="1.0"?>'
        write '<?mso-application progid="Excel.Sheet"?>'
        write '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'
        write '          xmlns:o="urn:schemas-microsoft-com:office:office"'
        write '          xmlns:x="urn:schemas-microsoft-com:office:excel"'
        write '          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'
        write '          xmlns:html="http://www.w3.org/TR/REC-html40">'
        write '  <Styles>'
        write '    <Style ss:ID="1"><Font ss:Bold="1"/></Style>'
        write '  </Styles>'
        write '  <Worksheet ss:Name="Sheet1">'
        write '    <Table>'
        write '      <Column ss:Width="150"/>'
        write '      <Column ss:Width="850"/>'
        write '      <Row ss:StyleID="1">'
        write '        <Cell><Data ss:Type="String">Key (DNC)</Data></Cell>'
        write '        <Cell><Data ss:Type="String">Value</Data></Cell>'
        write '      </Row>'
        write output_rows(translation_hash[ENV['LOCALE']])
        write '    </Table>'
        write '  </Worksheet>'
        write '</Workbook>'

        puts "Export Completed! XML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml")}"
      end

      desc 'Import translation from Microsoft Excel 2003 compatible format (pass in FILE_PATH to XML file)'
      task :import do
        ensure_locale_present
        ensure_file_path_present
        raise "Not yet implemented"
      end

      private

      def output_rows(hash, return_result = true)
        @result ||= Array.new
        @base_keys ||= Array.new
        @keys ||= Array.new
        hash.sort.each do |k,v|
          next unless k =~ /\w(\w|\d)+/
          @keys << k
          if v.is_a?(Hash)
            output_rows(v, false)
          elsif v.is_a?(String)
            data = [
              '      <Row>',
              "        <Cell><Data ss:Type=\"String\">#{h(@keys.join('.'))}</Data></Cell>",
              "        <Cell><Data ss:Type=\"String\">#{h(v)}</Data></Cell>",
              '      </Row>' ]
            data.each { |d| (@keys.first == 'base' ? @base_keys : @result) << d }
          end
          @keys.pop
        end
        if return_result
          @keys = nil
          @base_keys.join("\n") + "\n" + @result.join("\n")
        end
      end

    end

    namespace :xml do

      desc 'Export translations to nested XML format (pass in LOCALE key)'
      task :export do
        ensure_locale_present

        translation_hash = YAML.load(IO.read(@translation_file))
        write strip_invalid_keys_and_values_from(translation_hash).to_xml

        puts "Export Completed! XML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml")}"
      end

      desc 'Import translation from nested XML format (pass in FILE_PATH to XML file)'
      task :import do
        ensure_locale_present
        ensure_file_path_present

        translation_xml = IO.read(ENV['FILE_PATH'])
        write Hash.from_xml(translation_xml)['hash'].to_yaml, :yml

        puts "Import Completed! YAML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.yml")}"
      end

      private

      def strip_invalid_keys_and_values_from(hash, print_deleted = true)
        @keys_deleted ||= Array.new
        hash.delete_if do |k,v|
          if k.to_s =~ /^\w(\w|\d|-)+$/ &&
              k.to_s =~ /^[a-zA-Z]/ &&
              k.to_s =~ /[a-zA-Z0-9]$/ &&
              !v.is_a?(Array)
            false
          else
            @keys_deleted << [k, v]
            true
          end
        end
        hash.each do |k,v|
          next unless v.is_a?(Hash)
          strip_invalid_keys_and_values_from(v, false)
        end
        if print_deleted
          puts "Deleting the following keys because either the key is not a valid string or the value is an array:"
          @keys_deleted.each { |k,v| puts "  #{k.inspect} -> #{v.inspect}" }
          puts "These above keys and values will need to be added manually during import."
        end
        hash
      end

    end

    private

    def ensure_locale_present
      raise 'ERROR: No LOCALE value was set. Please set one when running the task again.' unless ENV['LOCALE']
      @translation_file = File.join(RAILS_ROOT, "config/locales/#{ENV['LOCALE']}.yml")
      raise "ERROR: config/locales/#{ENV['LOCALE']}.yml does not exist." unless File.exists?(@translation_file)
    end

    def ensure_file_path_present
      raise 'ERROR: No FILE_PATH value was set. Please set one when running the task again.' unless ENV['FILE_PATH']
      raise "ERROR: #{ENV['FILE_PATH']} does not exist." unless File.exists?(ENV['FILE_PATH'])
    end

    def write(text, format = :xml)
      @output ||= File.new(File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.#{format.to_s}"), 'w')
      @output.puts text
    end

    def h(text)
      text.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
    end

  end
end
