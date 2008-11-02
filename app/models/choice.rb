class Choice < ActiveRecord::Base
  
  # Associations (polymorphic has_many :through)
  has_many :choice_mappings
  
  has_many :extended_fields, :through => :choice_mappings, 
    :source => :field, :source_type => 'ExtendedField'
    
  # STI for subcategories
  belongs_to :parent, :class_name => 'Choice', :foreign_key => 'parent_id'
  has_many :children, :class_name => 'Choice', :foreign_key => 'parent_id'
  
  # Label is compulsory
  validates_presence_of :label

  # If no value is given, use the label as the value
  # I expect this will be a pretty common use-case
  def value
    read_attribute(:value).blank? ? label : read_attribute(:value)
  end
  
  class << self
    
    def options_for_select
      find(:all).collect { |c| [c.label, c.value] }
    end
    
  end
  
end