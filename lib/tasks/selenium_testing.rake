namespace :test do
  Rake::TestTask.new(:selenium => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/selenium/test_cases/**/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test:selenium'].comment = "Run the selenium tests in test/selenium/test_cases"
end