class CreateUserPortraitRelations < ActiveRecord::Migration
  def self.up
    create_table :user_portrait_relations do |t|
      t.integer :position, :user_id, :still_image_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_portrait_relations
  end
end
