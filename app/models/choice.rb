class Choice < ActiveRecord::Base
  
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
      move_to_left_of(root.id)
    else
      move_to_child_of(parent_choice_id)
    end
  end
  
  def children=(array_of_choice_ids)
    array_of_choice_ids.each do |choice|
      choice.move_to_child_of(self)
    end
  end
  
  def to_s
    label
  end
  
  class << self
    
    def options_for_select
      find(:all).collect { |c| [c.label, c.value] }
    end
    
    def find_without_parent_in(array_of_parent_choices, options_for_find = {})
      default_options = { :conditions => 'parent_id IS NOT NULL' }
      candidates = find(:all, default_options.merge(options_for_find))
      
      candidates.reject { |c| array_of_parent_choices.member?(c) }
    end
    
    def find_top_level(options_for_find = {})
      default_options = { :conditions => 'parent_id IS NULL' }
      find(:all, default_options.merge(options_for_find))
    end
    
    def find_top_level_and_all_ancestors(options_for_find = {})
      top_level = find_top_level
      candidates = [top_level] + top_level.map { |choice| ancestors_of(choice) }.flatten
      candidates.flatten
    end
    
    def find_top_level_and_orphaned
      find_top_level + find_without_parent_in(find_top_level_and_all_ancestors)
    end
    
    def find_top_level_and_orphaned_sorted
      find_top_level_and_orphaned.sort { |a, b| a.label <=> b.label }
    end
    
    def ancestors_of(choice)
      choice.children + choice.children.map { |child| ancestors_of(child) }.flatten.uniq
    end
    
  end
  
end