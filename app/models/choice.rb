# frozen_string_literal: true

class Choice < ActiveRecord::Base
  ROOT = Choice.find(1) rescue nil

  # find a choice based on params[:limit_to_choice]
  def self.from_id_or_value(id_or_label)
    find_by_value(id_or_label) || find_by_id(id_or_label)
  end

  # Ensure any newly created choices become a child of root.
  # Without this, they will need be found when doing lookups against all choices, since we are depending entirely on
  # better_nested_set to provide choice hierachy and listings.
  after_create :make_child_of_root

  # After updating, check to see if we should change the parent choice.
  after_update :change_parent

  # Before saving, make sure the value is set with something
  before_validation :construct_value_if_not_set

  # don't orphan children
  # reassign them as children of their grandparent
  # if you destroy their parent
  before_destroy :reassign_children_to_grandparent

  # Associations (polymorphic has_many :through)
  has_many :choice_mappings

  has_many :extended_fields, through: :choice_mappings,
                             source: :field, source_type: 'ExtendedField'

  # Use better nested set for STI
  acts_as_nested_set

  # Label and value are compulsory
  validates_presence_of :label
  validates_presence_of :value

  # Label and value must be unique (for lookup reasons)
  validates_uniqueness_of :label, message: lambda { I18n.t('choice_model.must_be_unique') }
  validates_uniqueness_of :value, message: lambda { I18n.t('choice_model.must_be_unique') }

  # class methods
  class << self
    def find_top_level
      ROOT.children
    end

    # Find whether a set of choices (through an association) have a bunch of sub-choices we need to deal with.
    def have_subchoices?
      find_top_level.any? do |choice|
        choice.children_count > 0
      end
    end

    # this may have a nil value passed in for label
    # and handles a few cases
    # that where label == value in choice object and nil has been passed in for label
    # extended_field.ftype autocompletion:
    # where label != value in choice object,
    # but value passed in actually corresponds to label
    # where label != value in choice object,
    # but we have a match against choice.value
    def matching(label, value)
      value = value[:value] if value.is_a?(Hash)
      label = value[:label] if value.is_a?(Hash) && label.nil?

      label = label ? label : value
      find_by_label(label) || find_by_value(value)
    end
  end

  def parent=(parent_choice_id)
    unless new_record?
      @new_parent = parent_choice_id.blank? ? ROOT : parent_choice_id
    end
  end

  # An alias so we dont have to run checks between ExtendedFields and choices
  alias choices children

  def children=(array_of_choice_ids)
    # Remove existing children
    children.each do |choice|
      choice.move_to_child_of(ROOT)
    end

    # Add new children
    unless array_of_choice_ids.blank?
      array_of_choice_ids.map { |id| Choice.find(id) }.each do |choice|
        choice.move_to_child_of(id)
      end
    end

    # Return true to stop saving from being aborted.
    true
  end

  # Ensure things make sense to end users
  def to_s
    label
  end

  # Ensure things make sense to end users
  def label
    self == ROOT ? I18n.t('choice_model.top_level') : read_attribute(:label)
  end

  # Find whether the choice has been mapped to something
  def assigned?
    choice_mappings.size > 0
  end

  private

  def make_child_of_root
    move_to_child_of(ROOT) unless ROOT.nil?
  end

  def change_parent
    move_to_child_of(@new_parent) if @new_parent
  end

  # if only one of the attributes is set
  # set both attributes to that value
  # if both blank, fails validation, of course
  def construct_value_if_not_set
    self.label = value if label.blank?
    self.value = label if value.blank?
  end

  def reassign_children_to_grandparent
    grandparent = parent
    # Remove existing children
    children.each do |choice|
      choice.move_to_child_of(grandparent)
    end
  end

  # turn pretty urls on or off here
  include FriendlyUrls
  alias to_param format_for_friendly_unicode_urls
end
