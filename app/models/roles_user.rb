# frozen_string_literal: true

class RolesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
end
