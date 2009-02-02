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
      klass.send :include, GoogleMap::Mapper

      if klass.name == 'CommentsController'
        klass.send :before_filter, :is_authorized?, :only => [ :new, :create, :edit, :update ]
      else
        klass.send :permit, "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket",
                            :only => [ :new, :create, :edit, :update, :convert ]
      end

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

      private

      def build_relations_from_topic_type_extended_field_choices(extended_values=nil)
        extended_values = (extended_values || params[params[:controller].singularize][:extended_content_values])
        extended_values.each_pair do |key,value|
          if value.is_a?(Hash)
            build_relations_from_topic_type_extended_field_choices(value)
          else
            skip_or_add_relation_for(key, value)
          end
        end
      end

      def skip_or_add_relation_for(key, value)
        # Check before any further queries are made that the field looks like a topic type string
        return unless !value.blank? && value =~ /^.+ \((.+)\)$/

        # Check if this extended content belongs to an extended field that is a topic type field type
        # TODO: limit this to content_type or topic type
        # add condition to match key in query
        @extended_fields ||= ExtendedField.find_all_by_ftype('topic_type')
        extended_field = @extended_fields.select { |extended_field| qualified_name_for_field(extended_field) == key }
        return if extended_field.nil?

        # Now we know this content is valid and meant for a topic type extended field,
        # make a relation if one doesn't already exist
        topic_id = $1.split('/').last.split('-').first.to_i

        if topic_id && topic_id > 0
          relation_already_exists = ContentItemRelation.count(:conditions => { :topic_id => topic_id,
                                                                :related_item_id => current_item }) > 0
          unless relation_already_exists
            logger.debug("Add relation for #{value}, with id of #{topic_id}")
            topic = Topic.find(topic_id)
            ContentItemRelation.new_relation_to_topic(topic, current_item)
            prepare_and_save_to_zoom(topic)
            expire_related_caches_for(topic, 'topics')
          end
        end
      end

      # Taken from app/helpers/extended_fields_helper.rb
      # We only need this though, so should we include the whole set of helpers?
      def qualified_name_for_field(extended_field)
        extended_field.label.downcase.gsub(/\s/, "_")
      end

    end
  end
end
