require 'nokogiri'

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

      unless klass.name == 'TopicsController'
        # used to determined appropriate extended fields for the model you are operating on
        klass.send :before_filter, :load_content_type,
                                   :only => [:show, :new, :create, :edit, :update]
      end

      ### TinyMCE WYSIWYG editor stuff
      klass.send :uses_tiny_mce, :only => VALID_TINYMCE_ACTIONS
      ### end TinyMCE WYSIWYG editor stuff

      klass.send :helper, :privacy_controls

      def load_content_type
        @content_type = ContentType.find_by_class_name(zoom_class_from_controller(params[:controller]))
      end

      private

      # By default, only site admins are allowed to not sanitize content, however if a user wants to edit an item
      # with insecure content, we should let them change stuff around it, and to do that, if the current elements
      # is an exact match with the submitted elements, then we can set do_not_sanitize to true here. A non site admin
      # still can't choose to no sanotize content though (so any new elements must be added by a site admin)
      def ensure_no_new_insecure_elements_in(item_type)
        return true if @site_admin && params[item_type.to_sym][:do_not_sanitize] == '1'

        @item = eval("@#{item_type}")

        old_doc = Nokogiri.HTML(@item.description) unless @item.description.blank?
        existing_elements = Array.new
        new_doc = Nokogiri::HTML(params[item_type.to_sym][:description]) unless params[item_type.to_sym][:description].blank?
        current_elements = Array.new

        INSECURE_EXTENDED_VALID_ELEMENTS.each do |field_key|
          old_doc.search("//#{field_key.to_s}").each { |element| existing_elements << element.to_s.strip } unless @item.description.blank?
          new_doc.search("//#{field_key.to_s}").each { |element| current_elements << element.to_s.strip } unless params[item_type.to_sym][:description].blank?
        end

        params[item_type.to_sym][:do_not_sanitize] = true
        new_elements = Array.new
        current_elements.each do |element|
          if existing_elements.include?(element)
            # delete it as we go so we can't use the same one again later
            existing_elements.delete_at(existing_elements.index(element))
          else
            new_elements << element
            params[item_type.to_sym][:do_not_sanitize] = false
          end
        end

        if new_elements.size > 0
          if @site_admin
            @item.errors.add('Description', I18n.t('extended_content_controller_lib.ensure_no_new_insecure_elements_in.contains_new_elements_admin',
                                                   :count => new_elements.size))
            false
          else
            @item.errors.add('Description', I18n.t('extended_content_controller_lib.ensure_no_new_insecure_elements_in.contains_new_elements',
                                                   :count => new_elements.size))
            logger.warn "WARNING: #{current_user.login} tried to add the following new elements to #{item_type} #{@item.id}"
            new_elements.each { |element| logger.warn element.inspect }
            false
          end
        else
          true
        end
      end

      def build_relations_from_topic_type_extended_field_choices(extended_values=nil)
        params_key = zoom_class_params_key_from_controller(params[:controller])
        extended_values ||= params[params_key][:extended_content_values] if !params[params_key].blank? && !params[params_key][:extended_content_values].blank?

        # no extended_values, nothing to do
        return if extended_values.blank?

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
        return unless value.present? && value =~ /^.+ \(\w+:\/\/(.+)\)$/ && $1

        # Check if this extended content belongs to an extended field that is a topic type field type
        # TODO: limit this to content_type or topic type
        # add condition to match key in query
        @extended_fields ||= ExtendedField.find_all_by_ftype('topic_type')
        extended_field = @extended_fields.find { |ef| qualified_name_for_field(ef) == key }
        return if extended_field.blank?

        # Now we know this content is valid and meant for a topic type extended field,
        # make a relation if one doesn't already exist
        topic_id = $1.dup.split('/').last.to_i

        if topic_id && topic_id > 0
          topic = Topic.find_by_id(topic_id)
          if topic # incase the id is wrong, don't cause any errors
            relation_already_exists = ContentItemRelation.count(:conditions => { :topic_id => topic.id,
                                                                :related_item_id => current_item }) > 0
            unless relation_already_exists
              logger.debug("Add relation for #{value}, with id of #{topic.id}")
              ContentItemRelation.new_relation_to_topic(topic, current_item)
              topic.prepare_and_save_to_zoom
              expire_related_caches_for(topic, 'topics')
            end
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
