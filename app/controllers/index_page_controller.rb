class IndexPageController < ApplicationController

  def index
      render( :file => "#{RAILS_ROOT}/public/index-source.html", :layout => true )
  end

  def help_file
      render(:layout => "layouts/simple", :file => "#{RAILS_ROOT}/public/about/manual-source.html")
  end

  def uptime
      render(:text => "success")
  end

end
