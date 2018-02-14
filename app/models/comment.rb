# frozen_string_literal: true

class Comment < ActiveRecord::Base
  include PgSearch
  include PgSearchCustomisations
  multisearchable against: %i[
    title
    description
    raw_tag_list
    searchable_extended_content_values
  ]

  # don't orphan children
  # reassign them as children of their grandparent
  # if you destroy their parent
  before_destroy :reassign_children_to_grandparent

  # comments unique feature is that they are attached to another item
  # this code is adapted from the acts_as_commentable plugin
  # http://www.juixe.com/techknow/index.php/2006/06/18/acts-as-commentable-plugin/
  # however, we do user contribution tracking, searchability, etc.
  # through our standard kete content item stuff (see include below)
  belongs_to :commentable, polymorphic: true

  ZOOM_CLASSES.each do |zoom_class|
    unless zoom_class == 'Comment'
      belongs_to "direct_#{zoom_class.tableize.singularize}".to_sym, class_name: zoom_class, foreign_key: 'commentable_id'
    end
  end

  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  include ItemPrivacy::ActsAsVersionedOverload
  include ItemPrivacy::TaggingOverload

  validates_presence_of :description

  # most likely we won't use versioning for comments
  # but we provide it for consistency sake with the rest of kete
  # however, we definitely don't need to keep track of what the comment is on
  # in the versioning table
  non_versioned_columns << 'commentable_id'
  non_versioned_columns << 'commentable_type'

  # Do not version commentable privacy.
  non_versioned_columns << 'commentable_private'

  # Do not version nested set fields since they can't change
  non_versioned_columns << 'parent_id'
  non_versioned_columns << 'lft'
  non_versioned_columns << 'rgt'

  acts_as_nested_set

  # pulled almost directly from acts_as_commentable
  # Helper class method to look up all comments for
  # commentable class name and commentable id.
  def self.find_comments_for_commentable(commentable_str, commentable_id)
    where(commentable_type: commentable_str, commentable_id: commentable_id).order('lft')
  end

  # pulled almost directly from acts_as_commentable
  # Helper class method to look up a commentable object
  # given the commentable class name and id
  def self.find_commentable(commentable_str, commentable_id)
    commentable_str.constantize.find(commentable_id)
  end

  # We need to pretend to respond to privacy related methods in order
  # for the customized ActsAsZoom to store the comment record in the
  # correct Zebra instance.
  def private?
    commentable_private?
  end

  def private
    commentable_private
  end

  def private=(*args)
    self.commentable_private = *args
  end

  def has_private_version?
    commentable_private?
  end

  def should_save_to_private_zoom?
    commentable_private?
  end

  def private_version(&block)
    block.call
  end

  def to_anchor
    "comment-#{id}"
  end

  private

  def reassign_children_to_grandparent
    grandparent = parent
    # Move children up a level
    if grandparent
      children.each do |comment|
        comment.move_to_child_of(grandparent)
      end
    else
      children.each do |comment|
        # Use update_all instead of self.update_attribute to avoid validations and callbacks
        Comment.update_all("#{parent_column_name} = NULL", { id: comment.id })
      end
    end
  end
end
