class TagsController < ApplicationController
  def index
    @type = params[:type] || 'tag_cloud'
    @order = params[:order] || 'random'
    @tags_in_reverse = (params[:tags_in_reverse] && params[:tags_in_reverse] == 'reverse') ? true : false
    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1

    @number_per_page = 25

    @tag_counts_array = @current_basket.tag_counts_array({:limit => false, :order => @order, :tags_in_reverse => @tags_in_reverse})
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @tag_counts_array.size)
    @tags = @tag_counts_array[(@results.offset)..(@results.offset + (@number_per_page - 1))]
  end

  def list
    index
  end
end
