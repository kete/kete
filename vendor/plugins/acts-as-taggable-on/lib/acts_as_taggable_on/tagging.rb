class Tagging < ActiveRecord::Base #:nodoc:
  belongs_to :tag
  belongs_to :taggable, :polymorphic => true
  belongs_to :tagger, :polymorphic => true
  validates_presence_of :context

  # Kieran Pilkington, 2009-05-12
  # We make taggings belong to a basket, which makes
  # homepage tag clouds a lot faster to generate
  belongs_to :basket
end