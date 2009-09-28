module SearchSourcesHelper
  def cache_key_for(source)
    # If we are on an item page, make sure we add the item title to the cache key
    # so that if the title changes, the cache is made invalid and gets recreated
    if @current_item
      { :search_source => source.title_id, :id => params[:id].to_i, :title => @current_item.to_param }
    else
      { :search_source => source.title_id, :id => params[:id].to_i }
    end
  end
end
