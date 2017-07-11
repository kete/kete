require 'nokogiri'

module ExtendedContentController
  unless included_modules.include? ExtendedContentController
    def self.included(klass)
      # stuff related to flagging and moderation
      klass.send :include, FlaggingController

      # Kieran Pilkington, 2008/10/23
      # Autocomplete methods for tag adder on item pages
      klass.send :include, TaggingController

      klass.send :include, AnonymousFinishedAfterFilter

      if klass.name == 'CommentsController'
        klass.send :before_filter, :is_authorized?, only: [:new, :create, :edit, :update]
      else
        klass.send :permit, 'site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket',
                   only: [:new, :create, :edit, :update, :convert]
      end

      klass.send :permit, 'site_admin or moderator of :current_basket or admin of :current_basket',
                 only: [:destroy, :restore, :reject, :make_theme]

      # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
      # klass.send :verify, :method => :post,
      #                     :only => [ :destroy, :create, :update ],
      #                     :redirect_to => { :action => :list }

      unless klass.name == 'TopicsController'
        # used to determined appropriate extended fields for the model you are operating on
        klass.send :before_filter, :load_content_type,
                   only: [:show, :new, :create, :edit, :update]
      end

      klass.send :helper, :privacy_controls

      def load_content_type
        @content_type = ContentType.find_by_class_name(zoom_class_from_controller(params[:controller]))
      end

      private

      def build_relations_from_topic_type_extended_field_choices(extended_values = nil)
        params_key = zoom_class_params_key_from_controller(params[:controller])
        extended_values ||= params[params_key][:extended_content_values] if !params[params_key].blank? && !params[params_key][:extended_content_values].blank?

        # no extended_values, nothing to do
        return if extended_values.blank?

        # extended_values can be hash of hashes
        # e.g. {"relatives"=>{"1"=>"Joe Bob (http://kete/end/topics/show/16-joe-bob)"}, "place_of_birth"=>""}
        # where field keys are the outermost keys and there may be non-topic_type field values
        # or on second recursive call if value is a hash
        # it might include position as key
        # e.g. {"1"=>"Joe Bob (http://kete/end/topics/show/16-joe-bob)"}
        # in which case we need to replace position with qualified field label for params
        # lastly value is just a string
        # e.g. "Joe Bob (http://kete/end/topics/show/16-joe-bob)"
        @extended_fields ||= ExtendedField.find_all_by_ftype('topic_type')
        extended_values.each_pair do |key, value|
          if value.is_a?(Hash)
            # check for multiple with nested position keys
            extended_field = @extended_fields.find { |ef| qualified_name_for_field(ef) == key }
            if extended_field.present?
              field_key = key
              value.values.each do |value|
                skip_or_add_relation_for(field_key, value)
              end
            else
              build_relations_from_topic_type_extended_field_choices(value)
            end
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
        extended_field = @extended_fields.find { |ef| qualified_name_for_field(ef) == key }
        return if extended_field.blank?

        # Now we know this content is valid and meant for a topic type extended field,
        # make a relation if one doesn't already exist
        topic_id = $1.dup.split('/').last.to_i

        if topic_id && topic_id > 0
          topic = Topic.find_by_id(topic_id)
          if topic # incase the id is wrong, don't cause any errors
            relation_already_exists = ContentItemRelation.find_relation_to_topic(topic.id, current_item).present?

            unless relation_already_exists
              logger.debug("Add relation for #{value}, with id of #{topic.id}")
              ContentItemRelation.new_relation_to_topic(topic, current_item)
              # use async backgroundrb worker rather than slowing down response to request to wait for related topic rebuild
              # topic.prepare_and_save_to_zoom
              update_search_record_for(topic)
            end
          end
        end
      end

      # Taken from app/helpers/extended_fields_helper.rb
      # We only need this though, so should we include the whole set of helpers?
      def qualified_name_for_field(extended_field)
        extended_field.label.downcase.gsub(/\s/, '_')
      end
    end
  end
end
