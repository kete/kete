require 'spec_helper'

describe 'Topic comments', js: true do
  let(:user)            { FactoryGirl.create(:user, :activated, :with_default_baskets) }
  let(:topic)           { FactoryGirl.create(:topic, creator: user)                    }
  let(:show_topic_path) { basket_topic_path(topic.basket.urlified_name, topic.id)      }

  def add_comment_to_topic(comment_attrs)
    visit show_topic_path
    click_on 'join this discussion'
    fill_in 'comment[title]', with: comment_attrs[:title]
    tinymce_fill_in 'comment_description', comment_attrs[:description]
    fill_in 'comment[tag_list]', with: 'clever, funny'
    click_on 'Save'
  end

  describe 'Access control' do
    describe 'An anonymous user' do
      it 'can view other users comments on a topic' do
        # given ...
        comment_attrs = FactoryGirl.attributes_for(:comment)

        # when a user creates a comment on a topic ...
        login(user)
        add_comment_to_topic(comment_attrs)

        # and then logs out ...
        click_on 'Logout'

        # when an anonymous user views the topic ...
        visit show_topic_path

        # then ...
        expect(page).to have_content('There are 1 comments in this discussion')
        expect(page).to have_content(comment_attrs[:title])
        expect(page).to have_link('Reply')
      end
    end

    describe 'An ordinary user' do
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
        add_comment_to_topic(comment)

        # then ...
        expect(page).to have_content(comment[:title])
        expect(page).to have_content(comment[:description])
        expect(page).to have_link('clever')
        expect(page).to have_link('funny')
      end

      it 'can reply to a comment on a topic' do
        # given ...
        comment_attrs = FactoryGirl.attributes_for(:comment)
        reply_attrs = FactoryGirl.attributes_for(:comment, title: 'A reply', description: 'A pithy reply')

        # when ...
        login(user)
        add_comment_to_topic(comment_attrs)

        expect(page).to have_content('There are 1 comments in this discussion')

        click_on 'Reply'
        fill_in 'comment[title]', with: reply_attrs[:title]
        tinymce_fill_in 'comment_description', reply_attrs[:description]
        click_on 'Save'

        # then ...
        expect(page).to have_content(reply_attrs[:title])
        expect(page).to have_content(reply_attrs[:description])
        expect(page).to have_content('There are 2 comments in this discussion')
      end

      it 'cannot edit a comment they create' do
        # given some comment attributes ...
        comment_attrs = FactoryGirl.attributes_for(:comment)

        # when the user logs in and creates a comment ...
        login(user)
        add_comment_to_topic(comment_attrs)

        # then there is no visible 'Edit' link.
        expect(page.find('.comment-tools')).not_to have_link('Edit')
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

    describe 'An admin' do
      let(:privileged_user) do
        FactoryGirl.create(:user, :activated, :with_site_admin_role, :with_default_baskets)
      end

      it 'can add a comment to a topic' do
        # given some comment attributes ...
        comment = FactoryGirl.attributes_for(:comment)

        # when an admin logs in and creates a comment ...
        login(privileged_user)
        add_comment_to_topic(comment)

        # then it should save and be displayed to them ...
        expect(page).to have_content(comment[:title])
        expect(page).to have_content(comment[:description])
        expect(page).to have_link('clever')
        expect(page).to have_link('funny')
      end

      it 'can delete their own comment' do
        # given ...
        comment_attrs = FactoryGirl.attributes_for(:comment)

        # when ...
        login(privileged_user)
        add_comment_to_topic(comment_attrs)

        within('.comment-tools') do
          click_on 'Delete'
        end

        # accept the confirmation alert dialog that rails shows
        accept_confirm_dialog

        # then ...
        expect(page).to have_content('There are 0 comments in this discussion')
      end

      it 'can edit comments created by a different user' do
        # given some comment attributes ...
        comment_attrs = FactoryGirl.attributes_for(:comment)
        ordinary_user = FactoryGirl.create(:user, :activated, :with_default_baskets)
        new_title = 'I am checking my privilege'

        # when an ordinary user logs in and creates a comment and logs out...
        login(ordinary_user)
        add_comment_to_topic(comment_attrs)
        click_on 'Logout'

        # and then the privileged user logs in ...
        login(privileged_user)

        visit show_topic_path
        within('.comment-tools') do
          click_on 'Edit'
        end
        fill_in 'comment[title]', with: new_title
        click_on 'Save'

        # then ...
        expect(page).to have_content(new_title)
      end

      it 'can delete comments created by a different user' do
        # given ...
        comment_attrs = FactoryGirl.attributes_for(:comment)

        # when ...
        login(user)
        add_comment_to_topic(comment_attrs)

        click_on 'Logout'

        login(privileged_user)
        visit show_topic_path
        within('.comment-tools') do
          click_on 'Delete'
        end
        accept_confirm_dialog

        # then ...
        expect(page).to have_content('There are 0 comments in this discussion')
      end
    end
  end

  describe 'Deleting comments' do
    let(:site_admin) { FactoryGirl.create(:user, :activated, :with_default_baskets, :with_site_admin_role) }

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

      # then ...
      expect(page).to have_content(grandparent_attrs[:title])
      expect(page).to have_content(grandparent_attrs[:description])
      expect(page).to have_content(child_attrs[:title])
      expect(page).to have_content(child_attrs[:description])
    end

    it 'deleting a parent comment also deletes the children' do
      # given ...
      parent_attrs = FactoryGirl.attributes_for(:comment)
      child_attrs = FactoryGirl.attributes_for(:comment)

      # when we create a topic ...
      login(site_admin)
      visit show_topic_path

      # .. and then create a parent comment ...
      click_on 'join this discussion'
      fill_in 'comment[title]', with: parent_attrs[:title]
      tinymce_fill_in 'comment_description', parent_attrs[:description]
      click_on 'Save'

      # ... and then create a child comment ...
      first('.comment-depth-0').find('.comment-tools').find_link('Reply').click
      fill_in 'comment[title]', with: child_attrs[:title]
      tinymce_fill_in 'comment_description', child_attrs[:description]
      click_on 'Save'

      # ... and then delete the child comment.
      first('.comment-depth-0').find('.comment-tools').find_link('Delete').click
      accept_confirm_dialog

      # then ...
      expect(page).to have_content('There are 0 comments in this discussion')
      expect(page).not_to have_content(parent_attrs[:title])
      expect(page).not_to have_content(parent_attrs[:description])
      expect(page).not_to have_content(child_attrs[:title])
      expect(page).not_to have_content(child_attrs[:description])
    end
  end
end
