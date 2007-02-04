module ExtendedContentController
  unless included_modules.include? ExtendedContentController
    def self.included(klass)
      # not much here for now, but could expand later
      # you need to define load_content_type in your controller
      klass.send :before_filter, :load_content_type, :only => [:new, :show, :edit, :create, :update]
    end
  end

end
