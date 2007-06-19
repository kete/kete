class AddPreferenceColumnsToBaskets < ActiveRecord::Migration
  def self.up
    add_column :baskets, :index_page_redirect_to_all, :string
    add_column :baskets, :index_page_topic_is_entire_page, :boolean, :default => false
    add_column :baskets, :index_page_link_to_index_topic_as, :string
    add_column :baskets, :index_page_basket_search, :boolean, :default => true
    add_column :baskets, :index_page_image_as, :string
    add_column :baskets, :index_page_tags_as, :string
    add_column :baskets, :index_page_number_of_tags, :integer, :default => 0
    add_column :baskets, :index_page_order_tags_by, :string, :default => 'number'
    add_column :baskets, :index_page_recent_topics_as, :string
    add_column :baskets, :index_page_number_of_recent_topics, :integer, :default => 0
    add_column :baskets, :index_page_archives_as, :string
    add_column :baskets, :index_page_extra_side_bar_html, :text
  end

  def self.down
    remove_column :baskets, :index_page_redirect_to_all
    remove_column :baskets, :index_page_topic_is_entire_page
    remove_column :baskets, :index_page_link_to_index_topic_as
    remove_column :baskets, :index_page_basket_search
    remove_column :baskets, :index_page_image_as
    remove_column :baskets, :index_page_tags_as
    remove_column :baskets, :index_page_number_of_tags
    remove_column :baskets, :index_page_order_tags_by
    remove_column :baskets, :index_page_recent_topics_as
    remove_column :baskets, :index_page_number_of_recent_topics
    remove_column :baskets, :index_page_archives_as
    remove_column :baskets, :index_page_extra_side_bar_html
  end
end
