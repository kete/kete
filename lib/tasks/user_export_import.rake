# lib/tasks/user_export_import.rake
#
# export/import users data and roles
#
# Kieran Pilkington, 2008-08-15
#
namespace :kete do
  namespace :export do
    desc 'Export the Users table to a Yaml formatted file'
    task :users => :environment do
      yaml = ""
      User.all.each do |user|
        next if user.login == 'admin'
        yaml += "#{user.login}:\n"
        yaml += "  fields:\n"
        user.attributes.each do |field, value|
          next if field == 'id' or field.empty?
          if field == 'extended_content'
            yaml += "    #{field}: |\n      #{value}\n"
          else
            yaml += "    #{field}: #{value}\n"
          end
        end
        yaml += "  roles:\n"
        user.roles.each do |role|
          next unless role.authorizable_type == "Basket"
          yaml += "    #{role.id}:\n"
          basket = Basket.find_by_id(role.authorizable_id)
          yaml += "      basket: #{basket.urlified_name}\n"
          yaml += "      name: #{role.name}\n"  
        end
      end
      write_to_file('users.yml', yaml)
      p "All users exported to RAILS_ROOT/tmp/users.yml"
    end
  end

  namespace :import do
    desc 'Import the Users table from a Yaml formatted file'
    task :users => :environment do
      users = read_from_file('users.yml')
      users.each do |user|
        user_data = user.last['fields'].merge({"agree_to_terms" => '1', "security_code" => "bleh"})
        if User.count(:conditions => ["login = ?", user_data['login']]) > 0
          p "#{user_data['login']} already exists"
          next
        else
          new_user = User.create!(user_data)
          user.last['roles'].each do |role|
            basket = Basket.find_by_urlified_name(role.last['basket'])
            next if !basket
            new_user.has_role(role.last['name'], basket)
          end
          p "Added User #{user_data['login']}"
        end
      end
      p "All users imported from RAILS_ROOT/tmp/users.yml"
    end
  end
  
  private
  
  def read_from_file(filename)
    if !File.exists?("#{RAILS_ROOT}/tmp/#{filename}")
      p "ERROR: Could not find RAILS_ROOT/tmp/#{filename}"; exit
    end
    YAML.load_file("#{RAILS_ROOT}/tmp/#{filename}")
  end

  def write_to_file(filename, contents)
    fout = File.open("#{RAILS_ROOT}/tmp/#{filename}", "w")
    fout.puts contents
    fout.close
  end
end