class ModerateController < ApplicationController
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

    @items = @current_basket.all_disputed_revisions
  end

  def rss
    @cache_key_hash = { :rss => "#{@current_basket.urlified_name}_moderate_list" }
    unless has_all_rss_fragments?(@cache_key_hash)
      @items = @current_basket.all_disputed_revisions
    end
    respond_to do |format|
      format.xml
    end
  end
end
