module LocationMapper
  unless included_modules.include? LocationMapper
    def self.included(klass)
      case klass.name
      when 'BasketsController'
        klass.send :before_filter, :instantiate_google_map, :only => ['choose_type']
      else
        klass.send :before_filter, :instantiate_google_map, :only => ['new', 'create', 'edit', 'update']
      end
    end

    private

    def instantiate_google_map
      @using_google_maps = true
    end
  end
end