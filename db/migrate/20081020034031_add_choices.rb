class AddChoices < ActiveRecord::Migration
  def self.up
    
    create_table 'choices' do |t|
      t.column 'label', :string
      t.column 'value', :string
    end
    
    create_table 'choice_mappings' do |t|
      t.column 'choice_id', :integer, :references => nil
      t.column 'field_id', :integer, :references => nil
      t.column 'field_type', :string
    end
    
  end

  def self.down
    
    drop_table 'choices'
    drop_table 'choice_mappings'
    
  end
end
