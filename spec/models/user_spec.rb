# frozen_string_literal: true

require 'spec_helper'

describe User do
  let(:default_password) { 'quirk' }
  let(:user) do
    User.create(
      login: 'user_2',
      email: 'user_2@example.com',
      password: default_password,
      password_confirmation: default_password,
      agree_to_terms: '1',
      security_code: 'test',
      security_code_confirmation: 'test',
      locale: 'en',
      resolved_name: 'John Doe'
    )
  end
  let(:activated_user) do
    user.activate
    user
  end

  it 'can be authenticated with valid data' do
    expect(User.authenticate(activated_user.login, default_password)).to eq(activated_user)
  end

  it 'can reset password' do
    newpass = 'hellothere'
    activated_user.password = newpass
    activated_user.password_confirmation = newpass
    activated_user.save!

    expect(User.authenticate(activated_user.login, newpass)).to eq(activated_user)
  end

  it 'can have roles added' do
    site_admin_role = Role.where(name: 'site_admin').first
    user.roles << site_admin_role
    expect(user.roles).to eq([site_admin_role])
  end
end
