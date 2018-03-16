# frozen_string_literal: true

class Contribution < ActiveRecord::Base
  # this is where we track our polymorphic contributions
  # between users
  # and multiple types of items
  # the user can have multiple contributions
  # for versions
  # or multiple roles
  belongs_to :user
  belongs_to :contributed_item, polymorphic: true

  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through

  ZOOM_CLASSES.each do |zoom_class|
    # to track whom created these things
    belongs_to "created_#{zoom_class.tableize.singularize}".to_sym,
               class_name: zoom_class,
               foreign_key: 'contributed_item_id'

    # to track whom contributed to these things
    belongs_to "contributed_#{zoom_class.tableize.singularize}".to_sym,
               class_name: zoom_class,
               foreign_key: 'contributed_item_id'
  end

  def self.add_as_to(user, role, item)
    with_scope(create: {
                 contributor_role: role,
                 version: user.version
               }) { item.concat user }
  end
end
