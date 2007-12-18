class ModerateController < ApplicationController
  layout "application" , :except => [:rss]

  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index, :rss]

  permit "site_admin or admin of :current_basket"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  # limit to items in this basket
  # that have disputed versions
  def list
    @rss_tag_auto = rss_tag(:replace_page_with_rss => true)
    @rss_tag_link = rss_tag(:auto_detect => false, :replace_page_with_rss => true)

    @items = Array.new
    ZOOM_CLASSES.each do |zoom_class|
      class_plural = zoom_class.tableize
      these_class_items = @current_basket.send("#{class_plural}").find_disputed

      logger.debug("what is size of this batch of disputed stuff: " + these_class_items.size.to_s)
      @items += these_class_items
    end

    # sort by flagged_at
    @items.sort_by { |item| item.flagged_at }

    # add pagination last?
    # @items.paginate(:page => params[:page], :per_page => 10)
  end

  def rss
    # changed from @headers for Rails 2.0 compliance
    response.headers["Content-Type"] = "application/xml; charset=utf-8"

    list

    respond_to do |format|
      format.xml
    end
  end
end
