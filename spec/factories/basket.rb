FactoryGirl.define do
  factory :basket do
    sequence :name do |n| "Basket name #{n}" end
    urlified_name 'site'
    index_page_basket_search '0'
    index_page_archives_as 'by type'
    private_default false
    file_private_default false
    allow_non_member_comments true
    show_privacy_controls false
    status 'approved'
    creator_id 1
  end
end
