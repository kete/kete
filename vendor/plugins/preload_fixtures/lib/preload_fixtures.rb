# PreloadFixtures

require "active_record/fixtures"

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:    
      # def initialize_with_fixtures(*args)
      #   puts "Initializing test case: #{self.class}"
      #   @loaded_fixtures = LOADED_GLOBAL_FIXTURES
      #   puts "Loaded_fixtures: DIM1-#{@loaded_fixtures.length} DIM2-#{@loaded_fixtures.first.length} DIM3-#{@loaded_fixtures.first.first.length}"
      #   puts "Loaded_fixtures: DIM1-#{@loaded_fixtures.first.inspect} DIM2-#{@loaded_fixtures.first.first.inspect} DIM3-#{@loaded_fixtures.first.first.first.inspect}"
      #   initialize_without_fixtures(*args)
      # end
      # 
      # alias_method_chain :initialize, :fixtures
       
      def self.fixtures_with_disable(*table_names)
        # do nothing sucker!!
      end
      
      class << self
        alias_method_chain :fixtures, :disable
      end

      # def self.already_loaded_fixtures
      #   @@already_loaded_fixtures
      # end
      # 
      # def self.already_loaded_fixtures=(newfix)
      #   @@already_loaded_fixtures = newfix
      # end
      # 
      # def self.inherited(newclass)
      #   newclass.already_loaded_fixtures[newclass] = LOADED_GLOBAL_FIXTURES
      # end
      
      def use_transactional_fixtures?
        true
      end
      
      def use_transactional_fixtures
        true
      end

      def use_instantiated_fixtures
        false
      end
      
      def pre_loaded_fixtures
        true
      end
    end
  end
end

module PreloadFixtures
  def self.preload!
    puts "PRELOADING FIXTURES..."

    require 'active_record/fixtures'
    ActiveRecord::Base.establish_connection(:test)
    (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|
      Fixtures.create_fixtures(File.join(RAILS_ROOT, 'test', 'fixtures'), File.basename(fixture_file, '.*'))
    end      
    puts "DONE. Loaded #{Fixtures.all_loaded_fixtures.keys.length} fixtures."
  end
  
  def self.instantiate!(object)
    puts "INSTANTIATING FIXTURES..."
    Fixtures.instantiate_all_loaded_fixtures(object)
    #Test::Unit::TestCase.setup_fixture_accessors(Fixtures.all_loaded_fixtures.keys)
    Fixtures.all_loaded_fixtures.each do |table_name,values|
      #puts "Defining method #{table_name}"
      Test::Unit::TestCase.send(:define_method, table_name) do |fixture, *optionals|
        @fixture_cachez ||= {}
        #puts "Accessing fixture cache for #{table_name}[#{fixture}]..."
        #puts "#{values[fixture.to_s].inspect}"
        #puts "Cached value: #{@fixture_cachez[table_name].inspect}"
        @fixture_cachez[table_name] ||= {}
        if values[fixture.to_s]
          @fixture_cachez[table_name][fixture.to_s] ||= values[fixture.to_s].find
        else
          raise StandardError, "No fixture with name '#{fixture}' found for table '#{table_name}'"
        end
      end
    end
    #puts Test::Unit::TestCase.public_instance_methods.sort.inspect
    # Fixtures.all_loaded_fixtures.each do |k,v|      
    #   Test::Unit::TestCase.class_eval "
    #     def #{k}(*args)
    #       Test::Unit::TestCase.(:#{k})
    #     end
    #   "
    # end
    puts "DONE. Instantiated #{Fixtures.all_loaded_fixtures.keys.length} fixtures."
  end
end