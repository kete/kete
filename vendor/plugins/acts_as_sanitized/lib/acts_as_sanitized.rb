module AlexPayne
  module Acts #:nodoc: all
    module Sanitized
      def self.included(base)
        # Walter McGinnis, 2008-01-09
        # update to work with Rails 2.0
        base.extend(ActionView::Helpers::SanitizeHelper::ClassMethods)

        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_sanitized(options = {})
          before_save :sanitize_fields

          write_inheritable_attribute(:acts_as_sanitized_options, {
            :fields => options[:fields],
            :strip_tags => options[:strip_tags]
          })

          class_inheritable_reader :acts_as_sanitized_options

          # discover sanitizable (string and text) fields if none specified
          unless acts_as_sanitized_options[:fields]
            acts_as_sanitized_options[:fields] = []

            self.columns.each do |column|
              if column.type == :string || column.type == :text
                acts_as_sanitized_options[:fields].push(column.name)
              end
            end
          end

          include AlexPayne::Acts::Sanitized::InstanceMethods
        end
      end

      module InstanceMethods
        # Walter McGinnis, 2008-01-09
        # update to work with Rails 2.0
        include ActionView::Helpers::SanitizeHelper
        def sanitize_fields
          if acts_as_sanitized_options[:strip_tags] == true
            acts_as_sanitized_options[:fields].each do |field|
              strip_tags_field(field)
            end
          else
            # Walter McGinnis, 2008-01-09
            # allow for turning off sanitization on a record by record basis
            # for cases like a site admin adding a form
            # via virtual attribute on record
            do_not_sanitize = !self.do_not_sanitize.nil? && self.do_not_sanitize.to_s != 'false' && (self.do_not_sanitize.to_s == 'true' || self.do_not_sanitize.to_i == 1) ?  true : false
            unless do_not_sanitize
              acts_as_sanitized_options[:fields].each do |field|
                sanitize_field(field)
              end
            end
          end
        end

        def sanitize_field(field)
          content = self[field.to_sym]
          self[field.to_sym] = sanitize(content) unless content.nil?
        end

        def strip_tags_field(field)
          content = self[field.to_sym]
          self[field.to_sym] = strip_tags(content) unless content.nil?
        end
      end
    end
  end
end
