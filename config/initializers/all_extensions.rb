# encoding: UTF-8
# frozen_string_literal: true

#
# CAUTION
#
# This intializer must be run before all others!!!
# (name it accordingly so it is sorted alphabetically before all others)
#

# Include extensions into Ruby components here

module ParamToObjEquiv
  # converts "true", "1", "false", "0" and "nil" into their appropriate boolean/NilClass values
  def param_to_obj_equiv
    case self
    when '1', 'true', true then true
    when '0', 'false', false then false
    when 'nil', nil then nil
    else self
    end
  end
end
[String, TrueClass, FalseClass, NilClass].each { |c| c.send(:include, ParamToObjEquiv) }

class String
  # Add a quick escape method to all string instances
  # (for xml displays)
  def escape
    require 'htmlentities'
    entities = HTMLEntities.new
    # decode special chars (like multi language chars)
    # escape xml special chars &, <, and >
    CGI::escapeHTML(entities.decode(self))
  end

  # In Rails 2.3, strip_tags and sanitize are not accessible in their short form outside of
  # helpers and view, so lets add a method on String that we can call in controllers/models/libs etc
  def strip_tags
    ActionController::Base.helpers.strip_tags(self)
  end

  def sanitize
    ActionController::Base.helpers.sanitize(self)
  end

  # Add a quick escpe for url and decode from url methods to string instances
  # (escapes anything that causes issues with route parsing, like forward slashes and periods)
  def escape_for_url
    URI.escape(self, /\W/)
  end

  def decode_from_url
    URI.decode(self)
  end
end

class Array
  # Pass in an attribute name that corresponds to a
  # column in the database, but without the _id
  # i.e.   basket_id     => :basket
  # i.e.   topic_type_id => :topic_type
  def collection_of_objects_and_counts_for(attr_name, ordered = false)
    attr_name_id = "#{attr_name}_id"

    if any? { |item| !item.respond_to?(attr_name_id) }
      error_msg = "Trying to get hash of #{attr_name.to_s.humanize} names and counts, "
      error_msg += "but Array contains an object that doesn't have that value."
      raise error_msg
    end

    name_and_counts = Hash.new

    attr_ids = collect { |item| item.send(attr_name_id) }
    attr_types = attr_name.to_s.classify.constantize.all(conditions: { id: attr_ids })
    attr_types.each do |attr_type|
      name_and_counts[attr_type] = select { |item| item.send(attr_name_id) == attr_type.id }.size
    end

    if ordered
      name_and_counts.sort_by do |attr_type, count|
        attr_type.respond_to?(:lft) ? attr_type.lft : attr_type.id
      end
    else
      name_and_counts
    end
  end
end

# Include extensions into Rails components here

module ActiveRecord
  class Base
    # Kieran Pilkington, 2009-07-09
    # Adding a class_as_key method which returns a key for a model as used in params
    def class_as_key
      # self. is necessary in this case because class is a reserved word
      self.class.name.tableize.singularize.to_sym
    end
  end
end

