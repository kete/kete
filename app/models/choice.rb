class Choice < ActiveRecord::Base
  
  ROOT = Choice.find(1) rescue nil
  
  # Ensure any newly created choices become a child of root.
  # Without this, they will need be found when doing lookups against all choices, since we are depending entirely on
  # better_nested_set to provide choice hierachy and listings.
  after_create :make_child_of_root
  
  def make_child_of_root
    move_to_child_of(ROOT) unless ROOT.nil?
  end
  
  private :make_child_of_root
  
  # After updating, check to see if we should change the parent choice.
  after_update :change_parent
  
  def change_parent
    move_to_child_of(@new_parent) if @new_parent
  end
  
  private :change_parent
  
  # Before saving, make sure the value is set with something
  before_validation :construct_value_if_not_set
  
  def construct_value_if_not_set
    self.value = self.label if value.blank?
  end
  
  private :construct_value_if_not_set
  
  # Associations (polymorphic has_many :through)
  has_many :choice_mappings
  
  has_many :extended_fields, :through => :choice_mappings, 
    :source => :field, :source_type => 'ExtendedField'
    
  # Use better nested set for STI
  acts_as_nested_set
  
  # Label and value are compulsory
  validates_presence_of :label
  validates_presence_of :value
  
  # Label and value must be unique (for lookup reasons)
  validates_uniqueness_of :label, :message => "must be unique"
  validates_uniqueness_of :value, :message => "must be unique"

  def parent=(parent_choice_id)
    unless new_record? 
      @new_parent = parent_choice_id.blank? ? ROOT : parent_choice_id
    end
  end
  
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
    self == ROOT ? "(Top level)" : read_attribute(:label)
  end
  
  # Find whether the choice has been mapped to something
  def assigned?
    choice_mappings.size > 0
  end
  
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
    
  end
  
end