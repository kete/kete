# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_many :user_roles
  has_many :users, :through => :user_roles

  def self.user_role_for(user, name, authorizable_id)
    self.find_by_name_and_authorizable_id(name, authorizable_id).user_roles.find_by_user_id(user)
  end

  belongs_to :authorizable, :polymorphic => true
end
