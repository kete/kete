require 'yaml'

class Hash
  def deep_merge(other)
    # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
    merger = proc { |key, v1, v2| (Hash === v1 && Hash === v2) ? v1.merge(v2, &merger) : v2 }
    merge(other, &merger)
  end

  def set(keys, value)
    key = keys.shift
    if keys.empty?
      self[key] = value
    else
      self[key] ||= {}
      self[key].set keys, value
    end
  end

  if ENV['SORT']
    # copy of ruby's to_yaml method, prepending sort.
    # before each so we get an ordered yaml file
    def to_yaml( opts = {} )
      YAML::quick_emit( self, opts ) do |out|
        out.map( taguri, to_yaml_style ) do |map|
          sort.each do |k, v| #<- Adding sort.
            map.add( k, v )
          end
        end
      end
    end
  end
end

namespace :translate do
  desc "Show I18n keys that are missing in the config/locales/default_locale.yml YAML file"
  task :lost_in_translation => :environment do
    LOCALE = I18n.default_locale
    keys = []; result = []; locale_hash = {}
    Dir.glob(File.join("config", "locales", "**","#{LOCALE}.yml")).each do |locale_file_name|
      locale_hash = locale_hash.deep_merge(YAML::load(File.open(locale_file_name))[LOCALE])
    end
    lookup_pattern = Translate::Keys.new.send(:i18n_lookup_pattern)
    Dir.glob(File.join("app", "**","*.{rb,rhtml}")).each do |file_name|
      File.open(file_name, "r+").each do |line|
        line.scan(lookup_pattern) do |key_string|
          result << "#{key_string} in \t  #{file_name} is not in any locale file" unless key_exist?(key_string.first.split("."), locale_hash)
        end
      end
    end
    puts !result.empty? ? result.join("\n") : "No missing translations for locale: #{LOCALE}"
  end

  def key_exist?(key_arr,locale_hash)
    key = key_arr.slice!(0)
    if key
      key_exist?(key_arr, locale_hash[key]) if (locale_hash && locale_hash.include?(key))
    elsif locale_hash
      true
    end
  end

  desc "Merge I18n keys from log/translations.yml into config/locales/*.yml (for use with the Rails I18n TextMate bundle)"
  task :merge_keys => :environment do
    I18n.backend.send(:init_translations)
    new_translations = YAML::load(IO.read(File.join(Rails.root, "log", "translations.yml")))
    raise("Can only merge in translations in single locale") if new_translations.keys.size > 1
    locale = new_translations.keys.first

    overwrites = false
    Translate::Keys.new.send(:extract_i18n_keys, new_translations[locale]).each do |key|
      new_text = key.split(".").inject(new_translations[locale]) { |hash, sub_key| hash[sub_key] }
      existing_text = I18n.backend.send(:lookup, locale.to_sym, key)
      if existing_text && new_text != existing_text
        puts "ERROR: key #{key} already exists with text '#{existing_text.inspect}' and would be overwritten by new text '#{new_text}'. " +
          "Set environment variable OVERWRITE=1 if you really want to do this."
        overwrites = true
      end
    end

    if !overwrites || ENV['OVERWRITE']
      I18n.backend.store_translations(locale, new_translations[locale])
      Translate::Storage.new(locale).write_to_file
    end
  end

  desc "Apply Google translate to auto translate all texts in locale ENV['FROM'] to locale ENV['TO']"
  task :google => :environment do
    raise "Please specify FROM and TO locales as environment variables" if ENV['FROM'].blank? || ENV['TO'].blank?

    # Depends on httparty gem
    # http://www.robbyonrails.com/articles/2009/03/16/httparty-goes-foreign
    class GoogleApi
      include HTTParty
      base_uri 'ajax.googleapis.com'
      def self.translate(string, to, from)
        tries = 0
        begin
          get("/ajax/services/language/translate",
            :query => {:langpair => "#{from}|#{to}", :q => string, :v => 1.0},
            :format => :json)
        rescue
          tries += 1
          puts("SLEEPING - retrying in 5...")
          sleep(5)
          retry if tries < 10
        end
      end
    end

    I18n.backend.send(:init_translations)

    start_at = Time.now
    translations = {}
    Translate::Keys.new.i18n_keys(ENV['FROM']).each do |key|
      from_text = I18n.backend.send(:lookup, ENV['FROM'], key).to_s
      to_text = I18n.backend.send(:lookup, ENV['TO'], key)
      if !from_text.blank? && to_text.blank?
        print "#{key}: '#{from_text[0, 40]}' => "
        if !translations[from_text]
          response = GoogleApi.translate(from_text, ENV['TO'], ENV['FROM'])
          translations[from_text] = response["responseData"] && response["responseData"]["translatedText"]
        end
        if !(translation = translations[from_text]).blank?
          translation.gsub!(/\(\(([a-z_.]+)\)\)/i, '{{\1}}')
          # Google translate sometimes replaces {{foobar}} with (()) foobar. We skip these
          if translation !~ /\(\(\)\)/
            puts "'#{translation[0, 40]}'"
            I18n.backend.store_translations(ENV['TO'].to_sym, Translate::Keys.to_deep_hash({key => translation}))
          else
            puts "SKIPPING since interpolations were messed up: '#{translation[0,40]}'"
          end
        else
          puts "NO TRANSLATION - #{response.inspect}"
        end
      end
    end

    puts "\nTime elapsed: #{(((Time.now - start_at) / 60) * 10).to_i / 10.to_f} minutes"
    Translate::Storage.new(ENV['TO'].to_sym).write_to_file
  end

  desc 'Create a new translation based on the English translation (pass in LOCALE_CODE - a two letter country code, and LOCALE_NAME - the translated name of the language you\'re adding.)'
  task :create do
    raise "LOCALE_CODE (two letter country code) is not set. Please set one before running the rake task." unless ENV['LOCALE_CODE']
    raise "LOCALE_NAME (translated translation name) is not set. Please set one before running the rake task." unless ENV['SKIP_ACCESS'] || ENV['LOCALE_NAME']

    en = File.join(RAILS_ROOT, "config/locales/en.yml")
    new_locale = File.join(RAILS_ROOT, "config/locales/#{ENV['LOCALE_CODE']}.yml")

    if File.exists?(new_locale)
      puts "config/locales/#{ENV['LOCALE_CODE']}.yml already exists. Skipping locale creation..."
    else
      File.open(new_locale, 'w') do |new|
        File.open(en, 'r') do |old|
          lines = old.readlines
          lines[1] = "#{ENV['LOCALE_CODE']}:\n"
          new.print lines
        end
      end

      locales = File.join(RAILS_ROOT, "config/locales.yml")
      unless ENV['SKIP_ACCESS'] || !File.exists?(locales)
        File.open(locales, 'a') do |f|
          f.print "\n#{ENV['LOCALE_CODE']}: #{ENV['LOCALE_NAME']}"
        end
      end

      puts "#{ENV['LOCALE_NAME']} (#{ENV['LOCALE_CODE']}) has been added."
    end
  end

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
      write '      <Column ss:Width="425"/>'
      write '      <Column ss:Width="425"/>'
      write '      <Row ss:StyleID="1">'
      write '        <Cell><Data ss:Type="String">Key (DNC)</Data></Cell>'
      write '        <Cell><Data ss:Type="String">Value</Data></Cell>'
      write '        <Cell><Data ss:Type="String">Translation</Data></Cell>'
      write '      </Row>'
      write output_rows(translation_hash[ENV['LOCALE']])
      write '    </Table>'
      write '  </Worksheet>'
      write '</Workbook>'

      remove_locale_file_if_automatically_created

      puts "Export Completed! XML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml")}"
    end

    desc 'Import translation from Microsoft Excel 2003 compatible format (pass in FILE_PATH to XML file)'
    task :import do
      ensure_locale_present(false)
      ensure_file_path_present

      require 'nokogiri'
      require 'ya2yaml'
      $KCODE = 'u'

      # <Workbook>
      #   <ss:Worksheet>
      #     <Table>
      #       <Row>
      #         <Cell>
      #           <Data>key</Data>
      #         </Cell>
      #         <Cell>
      #           <Data>original value</Data>
      #         </Cell>
      #         <Cell>
      #           <Data>translated value</Data>
      #         </Cell>
      #       </Row>
      #     </Table>
      #   </ss:Worksheet>
      # </Workbook>

      values = { ENV['LOCALE'] => {} }
      xml = Nokogiri::XML(File.read(ENV['FILE_PATH']))
      rows = xml.root.search("Table/Row")
      rows.shift

      rows.each do |row|
        value = Array.new
        row.search("Cell").each do |cell|
          cell.search("Data").each do |data|
            value << data.inner_text
          end
        end
        unless value.empty?
          keys = value[0].split('.')
          last_key = keys.pop

          level = values[ENV['LOCALE']]
          keys.each { |key| level[key] ||= Hash.new; level = level[key] }
          level[last_key] = value[2]
        end
      end

      write values.ya2yaml, :yml

      puts "Import Completed! YAML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.yml")}"
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
            "        <Cell><Data ss:Type=\"String\"></Data></Cell>",
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

      remove_locale_file_if_automatically_created

      puts "Export Completed! XML file saved to #{File.join(RAILS_ROOT, "tmp/#{ENV['LOCALE']}.xml")}"
    end

    desc 'Import translation from nested XML format (pass in FILE_PATH to XML file)'
    task :import do
      ensure_locale_present(false)
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

  def ensure_locale_present(file_be_present=true)
    raise 'ERROR: No LOCALE value was set. Please set one when running the task again.' unless ENV['LOCALE']
    if file_be_present
      @translation_file = File.join(RAILS_ROOT, "config/locales/#{ENV['LOCALE']}.yml")
      unless File.exists?(@translation_file)
        ENV['LOCALE_CODE'] = ENV['LOCALE']
        ENV['SKIP_ACCESS'] = 'true'
        Rake::Task["kete:translation:create"].execute(ENV)
        @created_file_automatically = true
      end
    end
  end

  def remove_locale_file_if_automatically_created
    if @created_file_automatically
      locale_file = File.join(RAILS_ROOT, "config/locales/#{ENV['LOCALE']}.yml")
      File.delete(locale_file) if File.exists?(locale_file)
    end
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
