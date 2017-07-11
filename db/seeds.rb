# We want to be able to run `rake db:seed` to be idempotent (doesn't matter how
# many times we run it after first run)

def load_yaml(file: nil, model: nil, unique_attrs: nil)
  fail 'unique_attrs must be an array' unless unique_attrs.is_a?(Array)

  yaml_file = File.join(Rails.root, 'db', 'yaml', file)
  yaml_data = YAML.load_file(yaml_file)
  fail "Failed to load YAML from #{yaml_file}" unless yaml_data

  finder_method_name = "find_or_create_by_#{unique_attrs.join('_and_')}".to_sym

  log "  Before: #{model.count} #{model}(s) ..."

  yaml_data.each do |attrs|
    instance = model.send(finder_method_name, attrs)

    unless instance.is_a?(ActiveRecord::Base) && instance.valid?
      # We choose to die if we encounter any error because it is safer than
      # letting you think your seeding worked
      fail "Failed to create valid instance of #{model}. Errors: #{instance.errors.messages}"
    end

    # caller can customise model in block
    yield instance if block_given?
  end

  log "  After: #{model.count} #{model}(s) ..."
end

def log(message)
  puts message unless Rails.env.test?
end

log 'Loading seeds ...'

load_yaml(file: 'roles.yml',
          model: Role,
          unique_attrs: [:id])

load_yaml(file: 'users.yml', model: User, unique_attrs: [:email]) do |user|
  # activate admin after create
  user.activate if user.login == 'admin'
end

load_yaml(file: 'roles_users.yml',
          model: RolesUser,
          unique_attrs: [:user_id, :role_id])

load_yaml(file: 'baskets.yml',
          model: Basket,
          unique_attrs: [:name])

load_yaml(file: 'topics.yml',
          model: Topic,
          unique_attrs: [:title])

load_yaml(file: 'topic_types.yml',
          model: TopicType,
          unique_attrs: [:name])

load_yaml(file: 'content_types.yml',
          model: ContentType,
          unique_attrs: [:class_name])

load_yaml(file: 'licenses.yml',
          model: License,
          unique_attrs: [:name])

log 'done.'
