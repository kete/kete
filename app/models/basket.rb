# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # set up authorization plugin
  acts_as_authorizable

  # everything falls under one basket or another
  # we have a default basket for the site
  has_many :topics, :dependent => :delete_all
  has_many :web_links, :dependent => :delete_all
  has_many :audio_recordings, :dependent => :delete_all
  has_many :videos, :dependent => :delete_all
  has_many :still_images, :dependent => :delete_all

  validates_presence_of :name
  validates_uniqueness_of :name
  # TODO: don't allow special characters in names
  # TODO: handle non-ascii characters with entities? i.e. url_encode

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  protected
  # before filter
  def urlify_name
    return if name.blank?
    formatted_name = name.to_s.gsub(/ /, '-').
      gsub(/_/,'-').
      downcase
    self.urlified_name = formatted_name
  end

end
