module BasketsHelper
  def link_to_link_index_topic(options={})
    link_to options[:phrase], {
      :controller => 'search',
      :action => :find_index,
      :index_for_basket => options[:index_for_basket] },
    :popup => ['links', 'height=300,width=740,scrollbars=yes,top=100,left=100']
  end

  def link_to_add_index_topic(options={})
    link_to options[:phrase], :controller => 'topics', :action => :new, :index_for_basket => options[:index_for_basket]
  end

end
