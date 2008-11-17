class TagsController < ApplicationController
  def index
    @type = @current_basket.index_page_tags_as || 'categories'
    @order = params[:order] || @current_basket.index_page_order_tags_by || 'random'
    @tags_in_reverse = (params[:tags_in_reverse] && params[:tags_in_reverse] == 'reverse') ? true : false

    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1
    @number_per_page = 25

    @tag_counts_array = @current_basket.tag_counts_array({:limit => false, :order => @order, :tags_in_reverse => @tags_in_reverse})
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
