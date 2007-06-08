class MembersController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :current_basket"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    list
    render :action => 'list'
  end

  def list
    @non_member_roles_plural = Hash.new
    @members = nil
    @possible_roles = {'admin' => 'Admin',
      'moderator' => 'Moderator',
      'member' => 'Member'
    }

    @site_admin_actions = Hash.new

    if @current_basket.urlified_name == 'site' and site_admin?
      @possible_roles['site_admin'] = 'Site Admin'
      @site_admin_actions['become_user'] = 'Login as user'
      @site_admin_actions['destroy'] = 'Delete'
    end

    @current_basket.accepted_roles.each do |role|
      role_plural = role.name.pluralize
      instance_variable_set("@#{role_plural}", @current_basket.send("has_#{role_plural}"))
      if role_plural == 'members'
        @members = @current_basket.has_members
      else
        @non_member_roles_plural[role.name] = role_plural
      end
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
    else
      render :action => 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def change_membership_type
    membership_type = params[:role]
    @user = User.find(params[:id])

    can_change = false

    if !@user.has_role?('site_admin') or more_than_one_site_admin?
      can_change = true
    end

    if can_change == true
      # bit to do the change
      @current_basket.accepted_roles.each do |role|
        @user.has_no_role(role.name,@current_basket)
      end
      @user.has_role(membership_type,@current_basket)
      flash[:notice] = 'User successfully changed role.'
      redirect_to :action => 'list'
    else
      flash[:notice] = "Unable to have no site administrators"
      redirect_to :action => 'list'
    end
  end

  # we need at least one site admin at all times
  def more_than_one_site_admin?
    Basket.find(1).has_site_admins.size > 1
  end

  # added so site admins can assume identities of users if necessary
  def become_user
    return unless request.post?

    # logout the old user first
    # stolen from account_controller.logout, should make DRY
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session

    # now login as new user
    self.current_user = User.find(params[:id])
    if logged_in?
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = "Logged in successfully"
    end
  end

end
