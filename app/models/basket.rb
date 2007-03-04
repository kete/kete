# Kete means "basket" in the Te Reo Maori language
# using term basket here to spell out concept for developers
# and to avoid confusion with the kete app
class Basket < ActiveRecord::Base
  # set up authorization plugin
  acts_as_authorizable

  # everything falls under one basket or another
  # we have a default basket for the site
  # can't use delete_all, throws off versioning
  ZOOM_CLASSES.each do |zoom_class|
    has_many zoom_class.tableize.to_sym, :dependent => :destroy
  end

  validates_presence_of :name
  validates_uniqueness_of :name

  # don't allow special characters in label that will break our xml
  validates_format_of :name, :with => /^[^\'\"<>\&,\/\\]*$/, :message => ": \', \\, /, &, \", <, and > characters aren't allowed"

  # TODO: handle non-ascii characters with entities? i.e. url_encode

  # we have an urlified_name attribute that hold the urlified version of the basket name
  before_save :urlify_name

  protected
  # before filter
  def urlify_name
    return if name.blank?
    formatted_name = name.to_s.gsub(/ /, '_').
      gsub(/-/,'_').
      downcase
    self.urlified_name = formatted_name
  end

end
