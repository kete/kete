class MembersController < ApplicationController

  permit "site_admin or admin of :current_basket", :except => [:index, :list, :join, :remove, :rss]

  before_filter :permitted_to_view_memberlist, :only => [:index, :list, :rss]

  before_filter :permitted_to_remove_basket_members, :only => [:remove]

  def index
    redirect_to :action => 'list'
  end

  def list
    if !params[:type].blank? && @basket_admin
      @listing_type = params[:type]
    else
      @listing_type = 'all'
    end

    paginate_order = current_sorting_options('users.login', 'asc', ['users.login', 'roles_users.created_at', 'users.email'])

    # this sets up all instance variables
    # as well as preparing @members
    list_members(paginate_order)

    # turn on rss
    @rss_tag_auto = rss_tag(:replace_page_with_rss => true)
    @rss_tag_link = rss_tag(:auto_detect => false, :replace_page_with_rss => true)

    # list people who have all other roles
    # use (true) because the roles are cached when first run but
    # if we add roles (like moderator) this becomes problematic
    @current_basket.accepted_roles(true).each do |role|
      # skip this role if we're viewing all members and the role is requested or rejected
      next if (@listing_type == 'all' && (role.name == 'membership_requested' || role.name == 'membership_rejected'))
      # skip this role if we're viewing pending join requests and the role is something other than requested
      next if (@listing_type == 'pending' && role.name != 'membership_requested')
      # skip this role if we're viewing rejected join requests and the role is something other than rejected
      next if (@listing_type == 'rejected' && role.name != 'membership_rejected')

      role_plural = role.name.pluralize

      # we cover members above
      if role_plural != 'members'
        instance_variable_set("@#{role_plural}", @current_basket.send("has_#{role_plural}"))
        @non_member_roles_plural[role.name] = role_plural
      end
    end
  end

  def list_members(order='users.login asc')
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
    @member_role = Role.find_by_name_and_authorizable_type_and_authorizable_id('member', 'Basket', @current_basket)
    if @member_role.nil?
      # no members
      @members = User.paginate_by_id(0, :page => 1)
    else
      if params[:action] == 'rss'
        @members = @member_role.users(:order => 'updated_at desc')
      else
        @members = @member_role.users.paginate(:include => :contributions,
                                               :order => order,
                                               :page => params[:page],
                                               :per_page => 20)

      end
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

  def join
    if !@basket_access_hash[@current_basket.urlified_name.to_sym].blank?
      flash[:error] = "You already have a role in this basket or you have already applied to join."
    else
      case @current_basket.join_policy_with_inheritance
      when 'open'
        current_user.has_role('member', @current_basket)
        @current_basket.administrators.each do |admin|
          UserNotifier.deliver_join_notification_to(admin, current_user, @current_basket, 'joined')
        end
        flash[:notice] = "You have joined the #{@current_basket.urlified_name} basket."
      when 'request'
        current_user.has_role('membership_requested', @current_basket)
        @current_basket.administrators.each do |admin|
          UserNotifier.deliver_join_notification_to(admin, current_user, @current_basket, 'request')
        end
        flash[:notice] = "A basket membership request has been sent. You will get an email when it is approved."
      else
        flash[:error] = "This basket isn't currently accepting join requests."
      end
    end
    redirect_to "/#{@current_basket.urlified_name}/"
  end

  def change_membership_type
    membership_type = params[:role]
    @user = User.find(params[:id])

    can_change = false

    if @current_basket != @site_basket || !@user.has_role?('site_admin') || @site_basket.more_than_one_site_admin?
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
          @current_basket.delete_roles_for(@user)
        end
        @user.has_role(membership_type, @current_basket)
        if flash[:notice].blank?
          flash[:notice] = 'User successfully changed role.'
        end
      end
    else
      flash[:notice] = "Unable to have no site administrators."
    end
    redirect_to :action => 'list'
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

  # Remove is called from non-site baskets, only usable when
  #   the current basket isn't the site basket
  #   the basket has one other admin besides this user
  def remove
    # make sure we arn't trying to remove from site basket (destroy is the correct action for that)
    if @current_basket == @site_basket
      flash[:error] = "You cannot remove yourself from the Site basket."
    elsif !@current_basket.more_than_one_basket_admin?
      flash[:error] = "Unable to have no basket administrators."
    else
      @user ||= User.find(params[:id]) # will already be set by before filter 'permitted_to_remove_basket_members'
      @current_basket.delete_roles_for(@user)
      flash[:notice] = "Successfully removed user from #{@current_basket.name}."
    end

    if current_user_can_see_memberlist_for?(@current_basket)
      redirect_location = { :action => 'list' }
    else
      redirect_location = "/#{@site_basket.urlified_name}/"
    end

    redirect_to redirect_location
  end

  # Destroy is called from the site basket, only usable when
  #   the member has no contributions
  #   the basket has one other site admin besides this user
  def destroy
    @user = User.find(params[:id])
    if @user.contributions.size > 0
      flash[:error] = "#{@user.user_name} has contributions and cannot be deleted from the site. Perhaps a ban instead?"
    elsif !@site_basket.more_than_one_site_admin?
      flash[:error] = "Unable to have no site administrators."
    else
      @user.destroy
      flash[:notice] = "#{@user.user_name} has been deleted from the site."
    end
    redirect_to :action => 'list'
  end

  def change_request_status
    @user = User.find(params[:id])
    @current_basket.delete_roles_for(@user)

    approved = (params[:status] && params[:status] == 'approved')
    if approved
      @user.has_role('member', @current_basket)
      flash[:notice] = "#{@user.user_name}'s membership request has been accepted."
    else
      @user.has_role('membership_rejected', @current_basket)
      flash[:notice] = "#{@user.user_name}'s membership request has been rejected."
    end

    UserNotifier.deliver_join_notification_to(@user, current_user, @current_basket, params[:status])
    redirect_to :action => 'list'
  end

  def rss
    # changed from @headers for Rails 2.0 compliance
    response.headers["Content-Type"] = "application/xml; charset=utf-8"

    list_members

    respond_to do |format|
      format.xml
    end
  end

  private

  def permitted_to_view_memberlist
    unless current_user_can_see_memberlist_for?(@current_basket)
      flash[:error] = "You need to have the right permissions to access this baskets member list"
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end

  def permitted_to_remove_basket_members
    @user = User.find(params[:id])
    unless logged_in? && (permit?("site_admin or admin of :current_basket") || @current_user == @user)
      flash[:error] = "You need to have the right permissions to remove basket members"
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end
end
