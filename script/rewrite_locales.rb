#!/usr/bin/env ruby

require 'yaml'
require 'pry'

def traverse(hash, key_stem = "")
  puts "entering traverse. key_stem: #{key_stem}"
  hash.each_pair do |key, value|

    if value.class == String
      value = resolve(value)

    elsif value.class == Array 
      value = value.map do |element|
        resolve(value)
      end

    elsif value.class == Hash
      traverse(value, "#{key_stem}['#{key}']")
    end
  end
end

def resolve_key
end

def resolve(value)
  return value unless value.class == String

  puts "++++++++"
  puts "old: " + value

  new_value = ""

  value.scan(/\{\{(.+?)\}\}/) do |matches|
    str_key = matches.first
    next unless str_key =~ /^t\./ # ignore any match that does not start with t. as it probably a variable from the view

    # terrible hacks
    str_key.sub!(/^t\./, 'en.')       # convert t. to en.
    str_key.sub!(/\.pluralize$/, '')  # remove trailing .pluralize
    str_key.sub!(/\.pluralize\.capitalize$/, '')  # remove trailing .pluralize
    str_key.sub!(/\.capitalize$/, '')  # remove trailing .pluralize
    str_key.sub!(/\.downcase$/, '')  # remove trailing .pluralize
    str_key.sub!(/\.upcase$/, '')  # remove trailing .pluralize

    keys = str_key.split('.')
    new_value = keys.inject($locales, :fetch)
  end

  puts "new: " + new_value
  puts "---------"

  new_value
end

$locales = YAML.load_file('../config/locales/en.yml')
traverse($locales)

binding.pry
File.open('./out.yml', 'w+') do |f|
  f.write($locales.to_yaml)
end

