class ContentType < ActiveRecord::Base
  has_many :content_type_to_field_mappings, :dependent => :destroy, :order => 'position'
  # you have to do the elimination of dupes through the sql
  # otherwise, rails will reorder by content_type_to_field_mapping.id after the sql has bee run
  has_many :form_fields, :through => :content_type_to_field_mappings, :source => :extended_field, :select => "distinct content_type_to_field_mappings.position, extended_fields.*", :order => 'position' do
    def <<(extended_field)
      ContentTypeToFieldMapping.with_scope(:create => { :required => "false"}) { self.concat extended_field }
    end
  end
  has_many :required_form_fields, :through => :content_type_to_field_mappings, :source => :required_form_field, :select => "distinct content_type_to_field_mappings.position, extended_fields.*", :conditions => "content_type_to_field_mappings.required = 'true'", :order => 'position' do
    def <<(required_form_field)
      ContentTypeToFieldMapping.with_scope(:create => { :required => "true"}) { self.concat required_form_field }
    end
  end
  validates_presence_of :controller, :class_name, :humanized, :humanized_plural
  validates_uniqueness_of :controller, :class_name, :humanized, :humanized_plural

  # TODO: humanized and humanized_plural should be capitalized, do as validation or programmatically

  # TODO: globalize stuff, uncomment later
  # translates :humanized, :humanized_plura, :description

  def available_fields
    @available_fields = ExtendedField.find_available_fields(self,'ContentType')
  end
end
