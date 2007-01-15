# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  # only permit site members to add/delete things
  before_filter :login_required, :except => [ :login, :signup, :logout, :show, :search, :index, :list]

  # all topics and content items belong in a basket
  # some controllers won't need it, but it shouldn't hurt have it available
  # and will always be specified in our routes
  before_filter :load_basket

  # setup return_to for the session
  after_filter :store_location, :only => [ :index, :new, :show, :edit]

  def load_basket
    @current_basket = Basket.new
    if !params[:urlified_name].blank?
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    else
      # the first basket is always the default
      @current_basket = Basket.find(1)
    end
    return @current_basket
  end

  def redirect_to_related_topic(topic_id)
    # TODO: doublecheck this isn't too expensive, maybe better to find_by_sql
    basket = Basket.find_by_sql(["select b.id, b.urlified_name from baskets as b inner join topics as t on b.id = t.basket_id where t.id = ?", topic_id])
    redirect_to :action => 'show', :controller => 'topics', :id => topic_id, :urlified_name => basket[0]
  end

  # overriding here, to grab title of page, too
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
    session[:return_to_title] = @title
  end
end
