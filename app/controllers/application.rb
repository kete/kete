# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  # all topics and content items belong in a basket
  # some controllers won't need it, but it shouldn't hurt have it available
  # and will always be specified in our routes
  before_filter :load_basket

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

    basket = Basket.find(:select => "b.urlified_name",
                         :join => "as b inner join topics as t on b.id = t.basket_id",
                         :conditions => ["t.id = ?", topic_id])
    redirect_to :action => 'show', :controller => 'topics', :id => topic_id, :urlified_name => basket.urlified_name
  end
  def redirect_to_search_for_class(current_class)
    redirect_to :controller => 'search', :current_class => current_class
  end
end
