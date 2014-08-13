require 'spec_helper'

feature "User login" do

  def username
    "eoinkelly"
  end

  def password
    "iDHVrBKH2QeH"
  end

  def sign_in
    visit "/"
    within(".user-nav") do
      click_link('Login')
    end

    within("form#login") do
      fill_in "Login", with: username
      fill_in "Password", with: password
      click_button "Login"
    end
  end

  it "A site admin can login" do
    sign_in
    expect(page).to have_text("Logged in successfully")
  end

  describe "As a logged in site admin" do

    it "can logout" do
      sign_in
      click_link "Logout"
      expect(page).to have_text("You have been logged out.")
    end

    it "can see their account overview page" do
      sign_in
      click_link username
      expect(page).to have_text("Profile of #{username}")
    end

    it "can view the list of members" do
      sign_in
      click_link "Members"
      # expect(page.status_code).to be(200)
      expect(page).to have_text("Site Members")
    end
  end
end

