class TagsController < ApplicationController
  def index
    @order = params[:order] ? params[:order] : 'alphabetical'
    @reverse = params[:reverse] && params[:reverse] == 'reverse' ? true : false
    @current_page = params[:page] && params[:page].to_i > 0 ? params[:page].to_i : 1

    @number_per_page = 25
    @start_record = (@current_page - 1) * (@number_per_page - 1)
    @end_record = (@current_page) * (@number_per_page -1)

    @tag_counts_array = @current_basket.tag_counts_array({:limit => false, :order => @order, :reverse => @reverse})
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, @tag_counts_array.size)
    @tags = @tag_counts_array[(@start_record)..(@end_record)]
  end

  def list
    index
  end
end
