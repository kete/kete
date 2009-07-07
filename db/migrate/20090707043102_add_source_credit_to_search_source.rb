class AddSourceCreditToSearchSource < ActiveRecord::Migration
  def self.up
    add_column :search_sources, :source_credit, :text
  end

  def self.down
    remove_column :search_sources, :source_credit
  end
end
