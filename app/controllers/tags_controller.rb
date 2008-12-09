class TagsController < ApplicationController
  def index
    @type = @current_basket.index_page_tags_as || 'categories'
    @default_order = @current_basket.index_page_order_tags_by || 'latest'
    @order = params[:order] || @default_order
    @direction = params[:direction] || 'desc'

    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1
    # clouds can accommodate more tags per page than category view
    @number_per_page = 75
    @number_per_page = 25 if @type == "categories"

    @privacy_type = (@current_basket != @site_basket && permitted_to_view_private_items?) ? 'private' : 'public'

    @tag_counts_array = @current_basket.tag_counts_array({ :limit => false, :order => @order, :direction => @direction }, (@privacy_type == 'private'))
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @tag_counts_array.size)
    @tags = @tag_counts_array[(@results.offset)..(@results.offset + (@number_per_page - 1))]

    @rss_tag_auto = rss_tag
    @rss_tag_link = rss_tag(:auto_detect => false)

    respond_to do |format|
      format.html
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/tags/tags_list.js.rjs') }
    end
  end

  def list
    index
  end

  def rss
    response.headers["Content-Type"] = "application/xml; charset=utf-8"

    @number_per_page = 100

    # this doesn't work with http auth from and IRC client
    @privacy_type = (@current_basket != @site_basket && permitted_to_view_private_items?) ? 'private' : 'public'

    @tags = @current_basket.tag_counts_array({ :limit => @number_per_page, :order => 'latest', :direction => 'desc' }, (@privacy_type == 'private'))

    respond_to do |format|
      format.xml
    end
  end

end
