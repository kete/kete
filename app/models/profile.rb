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

  def rules(raw=false)
    data = Array.new
    return unless self.settings[:rules]
    return self.settings[:rules] if raw
    self.settings[:rules].each do |k,v|
      value = "#{k.humanize}: "
      value += if v['rule_type'] == 'all'
        "All."
      elsif v['rule_type'] == 'none'
        "None."
      elsif v['rule_type'] == 'some' && v['allowed']
        v['allowed'].collect { |a| a.humanize }.join(', ') + '.'
      else
        "None."
      end
      data << value
    end
    data.join(' ')
  end

  def rules=(value)
    @rules = value
  end

  def set_rules
    self.settings[:rules] = @rules unless @rules.blank?
  end

  def authorized_for?(args={})
    case args[:action].to_s
    when 'update'
      false
    when 'destroy'
      profile_mappings.blank? ? true : false
    else
      true
    end
  end

  def authorized_for_update?
    false
  end

  def authorized_for_destroy?
    profile_mappings.blank? ? true : false
  end

  private

  def set_available_to_models
    self.available_to_models = 'Basket'
  end
end
