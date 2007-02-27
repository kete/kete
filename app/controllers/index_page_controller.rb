class IndexPageController < ApplicationController

  def index
      render( :file => "#{RAILS_ROOT}/public/index-source.html", :layout => true )
  end
end
