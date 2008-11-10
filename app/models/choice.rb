class Choice < ActiveRecord::Base
  
  # Ensure any newly created choices become a child of root.
  # Without this, they will need be found when doing lookups against all choices, since we are depending entirely on
  # better_nested_set to provide choice hierachy and listings.
  after_create :make_child_of_root
  
  def make_child_of_root
    move_to_child_of(Choice.root)
  end
  
  private :make_child_of_root
  
  # Associations (polymorphic has_many :through)
  has_many :choice_mappings
  
  has_many :extended_fields, :through => :choice_mappings, 
    :source => :field, :source_type => 'ExtendedField'
    
  # Use better nested set for STI
  acts_as_nested_set
  
  # Label is compulsory
  validates_presence_of :label
  
  # Label and value must be unique (for lookup reasons)
  validates_uniqueness_of :label, :message => "must be unique"
  validates_uniqueness_of :value, :message => "must be unique"

  # If no value is given, use the label as the value
  # I expect this will be a pretty common use-case
  def value
    read_attribute(:value).blank? ? label : read_attribute(:value)
  end
  
  def parent=(parent_choice_id)
    if new_record?
      # Do nothing..
    elsif parent_choice_id.blank? 
      move_to_left_of(roots.last)
    else
      move_to_child_of(parent_choice_id)
    end
  end
  
  def children=(array_of_choice_ids)

    # Remove existing children
    children.each do |choice|
      choice.move_to_child_of(root)
    end
    
    # Add new children
    unless array_of_choice_ids.blank?
      array_of_choice_ids.map { |id| Choice.find(id) }.each do |choice|
        choice.move_to_child_of(self)
      end
    end
  end
  
  # Ensure things make sense to end users
  def to_s
    label
  end
  
  # Ensure things make sense to end users
  def label
    read_attribute(:label) == "ROOT" ? "(Top level)" : read_attribute(:label)
  end
  
  class << self
    
    def options_for_select
      find(:all).collect { |c| [c.label, c.value] }
    end
    
    def find_top_level
      root.children
    end
        
  end
  
end