# Used in conjunction with ZoomDbWrapper
# to return OAI-PMH Repository records
# from a ZoomDb
# see acts_as_zoom plugin
# define static sets based on straight pqf queries
# example: pqf_query_stub = "@attr 1=12" and pqf_search_for = ""
# or dynamic sets based on pqf query + Ruby that returns enum string values
# and therefore can define multiple set
# example: pqf_query_stub = "@attr 1=12" and pqf_search_for = "ZOOM_CLASSES"
# will create sets for all ZOOM_CLASSES, i.e. a set each for Topic, StillImage, etc.
# example: pqf_query_stub = "@attr 1=12" and pqf_search_for = "Basket.find(:all, :select => 'name').collect { |x| x.name }"
# will create sets for all baskets, i.e. a set each for basket
# IMPORTANT NOTE -- because we evaluate user input for the pqf_search_for
# there is a potential security risk
# only authorized users in the tech admin role should be allowed to set pqf_search_for
class OaiPmhRepositorySet < ActiveRecord::Base
  validates_presence_of :name, :set_spec, :match_code, :value
  validates_uniqueness_of :name, :set_spec, case_sensitive: false

  # don't allow special characters in name or set_spec that will break our xml
  validates_format_of :name, :set_spec,
  with: /^[^\'\":<>\&,\/\\\?]*$/,
  message: lambda { I18n.t('oai_pmh_repository_set_model.invalid_chars', invalid_chars: "\', \\, /, &, \", ?, <, and >") }

  class GeneratedSet
    attr_accessor :name, :description, :spec

    def initialize(options = { })
      @name = options[:name]
      @description = options[:description]
      @spec = options[:spec]
    end
  end

  def create_set(options = { })
    this_set = { name: options[:name] || name,
      description: options[:description] || description || nil,
      spec: options[:set_spec] || set_spec
    }
    set = GeneratedSet.new(this_set)
  end

  def generated_sets
    sets = Array.new
    unless dynamic?
      sets << create_set
    else
      sets += generate_dynamic_sets
    end
  end

  def add_this_set_to(xml_builder, options = { })
    this_name = options[:name] || name
    this_description = options[:description] || description || nil
    this_set_spec = options[:set_spec] || set_spec

    xml = xml_builder
    xml.set do
      xml.setName(this_name)
      xml.setDescription(this_description) unless this_description.blank?
      xml.setSpec(this_set_spec)
    end
    xml.target!
  end

  # we may simply have a static set
  # we just return xml for
  # but we may have a dynamic set
  # which we treat as specification for generating
  # multiple sets
  def append_generated_sets_to(xml_builder)
    unless dynamic?
      add_this_set_to(xml_builder)
    else
      dynamic_output_to(xml_builder)
    end
  end

  # IMPORTANT NOTE - security warning
  # this evaluates user submitted code
  # should only be open to tech admin
  def matching_specs(item)
    values = Array.new
    # dynamic value should return an array of names
    # static should return a string
    if dynamic?
      values = eval(value)
    else
      values << value
    end

    specs = Array.new
    values.each do |for_value|
      specs << full_spec(for_value) if test_match_with(item, for_value)
    end
    specs
  end

  def test_match_with(item, for_value)
    code = 'item.' + match_code
    if ['true', 'false'].include?(for_value)
      for_value = eval(for_value)
    end
    for_value == eval(code)
  end

  def full_spec(for_value)
    return set_spec unless dynamic?
    set_spec + '--' + for_value.gsub(':', '_colon_').gsub('_', '-underscore-').gsub(' ', '_')
  end

  private

  def generate_dynamic_sets
    generated = Array.new
    options_for_generated_sets.each { |options_hash| generated << create_set(options_hash) }
    generated
  end

  def dynamic_output_to(xml_builder)
    # an array of hashes
    options_for_generated_sets.each { |options_hash| add_this_set_to(xml_builder, options_hash) }
  end

  def options_for_generated_sets
    @options_for_generated_sets = Array.new
    return @options_for_generated_sets unless dynamic?

    # because this oai_pmh_repository_set is dynamic
    # expect an object class that inherits from Enum
    # to be returned from pqf_search_for
    # but that should be a collecition strings (what we search for)
    # append dynamic stuff to base set attributes
    eval(value).each do |string|
      options = { name: "#{name} - #{string}",
        description: string + ' - ' + description,
        set_spec: full_spec(string)}

      @options_for_generated_sets << options
    end

    @options_for_generated_sets
  end
end

