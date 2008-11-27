module ExtendedContentController
  unless included_modules.include? ExtendedContentController
    def self.included(klass)
      # stuff related to flagging and moderation
      klass.send :include, FlaggingController

      # Kieran Pilkington, 2008/10/23
      # Autocomplete methods for tag adder on item pages
      klass.send :include, TaggingController

      # Kieran Pilkington, 2008/11/26
      # Instantiation of Google Map code for location settings
      klass.send :include, LocationMapper

      klass.send :permit, "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket",
                          :only => [ :new, :create, :edit, :update, :convert]

      klass.send :permit, "site_admin or moderator of :current_basket or admin of :current_basket",
                          :only =>  [ :destroy, :restore, :reject, :make_theme ]

      # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
      klass.send :verify, :method => :post,
                          :only => [ :destroy, :create, :update ],
                          :redirect_to => { :action => :list }

      # override the site wide protect_from_forgery to exclude
      # things that you must be logged in to do anyway or at least a moderator
      klass.send :protect_from_forgery, :secret => KETE_SECRET, :except => ['new', 'destroy']

      unless klass.name == 'TopicsController'
        # used to determined appropriate extended fields for the model you are operating on
        klass.send :before_filter, :load_content_type,
                                   :only => [:show, :new, :create, :edit, :update]
      end

      ### TinyMCE WYSIWYG editor stuff
      klass.send :uses_tiny_mce, :options => DEFAULT_TINYMCE_SETTINGS,
                                 :only => VALID_TINYMCE_ACTIONS
      ### end TinyMCE WYSIWYG editor stuff

      klass.send :helper, :privacy_controls

      def load_content_type
        @content_type = ContentType.find_by_class_name(zoom_class_from_controller(params[:controller]))
      end
    end
  end
end
