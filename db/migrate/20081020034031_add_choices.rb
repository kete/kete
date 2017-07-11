class AddChoices < ActiveRecord::Migration
  def self.up
    create_table 'choices' do |t|
      t.column 'label', :string
      t.column 'value', :string
      t.column 'parent_id', :integer, null: true, references: nil
      t.column 'lft', :integer
      t.column 'rgt', :integer
      t.column 'data', :string
    end

    create_table 'choice_mappings' do |t|
      t.column 'choice_id', :integer, references: nil
      t.column 'field_id', :integer, references: nil
      t.column 'field_type', :string
    end

    # Add ROOT choice for better_nested_set
    raise 'Choices already exist. Please truncate choice table before continuing.' \
      if Choice.count_by_sql('SELECT COUNT(*) FROM choices') > 0

    Choice.create!(label: 'ROOT', value: 'ROOT')

    change_column :extended_fields, :ftype, :string, limit: 15
    add_column :extended_fields, :user_choice_addition, :boolean
  end

  def self.down
    drop_table 'choices'
    drop_table 'choice_mappings'

    change_column :extended_fields, :ftype, :string, limit: 10
    remove_column :extended_fields, :user_choice_addition
  end
end
