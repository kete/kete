require 'zoom_db'
require 'oai_pmh_repository_set'

# reopen zoom_db class
# to handle our static and dynamic sets
module ConfigureZoomDbForSets
  unless included_modules.include? ConfigureZoomDbForSets
    def self.included(klass)
      klass.has_many :oai_pmh_repository_sets, :dependent => :destroy
    end

    def active_sets
      @active_sets = oai_pmh_repository_sets.find_all_by_active(true)
    end

    # return static sets
    # and generate dynamic sets and return them, too
    # in form suitable for oai request
    # as array
    def sets
      sets = Array.new
      active_sets.each do |active_set|
        sets += active_set.generated_sets
      end
      sets
    end

    # return complete xml
    def complete_sets
      xml = Builder::XmlMarkup.new
      active_sets.each do |active_set|
        active_set.append_generated_sets_to(xml)
      end
      xml
    end

  end
end

