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

    @tag_counts_array = @current_basket.tag_counts_array({ :limit => false, :order => @order, :direction => params[:direction] })
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @tag_counts_array.size)
    @tags = @tag_counts_array[(@results.offset)..(@results.offset + (@number_per_page - 1))]

    respond_to do |format|
      format.html
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/tags/tags_list.js.rjs') }
    end
  end

  def list
    index
  end
end
