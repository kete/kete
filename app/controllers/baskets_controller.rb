class BasketsController < ApplicationController
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
  end

  def new
    @basket = Basket.new
  end

  def create
    @basket = Basket.new(params[:basket])
    if @basket.save
      flash[:notice] = 'Basket was successfully created.'
      redirect_to :action => 'list'
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
