# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # set up authorization plugin
  acts_as_authorizable

  # everything falls under one basket or another
  # we have a default basket for the site
  # can't use delete_all, throws off versioning
  has_many :topics, :dependent => :destroy
  has_many :web_links, :dependent => :destroy
  has_many :audio_recordings, :dependent => :destroy
  has_many :videos, :dependent => :destroy
  has_many :still_images, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  # TODO: don't allow special characters in names
  # TODO: handle non-ascii characters with entities? i.e. url_encode

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  protected
  # before filter
  # TODO: look up to_param and whether we should use it
  def urlify_name
    return if name.blank?
    formatted_name = name.to_s.gsub(/ /, '_').
      gsub(/-/,'_').
      downcase
    self.urlified_name = formatted_name
  end

end
