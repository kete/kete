class ModerateController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, only: %i[list index rss]

  permit 'site_admin or admin of :current_basket'

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #        :redirect_to => { :action => :list }

  # action menu uses a basket helper we need
  helper :baskets

  def index
    redirect_to action: 'list'
  end

  # limit to items in this basket
  # that have disputed versions
  def list
    @rss_tag_auto = rss_tag(replace_page_with_rss: true)
    @rss_tag_link = rss_tag(auto_detect: false, replace_page_with_rss: true)
    fetch_revisions
  end

  def rss
    fetch_revisions
    respond_to do |format|
      format.xml
    end
  end

  private

  def fetch_revisions
    @items = case params[:type]
    when 'reviewed'
      @current_basket.all_reviewed_revisions
    when 'rejected'
      @current_basket.all_rejected_revisions
    else
      @current_basket.all_disputed_revisions
             end
  end
end
