class BasketsController < ApplicationController
  # only permit site members to do anything with baskets
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @basket_pages, @baskets = paginate :baskets, :per_page => 10
  end

  def show
    @basket = Basket.find(params[:id])
    @title = @basket.name
  end

  def new
    @basket = Basket.new
  end

  def create
    @basket = Basket.new(params[:basket])
    if @basket.save
      @basket.accepts_role 'admin', @current_user

      flash[:notice] = 'Basket was successfully created.'
      redirect_to :controler => 'search'
    else
      render :action => 'new'
    end
  end

  def edit
    @basket = Basket.find(params[:id])
  end

  def update
    @basket = Basket.find(params[:id])
    if @basket.update_attributes(params[:basket])
      flash[:notice] = 'Basket was successfully updated.'
      redirect_to :action => 'show', :id => @basket
    else
      render :action => 'edit'
    end
  end

  def destroy
    Basket.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
