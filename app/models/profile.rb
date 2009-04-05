# = Profile
#
# Profiles are ways of shaping a model's forms to different purposes depending on context.
#
# For example, the initial application will allow Kete site administrators to specify a set of rules
# (a profile) to specify what default values a new basket with that profile will have and what options
# a basket administrator may change.
#
# The core of profile is its "rules" which are actually stored via acts_as_configurable.
# profile.settings will store the rules.
#
# Profiles are mapped to its available_to_models, a comma separate list of relevant models,
# via the polymorphic association ProfileMapping.
class Profile < ActiveRecord::Base
  has_many :profile_mappings, :dependent => :destroy
  has_many :baskets, :through => :profile_mappings

  # holds our profile's rule set
  acts_as_configurable

  # to start, profiles are only available to Basket model
  # so we simply hard code it here, that way we don't need to do anything in our interface
  before_validation :set_available_to_models

  validates_presence_of :name, :available_to_models

  # most things are stored in virtual attributes via acts_as_configurable
  # adding convenience methods to make them appear as standard attributes

  # type handles a few special cases for convenience
  # if the site admin only wants the user to be able to change the name field for an item
  # then they can skip specifying the fields to be shown individually and choose "none"
  # if they want all fields to be shown (say for an "advanced" profile) they may choose "all"
  # otherwise they choose which fields specifically to show
  # each form within a profile may have a type
  def self.type_options
    [ ['None', 'none'],
      ['All', 'all'],
      ['Select Below', 'some']
    ]
  end

  after_save :set_rules

  def rules
    @rules ||= settings[:rules]
  end

  def rules=(value)
    @rules = value
  end

  def set_rules
    settings[:rules] = @rules unless @rules.blank?
  end

  # for each form that a basket may have, we need a corresponding accessor method
  # for active_scaffold
  Basket::FORMS_OPTIONS.each do |form_option|
    method_name = "rules[#{form_option[1]}]"
    code = Proc.new {
      return if settings[:rules].blank?
      settings[:rules][form_option[1]] unless settings[:rules][form_option[1]].blank?
    }

    define_method(method_name, &code)
  end

  private

  def set_available_to_models
    self.available_to_models = 'Basket'
  end
end
