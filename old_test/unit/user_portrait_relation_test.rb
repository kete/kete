require File.dirname(__FILE__) + '/../test_helper'

class UserPortraitRelationTest < ActiveSupport::TestCase
  def test_relation_should_belong_to_user
    new_image_with_creator
    assert_not_nil @relation.user
    assert_kind_of User, @relation.user
    assert_equal User.first, @relation.user
  end

  def test_relation_should_belong_to_still_image
    new_image_with_creator
    assert_not_nil @relation.still_image
    assert_kind_of StillImage, @relation.still_image
    assert_equal StillImage.last, @relation.still_image
  end

  def test_should_prohibit_any_action_when_uploader_isnt_current_user
    new_image_with_creator
    @user2 = User.create(:login => 'test')
    assert_equal false, UserPortraitRelation.new_portrait_for(@user2, @still_image)
    assert_equal false, UserPortraitRelation.remove_portrait_for(@user2, @still_image)
    assert_equal false, UserPortraitRelation.make_portrait_selected_for(@user2, @still_image)
  end

  def test_portrait_only_added_when_not_already_used
    new_image_with_creator(false)
    assert_nil @still_image.portrayed_user
    creation_relation_between_user_and_still_image
    assert_not_nil @still_image.portrayed_user
  end

  def test_remove_portrait_for_user
    new_image_with_creator
    assert_not_nil @still_image.portrayed_user
    UserPortraitRelation.remove_portrait_for(@user, @still_image)
    @still_image.reload
    assert_nil @still_image.portrayed_user
  end

  def test_make_portrait_a_default
    new_image_with_creator
    assert_equal 1, @relation.position
    new_image_with_creator
    assert_equal 2, @relation.position
    UserPortraitRelation.make_portrait_selected_for(@user, @still_image)
    @relation.reload
    assert_equal 1, @relation.position
  end

  private

    def new_image_with_creator(make_relation=true)
      @user = User.first
      @still_image = StillImage.create(:title => 'test item',
                                       :basket_id => Basket.find(:first))
      @still_image.creator = @user
      @still_image.save
      creation_relation_between_user_and_still_image if make_relation
    end

    def creation_relation_between_user_and_still_image
      UserPortraitRelation.new_portrait_for(@user, @still_image)
      @relation = UserPortraitRelation.last
      @user.reload
      @still_image.reload
    end
end
