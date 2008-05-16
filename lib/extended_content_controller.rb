module ExtendedContentController
  unless included_modules.include? ExtendedContentController
    def self.included(klass)
      # stuff related to flagging and moderation
      klass.send :include, FlaggingController

      # used to determined appropriate extended fields for the model
      # you are operating on
      klass.send :before_filter, :load_content_type,
      :only => [:new, :show, :edit, :create, :update]

      klass.send :before_filter, :is_authorized?, 
      :only => [ :new, :create, :edit, :update, :convert]

      klass.send :permit, "site_admin or moderator of :current_basket or admin of :current_basket",
      :only =>  [ :destroy, :restore, :reject, :make_theme ]

      # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
      klass.send :verify, :method => :post, :only => [ :destroy, :create, :update ],
      :redirect_to => { :action => :list }

      # override the site wide protect_from_forgery to exclude
      # things that you must be logged in to do anyway or at least a moderator
      klass.send :protect_from_forgery, :secret => KETE_SECRET, :except => ['new', 'destroy']

      ### TinyMCE WYSIWYG editor stuff
      klass.send :uses_tiny_mce, :options => { :theme => 'advanced',
        :browsers => %w{ msie gecko safaris},
        :mode => "textareas",
        :convert_urls => false,
        :content_css => "/stylesheets/base.css",
        :remove_script_host => true,
        :theme_advanced_toolbar_location => "top",
        :theme_advanced_toolbar_align => "left",
        :theme_advanced_resizing => true,
        :theme_advanced_resize_horizontal => false,
        :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo code},
        :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect pastetext pasteword selectall },
        :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
        :editor_selector => 'mceEditor',
        :paste_create_paragraphs => true,
        :paste_create_linebreaks => true,
        :paste_use_dialog => true,
        :paste_auto_cleanup_on_paste => true,
        :paste_convert_middot_lists => false,
        :paste_unindented_list_class => "unindentedList",
        :paste_convert_headers_to_strong => true,
        :paste_insert_word_content_callback => "convertWord",
        :plugins => %w{ contextmenu paste table fullscreen} },
      :only => [:new, :pick, :create, :edit, :update, :pick_topic_type]
      ### end TinyMCE WYSIWYG editor stuff

      def load_content_type
        @content_type = ContentType.find_by_class_name(zoom_class_from_controller(params[:controller]))
      end

      def is_authorized?
        permit? "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket"
      end
      
    end
        
  end
end
