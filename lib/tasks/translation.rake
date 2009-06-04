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
        raise 'ERROR: No LOCALE value was set. Please set one when running the task again.' unless ENV['LOCALE']

        translation_file = File.join(RAILS_ROOT, "config/locales/#{ENV['LOCALE']}.yml")
        raise "ERROR: config/locales/#{ENV['LOCALE']}.yml does not exist." unless File.exists?(translation_file)
        translation_hash = YAML.load(IO.read(translation_file))

        xml_file = File.new(File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml"), 'w')
        xml_file.puts '<?xml version="1.0"?>'
        xml_file.puts '<?mso-application progid="Excel.Sheet"?>'
        xml_file.puts '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'
        xml_file.puts '          xmlns:o="urn:schemas-microsoft-com:office:office"'
        xml_file.puts '          xmlns:x="urn:schemas-microsoft-com:office:excel"'
        xml_file.puts '          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'
        xml_file.puts '          xmlns:html="http://www.w3.org/TR/REC-html40">'
        xml_file.puts '  <Styles>'
        xml_file.puts '    <Style ss:ID="1"><Font ss:Bold="1"/></Style>'
        xml_file.puts '  </Styles>'
        xml_file.puts '  <Worksheet ss:Name="Sheet1">'
        xml_file.puts '    <Table>'
        xml_file.puts '      <Column ss:Width="150"/>'
        xml_file.puts '      <Column ss:Width="850"/>'
        xml_file.puts '      <Row ss:StyleID="1">'
        xml_file.puts '        <Cell><Data ss:Type="String">Key (DNC)</Data></Cell>'
        xml_file.puts '        <Cell><Data ss:Type="String">Value</Data></Cell>'
        xml_file.puts '      </Row>'
        xml_file.puts parse(translation_hash[ENV['LOCALE']])
        xml_file.puts '    </Table>'
        xml_file.puts '  </Worksheet>'
        xml_file.puts '</Workbook>'
        puts "Export Completed! XML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml")}"
      end

      desc 'Import translation from Microsoft Excel 2003 compatible format (pass in XML_FILE path)'
      task :import do
        raise 'ERROR: No XML_FILE path value was set. Please set one when running the task again.' unless ENV['XML_FILE']
        raise "Not yet implemented"
      end

      private

      def parse(hash, return_result = true)
        @result ||= Array.new
        @base_keys ||= Array.new
        @keys ||= Array.new
        hash.sort.each do |k,v|
          next unless k =~ /\w(\w|\d)+/
          @keys << k
          if v.is_a?(Hash)
            parse(v, false)
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

      def h(text)
        text.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;')
      end

    end

  end
end
