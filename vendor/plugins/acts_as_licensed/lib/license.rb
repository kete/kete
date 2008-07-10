class License < ActiveRecord::Base

  # the following could be a named scope which works the same way but shorter
  # named_scope :find_available, :conditions => ['is_available', true]
  def self.find_available
    License.find(:all, :conditions => ['is_available', true])
  end

  def self.import_from_yaml(yaml_file, verbose = true)
    attr_sets = YAML.load(File.open(File.join(RAILS_ROOT, "vendor/plugins/acts_as_licensed/fixtures/#{yaml_file}")))
    attr_sets.each do |attrs|
      # Fixtures are returned as name => { value, .. }. We only need the values.
      attrs = attrs.last

      # Only insert licences if they do not already exist, using URL as unique key.
      if !License.find(:first, :conditions => ['url = ?', attrs["url"]])
        begin
          License.create!(attrs)
          p "Inserted license: '#{attrs["name"]}'." if verbose
        rescue
          p "Inserting license '#{attrs["name"]} failed: #{$!}."
        end
      else
        p "Skipped '#{attrs["name"]}': License already exists." if verbose
      end
    end
  end

  def title
    name
  end

end
