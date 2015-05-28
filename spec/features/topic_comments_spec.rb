require 'spec_helper'

feature 'Topic comments', js: true do
  let(:user) { FactoryGirl.create(:user, :activated, :with_default_baskets) }
  let(:topic) { FactoryGirl.create(:topic, creator: user) }
  let(:show_topic_path) { basket_topic_path(topic.basket.urlified_name, topic.id) }

  describe 'A logged in user' do
    it 'can view comments on a topic' do
      # given ...

      # when ...
      login(user)
      visit show_topic_path

      # then ...
      expect(page).to have_content('There are 0 comments in this discussion')
    end

    it 'can add a comment to a topic' do
      # given ...
      comment = FactoryGirl.attributes_for(:comment)

      # when ...
      login(user)
      visit show_topic_path
      click_on 'join this discussion'
      fill_in 'comment[title]', with: comment[:title]
      tinymce_fill_in 'comment_description', comment[:description]
      fill_in 'comment[tag_list]', with: 'clever, funny'
      click_on 'Save'

      # then ...
      expect(page).to have_content(comment[:title])
      expect(page).to have_content(comment[:description])
      expect(page).to have_link('clever')
      expect(page).to have_link('funny')
    end

    it 'can reply to a comment on a topic' do
      # given ...
      comment = FactoryGirl.attributes_for(:comment)
      reply = FactoryGirl.attributes_for(:comment, title: 'A reply', description: 'A pithy reply')

      # when ...
      login(user)
      visit show_topic_path
      click_on 'join this discussion'
      fill_in 'comment[title]', with: comment[:title]
      tinymce_fill_in 'comment_description', comment[:description]
      click_on 'Save'

      expect(page).to have_content('There are 1 comments in this discussion')

      click_on 'Reply'
      fill_in 'comment[title]', with: reply[:title]
      tinymce_fill_in 'comment_description', reply[:description]
      click_on 'Save'

      # then ...
      expect(page).to have_content(reply[:title])
      expect(page).to have_content(reply[:description])
      expect(page).to have_content('There are 2 comments in this discussion')
    end

    it 'can cancel a comment before saving it' do
      # given ...

      # when ...
      login(user)
      visit show_topic_path
      click_on 'join this discussion'
      click_on 'cancel'

      expect(current_path).to eq(show_topic_path)
    end
  end

  describe 'A site-admin user' do
    let(:site_admin) { FactoryGirl.create(:user, :activated, :with_default_baskets, :with_site_admin_role) }

    it 'a site admin can delete their own comment after saving it' do
      # given ...
      comment = FactoryGirl.attributes_for(:comment)

      # when ...
      login(site_admin)
      visit show_topic_path
      click_on 'join this discussion'
      fill_in 'comment[title]', with: comment[:title]
      tinymce_fill_in 'comment_description', comment[:description]
      click_on 'Save'

      within('.comment-tools') do
        click_on 'Delete'
      end

      # accept the confirmation alert dialog that rails shows
      accept_confirm_dialog

      # then ...
      expect(page).to have_content('There are 0 comments in this discussion')
    end

    it 'can delete comments created by a different user' do
      # given ...
      comment_attrs = FactoryGirl.attributes_for(:comment)

      # when ...
      login(user)
      visit show_topic_path
      click_on 'join this discussion'
      fill_in 'comment[title]', with: comment_attrs[:title]
      tinymce_fill_in 'comment_description', comment_attrs[:description]
      fill_in 'comment[tag_list]', with: 'clever, funny'
      click_on 'Save'

      click_on 'Logout'

      login(site_admin)
      visit show_topic_path
      within('.comment-tools') do
        click_on 'Delete'
      end
      accept_confirm_dialog

      # then ...
      expect(page).to have_content('There are 0 comments in this discussion')
    end

    it 'deleting a parent comment attaches children to the grandparent comment' do
      # given ...
      grandparent_attrs = FactoryGirl.attributes_for(:comment)
      parent_attrs = FactoryGirl.attributes_for(:comment)
      child_attrs = FactoryGirl.attributes_for(:comment)

      # when we create a topic ...
      login(site_admin)
      visit show_topic_path

      # .. and then create a grandparent comment ...
      click_on 'join this discussion'
      fill_in 'comment[title]', with: grandparent_attrs[:title]
      tinymce_fill_in 'comment_description', grandparent_attrs[:description]
      click_on 'Save'

      # ... and then create a parent comment ...
      first('.comment-depth-0').find('.comment-tools').find_link('Reply').click
      fill_in 'comment[title]', with: parent_attrs[:title]
      tinymce_fill_in 'comment_description', parent_attrs[:description]
      click_on 'Save'

      # ... and then create a child comment ...
      first('.comment-depth-1').find('.comment-tools').find_link('Reply').click
      fill_in 'comment[title]', with: child_attrs[:title]
      tinymce_fill_in 'comment_description', child_attrs[:description]
      click_on 'Save'

      # ... and then delete the parent comment.
      first('.comment-depth-1').find('.comment-tools').find_link('Delete').click
      accept_confirm_dialog

      # # then ...
      expect(page).to have_content(grandparent_attrs[:title])
      expect(page).to have_content(grandparent_attrs[:description])
      expect(page).to have_content(child_attrs[:title])
      expect(page).to have_content(child_attrs[:description])
    end
  end
end
