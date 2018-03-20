# frozen_string_literal: true

class Tagging < ActiveRecord:: Base
  # The acts-as-taggable-on gem creates a `taggings` table in the DB but it does not
  # create a `Tagging model. It used to create this model and the old Kete
  # depended on it for working directly with the `taggings` table.
  #
  # We have added this model to keep the old Kete code working.
end
