class TagsController < ApplicationController
  def index
    @order = params[:order] ? params[:order] : 'alphabetical'
    @tags_in_reverse = (params[:tags_in_reverse] && params[:tags_in_reverse] == 'reverse') ? true : false
    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1

    @number_per_page = 25
    @start_record = (@current_page - 1) * (@number_per_page - 1)
    @end_record = (@current_page) * (@number_per_page -1)

    @tag_counts_array = @current_basket.tag_counts_array({:limit => false, :order => @order, :tags_in_reverse => @tags_in_reverse})
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @tag_counts_array.size)
    @tags = @tag_counts_array[(@start_record)..(@end_record)]
  end

  def list
    index
  end
end
