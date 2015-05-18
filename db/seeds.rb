def load_yaml(file: nil, model: nil, unique_attr: nil)

  # Don't be so noisy when we are in the test environment
  be_quiet = Rails.env.test?

  puts "  Creating #{model}(s) ..." unless be_quiet

  yaml_file = File.join(Rails.root, 'db', 'yaml', file)
  yaml_data = YAML::load_file(yaml_file)

  fail "Failed to load YAML from #{yaml_file}" unless yaml_data

  finder_method_name = "find_or_create_by_#{unique_attr}".to_sym

  yaml_data.each do |attrs|
    instance = model.send finder_method_name, attrs

    unless instance.kind_of?(ActiveRecord::Base) && instance.valid?
      # We choose to die if we encounter any error because it is safer than
      # letting you think your seeding worked
      fail "Failed to create valid instance of #{model}. Errors are: #{instance.errors.messages}"
    end

    # allow our caller to customise the model before we move on
    yield instance if block_given?

    puts "   * #{instance.send(unique_attr)}" unless be_quiet
  end
end

puts "Loading seeds ... "

load_yaml(file: 'users.yml',        model: User,       unique_attr: :email)
load_yaml(file: 'baskets.yml',      model: Basket,     unique_attr: :name)
load_yaml(file: 'topics.yml',       model: Topic,      unique_attr: :title)
load_yaml(file: 'topic_types.yml',  model: TopicType,  unique_attr: :name)
load_yaml(file: 'content_types.yml',  model: ContentType,  unique_attr: :class_name)
load_yaml(file: 'licenses.yml',  model: License,  unique_attr: :name)

puts "done."
