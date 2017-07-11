class ContentType < ActiveRecord::Base
  has_many :content_type_to_field_mappings, dependent: :destroy, order: 'position'
  # you have to do the elimination of dupes through the sql
  # otherwise, rails will reorder by content_type_to_field_mapping.id after the sql has bee run
  has_many :form_fields, through: :content_type_to_field_mappings, source: :extended_field, select: 'distinct content_type_to_field_mappings.position, extended_fields.*', order: 'position' do
    def <<(extended_field)
      ContentTypeToFieldMapping.add_as_to('false', self, extended_field)
    end
  end
  has_many :required_form_fields, through: :content_type_to_field_mappings, source: :required_form_field, select: 'distinct content_type_to_field_mappings.position, extended_fields.*', conditions: "content_type_to_field_mappings.required = 'true'", order: 'position' do
    def <<(required_form_field)
      ContentTypeToFieldMapping.add_as_to('true', self, required_form_field)
    end
  end
  validates_presence_of :controller, :class_name, :humanized, :humanized_plural
  validates_uniqueness_of :controller, :class_name, :humanized, :humanized_plural, case_sensitive: false

  # TODO: humanized and humanized_plural should be capitalized, do as validation or programmatically

  # TODO: globalize stuff, uncomment later
  # translates :humanized, :humanized_plura, :description

  def available_fields
    @available_fields = ExtendedField.find_available_fields(self,'ContentType')
  end

  def mapped_fields(options={})
    # TODO: might want to reconsider using a subselect here
    ExtendedField.where('id in (select extended_field_id from content_type_to_field_mappings where content_type_id in (?))', self).all
  end
end
