class MembersController < ApplicationController
  # everything else is handled by application.rb
  before_filter :login_required, :only => [:list, :index]

  permit "site_admin or admin of :current_basket"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to :action => 'list'
  end

  def list
    # this sets up all instance variables
    # as well as preparing @members
    list_members

    # list people who have all other roles
    @current_basket.accepted_roles.each do |role|
      role_plural = role.name.pluralize
      # we cover members above
      if role_plural != 'members'
        instance_variable_set("@#{role_plural}", @current_basket.send("has_#{role_plural}"))
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

  def list_members
    @non_member_roles_plural = Hash.new
    @possible_roles = {'admin' => 'Admin',
      'moderator' => 'Moderator',
      'member' => 'Member'
    }

    @admin_actions = Hash.new

    if @current_basket == @site_basket and site_admin?
      @possible_roles['tech_admin'] = 'Tech Admin'
      @possible_roles['site_admin'] = 'Site Admin'
      @admin_actions['become_user'] = 'Login as user'
      @admin_actions['destroy'] = 'Delete'
      @admin_actions['ban'] = 'Ban'
    else
      @admin_actions['remove'] = 'Remove from Basket'
    end

    # members are paginated
    # since we are paginating we need to break a part
    # what the @current_basket.has_members method would do
    @member_role = Role.find_by_name_and_authorizable_type_and_authorizable_id('member','Basket', @current_basket)
    if @member_role.nil?
      # no members
      @members = User.paginate_by_id(0, :page => 1)
    else
      @members = User.paginate(:joins => "join roles_users on users.id = roles_users.user_id",
                               :conditions => ["roles_users.role_id = ?", @member_role.id],
                               :page => params[:page],
                               :per_page => 10)
    end

    if request.xhr?
      render :partial =>'list_members',
      :locals => { :members => @members,
        :possible_roles => @possible_roles,
        :admin_actions => @admin_actions }
    else
      if params[:action] == 'list_members'
        redirect_to params.merge(:action => 'list')
      end
    end
  end

  def potential_new_members
    @existing_users = User.find(:all,
                                :joins => "join roles_users on users.id = roles_users.user_id",
                                :conditions => ["roles_users.role_id in (?)", @current_basket.accepted_roles])

    @potential_new_members = User.find(:all,
                                       :conditions => ["id not in (:existing_users) and login like :searchtext or extended_content like :searchtext",
                                                       { :existing_users => @existing_users,
                                                         :searchtext => '%' + params[:search_name] + '%' }])

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
      # tech admin is essentially the only allowed duplicate role
      # you have to be a site_admin to be eligable to be tech_admin
      # because it's sensitive, we don't handle tech_admin rights
      # in the normal way
      clear_roles = true
      if membership_type == 'tech_admin'
        if @current_basket == @site_basket and @user.has_role?('site_admin')
          clear_roles = false
          flash[:notice] = 'User has been made tech admin.'
        else
          flash[:notice] = 'User is not eligable to be tech admin. The need to be a site admin, too.'
          can_change = false
        end
      end
      if can_change
        if clear_roles
          @current_basket.accepted_roles.each do |role|
            @user.has_no_role(role.name,@current_basket)
          end
        end
        @user.has_role(membership_type,@current_basket)
        if flash[:notice].blank?
          flash[:notice] = 'User successfully changed role.'
        end
      end
    else
      flash[:notice] = "Unable to have no site administrators."
    end
    redirect_to :action => 'list'
  end

  # we need at least one site admin at all times
  def more_than_one_site_admin?
    @site_basket.has_site_admins.size > 1
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

  def ban
    @user = User.find(params[:id])
    @user.banned_at = Time.now
    if @user.save
      flash[:notice] = "Successfully banned user."
      redirect_to :action => 'list'
    end
  end

  def unban
    @user = User.find(params[:id])
    @user.banned_at = nil
    if @user.save
      flash[:notice] = "Successfully removed ban on user."
      redirect_to :action => 'list'
    end
  end

  def add_members
    if !params[:user]
      params[:user] = Hash.new
      params[:user][params[:id]] = 1
    end

    params[:user].keys.each do |user|
      if params[:user][user][:add_checkbox].to_i != 0
        user = User.find(user)
        user.has_role('member', @current_basket)
      end
    end

    flash[:notice] = "Successfully added new "

    if params[:user].size > 1
      flash[:notice] += "members."
    else
      flash[:notice] += "member."
    end

    redirect_to :action => 'list'
  end

  def remove
    @user = User.find(params[:id])
    @current_basket.accepted_roles.each do |role|
      @user.has_no_role(role.name,@current_basket)
    end
    flash[:notice] = "Successfully removed user."
    redirect_to :action => 'list'
  end

end
