class AddTechAdminRole < ActiveRecord::Migration
  def self.up
    if !Role.find_by_name('tech_admin')
      Role.create(:name => 'tech_admin', :authorizable_id => 1, :authorizable_type => 'Basket')
    end
  end

  def self.down
    Role.find_by_name_and_authorizable_id_and_authorizable_type('tech_admin', 1, 'Basket').destroy
  end
end
