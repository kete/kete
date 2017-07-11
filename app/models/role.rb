# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_many :roles_users
  has_many :users, through: :roles_users

  def self.user_role_for(user, name, authorizable_id, options = {})
    # this method will be called multiple times on the members page, so make sure the
    # role query is only run once by caching it to a role named instance variable
    class_eval("@#{name}_role ||= self.find_by_name_and_authorizable_id(name, authorizable_id, :select => 'id')")
    class_eval("@role = @#{name}_role")
    RolesUser.find_by_role_id_and_user_id(@role, user, options)
  end

  belongs_to :authorizable, polymorphic: true
end
