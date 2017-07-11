class TopicType < ActiveRecord::Base
  # dependent topics should be what if a topic_type is destroyed?
  has_many :topics
  has_many :topic_type_to_field_mappings, dependent: :destroy, order: 'position'
  # Walter McGinnis (walter@katipo.co.nz), 2006-10-05
  # these association extension maybe able to be cleaned up with modules or something in rails proper down the line
  # code based on work by hasmanythrough.com
  # you have to do the elimination of duplicates through the sql
  # otherwise, rails will reorder by topic_type_to_field_mapping.id after the sql has bee run
  has_many :form_fields, through: :topic_type_to_field_mappings, source: :extended_field, select: 'distinct topic_type_to_field_mappings.position, extended_fields.*', order: 'position' do
    def <<(extended_field)
      TopicTypeToFieldMapping.add_as_to('false', self, extended_field)
    end
  end
  has_many :required_form_fields, through: :topic_type_to_field_mappings, source: :required_form_field, select: 'distinct topic_type_to_field_mappings.position, extended_fields.*', conditions: "topic_type_to_field_mappings.required = 'true'", order: 'position' do
    def <<(required_form_field)
      TopicTypeToFieldMapping.add_as_to('true', self, required_form_field)
    end
  end

  # imports are processes to bring in content to a basket
  # they specify a topic type of thing they are importing
  # or a topic type for the item that relates groups of things
  # that they are importing
  has_many :imports, dependent: :destroy

  scope :from_urlified_name, lambda { |urlified_name| where('LOWER(name) = ?', urlified_name.downcase.gsub('_', ' ')) }

  validates_presence_of :name, :description
  validates_uniqueness_of :name, case_sensitive: false

  # don't allow special characters in label that will break urls
  validates_format_of :name, with: /^[^\'\":<>\&,\/\\\?\.]*$/, message: lambda { I18n.t('topic_type_model.invalid_chars', invalid_chars: ": \', \\, /, &, \", ?, <, >, and .") }

  # to support inheritance of fields from ancestor topic types
  acts_as_nested_set

  # TODO: globalize stuff, uncomment later
  # translates :name, :description

  # we have a generic topic_type of Topic from which all types inherit their attributes
  # since these default fields reflect the state of the Topic model
  # then we also have ancestor fields for all the topic types above this topic type

  def available_fields
    @available_fields = ExtendedField.find_available_fields(self, 'TopicType')
  end

  def mapped_fields(options = {})
    options[:with_ancestors] ||= true
    relevant_topic_types = options[:with_ancestors] ? self_and_ancestors : [self]
    # TODO: might want to reconsider using a subselect here
    ExtendedField.where('id in (select extended_field_id from topic_type_to_field_mappings where topic_type_id in (?))', relevant_topic_types).all
  end

  def self_and_ancestors_ids
    @self_and_ancestors_ids ||= self_and_ancestors.collect { |a| a.id }
  end

  # MySQL ordering doesn't work well here so we do our own ordering
  def all_field_mappings
    mappings = TopicTypeToFieldMapping.find_all_by_topic_type_id(self_and_ancestors_ids, order: 'position ASC')
    self_and_ancestors_ids.collect do |id|
      mappings.select { |mapping| mapping.topic_type_id == id }
    end.flatten
  rescue
    []
  end

  def urlified_name
    name.downcase.gsub(/\s/, '_')
  end

  def full_set
    self_and_descendants
  end
end
