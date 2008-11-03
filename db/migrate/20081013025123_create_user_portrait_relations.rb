class CreateUserPortraitRelations < ActiveRecord::Migration
  def self.up
    create_table :user_portrait_relations do |t|
      t.integer :position
      t.integer :user_id
      t.integer :still_image_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_portrait_relations
  end
end
