# = Profile
#
# Profiles are ways of shaping a model's forms to different purposes depending on context.
#
# For example, the initial application will allow Kete site administrators to specify a set of rules
# (a profile) to specify what default values a new basket with that profile will have and what options
# a basket administrator may change.
#
# The core of profile is its "rules" which are actually stored via acts_as_configurable.
# profile.settings will store the rules. The rules are stored in the format of
#
# {
#   'form_name' => {
#     'rule_type' => 'some',
#     'allowed' => ['field1', 'field2'],
#     'values' => {
#       :field1 => 'default1',
#       :field2 => 'default2'
#     }
#   }
# }
#
# Profiles are mapped to its available_to_models, a comma separate list of relevant models,
# via the polymorphic association ProfileMapping.
#
# Profiles are added to a basket via the syntax
#
# basket.profiles << Profile.find(id)
#
class Profile < ActiveRecord::Base
  has_many :profile_mappings, dependent: :destroy
  has_many :baskets, through: :profile_mappings

  def setting(name, *args)
    ProfileSettings.get(name, *args)
  end

  # to start, profiles are only available to Basket model
  # so we simply hard code it here, that way we don't need to do anything in our interface
  before_validation :set_available_to_models

  validates_presence_of :name, :available_to_models

  # for each form type, the minimum it should have is a rule type.
  # If it's blank, things will fail
  validate :all_form_types_have_rule_type

  # most things are stored in virtual attributes via acts_as_configurable
  # adding convenience methods to make them appear as standard attributes

  # type handles a few special cases for convenience
  # if the site admin only wants the user to be able to change the name field for an item
  # then they can skip specifying the fields to be shown individually and choose "none"
  # if they want all fields to be shown (say for an "advanced" profile) they may choose "all"
  # otherwise they choose which fields specifically to show
  # each form within a profile may have a type
  def self.type_options
    [[I18n.t('profile_model.type_options.none'), 'none'],
     [I18n.t('profile_model.type_options.all'), 'all'],
     [I18n.t('profile_model.type_options.select_below'), 'some']]
  end

  # send @rules to profile.setting(:rules) for storage
  after_save :set_rules

  # return the rules details for the profile
  # if raw is false, it'll return a human readable version of the rules
  # (displayed on the active scaffold pages)
  # if raw is true, it'll return the hash we stored which can be
  # used on the forms for hiding/showing fields and setting values
  def rules(raw = false)
    return unless setting(:rules)

    return setting(:rules) if raw

    data = Array.new
    setting(:rules).each do |k, v|
      value = "#{k.humanize}: "
      value += if v['rule_type'] == 'all'
                 I18n.t('profile_model.rules.all')
               elsif v['rule_type'] == 'none'
                 I18n.t('profile_model.rules.none')
               elsif v['rule_type'] == 'some' && v['allowed']
                 v['allowed'].collect { |a| a.humanize }.join(', ') + '.'
               else
                 I18n.t('profile_model.rules.none')
      end
      data << value
    end
    data.join(' ')
  end

  # setter method used by Rails for virtual attributes
  # (attributes not in the profile model)
  def rules=(value)
    @rules = value
  end

  # an after_save callback method that saves the rules to settings
  def set_rules
    set_setting(:rules, @rules) unless @rules.blank?
  end

  # active scaffold uses this method to determine
  # what the user can do with the record
  def authorized_for?(args = {})
    case args[:action].to_s
    when 'update'
      false
    when 'destroy'
      profile_mappings.blank? ? true : false
    else
      true
    end
  end

  # active scaffold uses this method to determine
  # what the user can do with the record
  def authorized_for_update?
    false
  end

  # active scaffold uses this method to determine
  # what the user can do with the record
  def authorized_for_destroy?
    profile_mappings.blank? ? true : false
  end

  private

  # we need to make sure that rules and a rule_type for
  # each form type are set else things may break later on
  def all_form_types_have_rule_type
    if @rules
      missing_rule_types = Array.new
      @rules.each do |k, v|
        missing_rule_types << k.humanize if v['rule_type'].blank?
      end
      unless missing_rule_types.blank?
        errors.add_to_base(I18n.t('profile_model.all_form_types_have_rule_type.missing_rules_types', missing: missing_rule_types.join(', ')))
      end
    else
      errors.add_to_base(I18n.t('profile_model.all_form_types_have_rule_type.no_rules_submitted'))
    end
  end

  # we only use this for baskets at the moment,
  # but we may use it elsewhere later on
  def set_available_to_models
    self.available_to_models = 'Basket'
  end
end
