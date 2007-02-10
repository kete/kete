module ExtendedContentController
  unless included_modules.include? ExtendedContentController
    def self.included(klass)
      # not much here for now, but could expand later
      # you need to define load_content_type in your controller
      klass.send :before_filter, :load_content_type, :only => [:new, :show, :edit, :create, :update]
      klass.send :permit, "site_admin or moderator or member or admin of :current_basket", :only => [ :new, :create, :edit, :update]
      # put revert in here when we get to it
      klass.send :permit, "site_admin or moderator or admin of :current_basket", :only =>  [ :destroy ]
    end
  end

end
