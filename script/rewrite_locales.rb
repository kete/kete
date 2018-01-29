#!/usr/bin/env ruby
# The config/locales/en.yml file has multiple nested includes. Kill it!
# ex:
#    en.base.thing: thing
#    en.base.lots_o_things: lots of {{t.base.thing.pluralize}}
#    ...

require 'yaml'
require 'active_support/inflector'

def main
  yaml_text = File.read('../config/locales/en.yml')

  normaliser = LocaleFileNormaliser.new(yaml_text)
  normaliser.parse!

  File.open('./out.yml', 'w+') do |f|
    f.write(normaliser.results)
  end
end

class LocaleFileNormaliser
  def initialize(yaml_text)
    @yaml_text = yaml_text
    @tree = YAML.load(yaml_text)
  end

  def setup_gsub_pairs
    @gsub_pairs = []
  end

  def process_gsub_pairs
    @gsub_pairs.each do |pair|
      @yaml_text.gsub!("{{t.#{pair[0]}}}", pair[1])
      # i.e. @yaml_text.gsub("{{t.base.can_be}}", tree['base']['can_be'])

      process_gsub_function(pair)
      process_gsub_pluralize_capitalize(pair)
      process_gsub_capitalize_pluralize(pair)
    end
  end

  def process_gsub_function(pair)
    ['pluralize', 'capitalize', 'downcase', 'upcase'].each do |function|
      search_key = "{{t.#{pair[0]}.#{function}}}"
      replace_value = pair[1].send(function).to_s
      # puts search_key +"  --  "+ replace_value

      @yaml_text.gsub!(search_key, replace_value)
      # i.e. @yaml_text.gsub("{{t.base.can_be.capitalize}}", tree['base']['can_be'].capitalize)
    end
  end

  def process_gsub_pluralize_capitalize(pair)
    search_key = "{{t.#{pair[0]}.pluralize.capitalize}}"
    replace_value = pair[1].pluralize.capitalize.to_s
    @yaml_text.gsub!(search_key, replace_value)
  end

  def process_gsub_capitalize_pluralize(pair)
    search_key = "{{t.#{pair[0]}.capitalize.pluralize}}"
    replace_value = pair[1].capitalize.pluralize.to_s
    @yaml_text.gsub!(search_key, replace_value)
  end

  def parse!(number = 3)
    number.times do
      setup_gsub_pairs
      walk_base_en_node(@tree)
      process_gsub_pairs
    end
  end

  def results
    @yaml_text
  end

  def walk_base_en_node(tree)
    # Throw away 'en' form the keys_array
    walk_hash(tree['en'], [])
  end

  def walk_hash(hash, keys_array)
    hash.each_pair do |key, value|
      new_hash_stack = keys_array.clone << key
      process_by_type(value, new_hash_stack)
    end
  end

  def walk_array(array, keys_array)
    array.each do |value|
      process_by_type(value, keys_array)
    end
  end

  def process_by_type(value, keys_array)
    if value.class == String
      save_string_to_gsub_pair(value, keys_array)

    elsif value.class == Array
      walk_array(value,  keys_array)

    elsif value.class == Hash
      walk_hash(value, keys_array)
    end
  end

  def save_string_to_gsub_pair(value, keys_array)
    search_key = keys_array.join('.')
    replacement_value = value

    @gsub_pairs << [search_key, replacement_value]
  end
end

main