module I18n
  # EOIN: I have servere doubts about the usefulness of this extension. It is
  # called in a number of places in the code but it's not clear what benefit it
  # gives us.
  def self.available_locales_with_labels
    @@available_locales_with_labels ||=
      begin
           locales_file = File.join(Rails.root.to_s, 'config', 'locales', 'en.yml')
           return Hash.new unless File.exist?(locales_file)
           YAML.load(IO.read(locales_file)).stringify_keys
         end
  end

  module Backend
    class Simple
      PluralizeValues = {
        mi: { prefix: 'ngā ' },
        zh: { prefix: '', suffix: '' }
      }
        SingularizeValues = {
          mi: { prefix: 'te ' },
          zh: { prefix: '', suffix: '' }
        }

      protected

        # Kieran Pilkington, 2009-07-09
        # Adding very simple translation fallback support to I18n module
        # Calls the original lookup method. If the value is empty, call it again with default locale
        alias lookup_orig lookup
        def lookup(locale, key, scope = [], options = {})
          return unless key
          entry = lookup_orig(locale, key, scope, options)
          if (entry.nil? || (entry.is_a?(String) && entry.empty?)) && I18n.default_locale
            entry = lookup_orig(I18n.default_locale, key, scope, options)
          end
          entry
        end

        # Kieran Pilkington, 2009-07-09
        # Allows us to use keys in translations "Change {{t.base.password}}"
        # Replace all the {{t.}} values before handing the resulting string
        # to the original interpolate method
        # alias :interpolate_orig :interpolate
        # def interpolate(locale, string, values = {})
        #   match = /(\\\\)?\{\{([^\}]+)\}\}/
        #   return string unless string.is_a?(String)

        #   string = string.gsub(match) do
        #     escaped, pattern, key = $1, $2, $2.to_sym

        #     if !escaped && pattern.match(/^t\./)
        #       # a list of acceptable string methods to call
        #       string_methods = ['downcase', 'upcase', 'capitalize', 'singularize', 'pluralize']

        #       # remove string methods and t. from the key, then turn to a symbol
        #       # and run it through the translate method
        #       key = pattern.gsub(/^t\./, '').gsub(/\.(#{string_methods.join('|')})/, '').to_sym
        #       value = translate(locale, key, values)

        #       # for each string method in the patern, in order, execute that
        #       # method on the returned value, and overwrite value
        #       pattern.gsub(/\.(#{string_methods.join('|')})/) do
        #         if $1 == 'pluralize'
        #           value = pluralize_with_locale(locale, value)
        #         elsif $1 == 'singularize'
        #           value = singularize_with_locale(locale, value)
        #         else
        #           value = value.respond_to?($1) ? value.send($1) : value
        #         end
        #       end

        #       # return the translated, and string method executed value
        #       value
        #     else
        #       "{{#{pattern}}}"
        #     end
        #   end

        #   interpolate_orig(locale, string, values)
        # end

        def pluralize_with_locale(locale, string)
          if PluralizeValues[locale.to_sym]
            string = strip_prefix_and_suffix(locale, string)
            PluralizeValues[locale.to_sym][:prefix].to_s + string + PluralizeValues[locale.to_sym][:suffix].to_s
          else
            string.pluralize
          end
        end

        def singularize_with_locale(locale, string)
          if SingularizeValues[locale.to_sym]
            string = strip_prefix_and_suffix(locale, string)
            SingularizeValues[locale.to_sym][:prefix].to_s + string + SingularizeValues[locale.to_sym][:suffix].to_s
          else
            string.singularize
          end
        end

        def strip_prefix_and_suffix(locale, string)
          # strip any prefixes for this locale
          string.gsub!(/^#{PluralizeValues[locale.to_sym][:prefix]}/, '') unless PluralizeValues[locale.to_sym][:prefix].blank?
          string.gsub!(/^#{SingularizeValues[locale.to_sym][:prefix]}/, '') unless SingularizeValues[locale.to_sym][:prefix].blank?

          # strip any suffixes for this locale
          string.gsub!(/#{PluralizeValues[locale.to_sym][:suffix]}$/, '') unless PluralizeValues[locale.to_sym][:suffix].blank?
          string.gsub!(/#{SingularizeValues[locale.to_sym][:suffix]}$/, '') unless SingularizeValues[locale.to_sym][:suffix].blank?

          string
        end
    end
  end
end

# Include extensions into Kete dependancies here

# Kieran Pilkington, 2009-10-19
# A quick way to strip new lines, remove <?xml
# and <root> tags, and remove excess whitespace
module Nokogiri
  module XML
    class Builder
      # When importing, if any fields contain a reserved
      # name (like 'id' or 'parent') the importer will fail.
      # To avoid that, we add a quick method on the builder
      # to escape it by appending an underscore, then sending
      # it to the builder, which Nokogiri sees and removes
      # before generating the XML.
      # At the same time, make sure that the name is a valid
      # XML name and escape common patterns (spaces to
      # underscores) to prevent import errors
      def safe_send(*args, &block)
        args[0] = args[0].to_s.gsub(/\W/, '_').gsub(/(^_*|_*$)/, '') + '_'
        send(*args, &block)
      end

      def to_stripped_xml
        @doc.to_xml.gsub(/(^\s*|\s*$)/, '').gsub(/>(\n*|\s*)</, '><').gsub('<?xml version="1.0"?>', '').gsub(/(<root\/?>|<\/root>)/, '')
      end
    end
  end
end
