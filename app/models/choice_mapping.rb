# frozen_string_literal: true

class ChoiceMapping < ActiveRecord::Base
  belongs_to :choice
  belongs_to :field, polymorphic: true

  # Ensure that choice mappings are shown nicely when using the
  # 'show' action in the extended_fields controller.
  def to_s
    choice.label rescue super
  end
end
