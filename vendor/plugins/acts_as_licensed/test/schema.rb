ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define :version => 0 do
  
  create_table :licenses, :force => true do |t|
    t.column :name, :string, :null => false
    t.column :description, :string, :null => false
    t.column :url, :string, :null => false
    t.column :is_available, :boolean, :null => false
    t.column :image_url, :string, :null => false
    t.column :is_creative_commons, :boolean, :null => false
    t.column :metadata, :text, :null => true
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
  end
	
  create_table :documents, :force => true do |t|
    t.column :title, :string, :null => false
    t.column :author_id, :string, :null => false
    t.column :license_id, :integer
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
  end

  create_table :authors, :force => true do |t|
    t.column :name, :string, :null => false
    t.column :created_at, :datetime, :null => false
    t.column :updated_at, :datetime, :null => false
  end
  
end

ActiveRecord::Migration.verbose = true
