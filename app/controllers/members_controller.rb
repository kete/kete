class MembersController < ApplicationController

  permit 'site_admin or admin of :current_basket', except: [:index, :list, :join, :remove, :rss]

  before_filter :permitted_to_view_memberlist, only: [:index, :list, :rss]

  before_filter :permitted_to_remove_basket_members, only: [:remove]

  # action menu uses a basket helper we need
  helper :baskets

  def index
    redirect_to action: 'list'
  end

  def list
    if !params[:type].blank? && @basket_admin
      @listing_type = params[:type]
    else
      @listing_type = 'member'
    end

    @there_are_requested = 0
    @there_are_rejected = 0

    # list people who have all other roles
    # use (true) because the roles are cached when first run but
    # if we add roles (like moderator) this becomes problematic
    @current_basket.accepted_roles(true).each do |role|
      @there_are_requested += 1 if role.name == 'membership_requested'
      @there_are_rejected += 1 if role.name == 'membership_rejected'

      # skip this role if we're viewing members and the role is requested or rejected
      # next if (@listing_type == 'members' && (role.name == 'membership_requested' || role.name == 'membership_rejected'))
      # skip this role if we're viewing pending join requests and the role is something other than requested
      # next if (@listing_type == 'pending' && role.name != 'membership_requested')
      # skip this role if we're viewing rejected join requests and the role is something other than rejected
      # next if (@listing_type == 'rejected' && role.name != 'membership_rejected')

      role_plural = role.name.pluralize

      instance_variable_set("@#{role_plural}_count", @current_basket.send("has_#{role_plural}_count"))
    end

    @default_sorting = { order: 'roles_users.created_at', direction: 'desc' }
    acceptable_sort_types = ['users.resolved_name', 'roles_users.created_at', 'users.email']
    acceptable_sort_types << 'users.login' if @site_admin
    paginate_order = current_sorting_options(@default_sorting[:order], @default_sorting[:direction], acceptable_sort_types)

    # this sets up all instance variables
    # as well as preparing @members
    list_members_in(@listing_type, paginate_order)

    # turn on rss
    @rss_tag_auto = rss_tag(replace_page_with_rss: true)
    @rss_tag_link = rss_tag(replace_page_with_rss: true, auto_detect: false)
  end

  def list_members_in(role_name, order='users.login asc')
    @non_member_roles_plural = Hash.new
    @possible_roles = { 'admin' => t('members_controller.list_members_in.admin'),
      'moderator' => t('members_controller.list_members_in.moderator'),
      'member' => t('members_controller.list_members_in.member')
    }

    @admin_actions = Hash.new

    if @current_basket == @site_basket and site_admin?
      @possible_roles['tech_admin'] = t('members_controller.list_members_in.tech_admin')
      @possible_roles['site_admin'] = t('members_controller.list_members_in.site_admin')
      @admin_actions['become_user'] = t('members_controller.list_members_in.login_as')
      @admin_actions['destroy'] = t('members_controller.list_members_in.delete')
      @admin_actions['ban'] = t('members_controller.list_members_in.ban')
    else
      @admin_actions['remove'] = t('members_controller.list_members_in.remove')
    end

    # members are paginated
    # since we are paginating we need to break a part
    # what the @current_basket.has_members method would do
    @role = Role.where(name: role_name, authorizable_type: 'Basket', authorizable_id: @current_basket).first
    if @role.nil?
      # no members
      @members = User.paginate_by_id(0, page: 1)
    else
      not_anonymous_condition = "login != 'anonymous'"
      if params[:action] == 'rss'
        unless site_admin?
          @members = @role.users.where(not_anonymous_condition).order('roles_users.created_at desc').limit(50)
        else
          @members = @role.users.order('roles_users.created_at desc').limit(50)
        end

      else
        options = { include: :contributions, order: order, page: params[:page], per_page: 20 }
        options[:conditions] = not_anonymous_condition unless site_admin?

        @members = @role.users.paginate(options)
      end

      @all_roles = RolesUser.all(conditions: ['role_id = ? AND user_id IN (?)', @role, @members])
      @role_creations = Hash.new
      @members.each do |member|
        @role_creations[member.id] = @all_roles.reject { |r| r.user_id != member.id }.first.created_at
      end
    end
  end
  private :list_members_in

  def potential_new_members
    @existing_users = User.joins(:roles_users).where('roles_users.role_id in (?)', @current_basket.accepted_roles)

    # don't allow, at least for now, anonymous users to be added to other baskets
    # besides site
    # may change in the future if there is a use case
    @users_to_exclude = User.where(login: 'anonymous')
    @existing_users = @existing_users + @users_to_exclude

    @potential_new_members = Array.new
    unless params[:search_name].blank?
      @potential_new_members = User.where(
          'id not in (?) and login like ? or display_name like ?',
          @existing_users, '%'+params[:search_name]+'%', '%'+params[:search_name]+'%' )
    end
  end

  def join
    if !@basket_access_hash[@current_basket.urlified_name.to_sym].blank?
      flash[:error] = t('members_controller.join.already_joined')
    else
      case @current_basket.join_policy_with_inheritance
      when 'open'
        current_user.has_role('member', @current_basket)
        @current_basket.administrators.each do |admin|
          UserNotifier.join_notification_to(admin, current_user, @current_basket, 'joined').deliver
        end
        flash[:notice] = t('members_controller.join.joined', basket_name: @current_basket.name)
      when 'request'
        current_user.has_role('membership_requested', @current_basket)
        @current_basket.administrators.each do |admin|
          UserNotifier.join_notification_to(admin, current_user, @current_basket, 'request').deliver
        end
        flash[:notice] = t('members_controller.join.requested')
      else
        flash[:error] = t('members_controller.join.not_open')
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
          flash[:notice] = t('members_controller.change_membership_type.made_tech_admin')
        else
          flash[:notice] = t('members_controller.change_membership_type.cannot_be_tech_admin')
          can_change = false
        end
      end
      if can_change
        if clear_roles
          @current_basket.delete_roles_for(@user)
        end
        @user.has_role(membership_type, @current_basket)
        if flash[:notice].blank?
          flash[:notice] = t('members_controller.change_membership_type.changed_role')
        end
      end
    else
      flash[:notice] = t('members_controller.change_membership_type.need_site_admin')
    end
    redirect_to action: 'list'
  end

  # added so site admins can assume identities of users if necessary
  def become_user
    return unless request.post?

    # logout the old user first
    # stolen from account_controller.logout, should make DRY
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session

    # now login as new user
    self.current_user = User.find(params[:id])
    if logged_in?
      redirect_back_or_default(controller: '/account', action: 'index')
      flash[:notice] = t('members_controller.become_user.logged_in')
    end
  end

  def ban
    @user = User.find(params[:id])
    @user.banned_at = Time.now
    if @user.save
      flash[:notice] = t('members_controller.ban.banned')
      redirect_to action: 'list'
    end
  end

  def unban
    @user = User.find(params[:id])
    @user.banned_at = nil
    if @user.save
      flash[:notice] = t('members_controller.unban.unbanned')
      redirect_to action: 'list'
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

    if params[:user].size > 1
      flash[:notice] = t('members_controller.add_members.added_plural')
    else
      flash[:notice] = t('members_controller.add_members.added_singular')
    end

    redirect_to action: 'list'
  end

  # Remove is called from non-site baskets, only usable when
  #   the current basket isn't the site basket
  #   the basket has one other admin besides this user
  def remove
    @user ||= User.find(params[:id])

    # make sure we arn't trying to remove from site basket (destroy is the correct action for that)
    if @current_basket == @site_basket
      flash[:error] = t('members_controller.remove.cant_remove_self')

    # make sure that if the user is an admin, they aren't the last one
    elsif @user.has_role?('admin', @current_basket) && !@current_basket.more_than_one_basket_admin?
      flash[:error] = t('members_controller.remove.need_site_admin')

    # the user can be successfully removed, so lets do that
    else
      @current_basket.delete_roles_for(@user)
      flash[:notice] = t('members_controller.remove.removed', basket_name: @current_basket.name)
    end

    if current_user_can_see_memberlist_for?(@current_basket)
      redirect_location = { action: 'list' }
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
      flash[:error] = t('members_controller.destroy.has_contributions', user_name: @user.user_name)
    elsif !@site_basket.more_than_one_site_admin?
      flash[:error] = t('members_controller.destroy.need_site_admin')
    else
      @user.destroy
      flash[:notice] = t('members_controller.destroy.destroyed', user_name: @user.user_name)
    end
    redirect_to action: 'list'
  end

  def change_request_status
    @user = User.find(params[:id])
    @current_basket.delete_roles_for(@user)

    approved = (params[:status] && params[:status] == 'approved')
    if approved
      @user.has_role('member', @current_basket)
      flash[:notice] = t('members_controller.change_request_status.accepted', user_name: @user.user_name)
    else
      @user.has_role('membership_rejected', @current_basket)
      flash[:notice] = t('members_controller.change_request_status.rejected', user_name: @user.user_name)
    end

    UserNotifier.join_notification_to(@user, current_user, @current_basket, params[:status]).deliver
    redirect_to action: 'list'
  end

  def rss
    list_members_in('member')

    respond_to do |format|
      format.xml
    end
  end

  private

  def permitted_to_view_memberlist
    unless current_user_can_see_memberlist_for?(@current_basket)
      flash[:error] = t('members_controller.permitted_to_view_memberlist.not_authorized')
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end

  def permitted_to_remove_basket_members
    @user = User.find(params[:id])
    unless logged_in? && (permit?('site_admin or admin of :current_basket') || @current_user == @user)
      flash[:error] = t('members_controller.permitted_to_view_memberlist.cant_remove')
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end
end
