class Tag < ActiveRecord::Base
  has_many :taggings

  validates_presence_of :name
  validates_uniqueness_of :name

  class << self
    delegate :delimiter, :delimiter=, :to => TagList
  end

  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end

  def to_s
    name
  end

  def count
    read_attribute(:count).to_i
  end

  # Walter McGinnis, 2007-07-04
  # turn pretty urls on or off here
  include FriendlyUrls
  alias :to_param :format_for_friendly_urls
end
