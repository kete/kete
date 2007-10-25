# Copyright (c) 2006 Keith Morrison (keithm@infused.org)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module TestInjector
  
  def base_class
    @base_class ||= Module.const_get self.to_s.gsub(/Test$/, '')
  end
  
  def inject_activerecord_tests
    if base_class.ancestors.include?(ActiveRecord::Base)
      inject_association_tests if base_class.respond_to?(:reflections)
      define_acts_as_versioned_test(base_class) if base_class.respond_to?("acts_as_versioned") and base_class.include?(ActiveRecord::Acts::Versioned::ActMethods)      
      define_optimistic_locking_test(base_class) if base_class.column_names.include?("lock_version")
    end
  end
  
  def inject_association_tests
    ignore_associations = [:versions, :parent, :children]
    collectible_associations = [:has_many, :has_and_belongs_to_many]
    
    base_class.reflect_on_all_associations.each do |association|
      
      # redefine base_class as an instance method
      define_method "base_class" do
        @base_class ||= Module.const_get self.class.to_s.gsub(/Test$/, '')
      end
      
      unless ignore_associations.include?(association.name)
        define_fixture_test(association)
        define_association_test(association)
      end

    end

  end
  
  def define_association_test(association)
    collectible_associations = [:has_many, :has_and_belongs_to_many]
    association_name = association.options[:through] ? "#{association.name}_through_#{association.options[:through]}" : association.name
    remove_method "test_#{association.macro}_#{association_name}" rescue
    define_method "test_#{association.macro}_#{association_name}" do
      associated_model = eval(association.class_name)
      model_instance = base_class.find(:first)
      
      # tests for associations that return a collection of objects
      if collectible_associations.include?(association.macro)
        assert_kind_of Array, model_instance.send(association.name), "#{base_class}##{association.name} expected an array of #{association.class_name}'s"
        assert_kind_of associated_model, model_instance.send(association.name).first, 
          "#{base_class}##{association.name} was expected to be a #{association.class_name}. If the result is a NilClass, verify your fixtures."
        if [:destroy, :delete_all].include?(association.options[:dependent])
          association_count = model_instance.send(association.name).size
          associated_record_count = associated_model.count
          assert model_instance.destroy
          assert_equal associated_record_count - association_count, associated_model.count, 
            "Unexpected result when calling #{association.options[:dependent]} on dependent association :#{association.name}"
        elsif association.options[:dependent] == :nullify
          associated_record_ids = model_instance.send(association.name).map {|r| r.id}
          assert model_instance.destroy
          associated_record_ids.each  {|the_id| assert [0,'0',nil].include?(associated_model.find(the_id).send(association.primary_key_name))}
        end
      
      # tests for associations the return a single object
      else
        assert_kind_of associated_model, model_instance.send(association.name), 
          "#{base_class}##{association.name} was expected to be a #{association.class_name}. If the result is a NilClass, verify your fixtures."
        if [:destroy, :delete].include?(association.options[:dependent])
          dependent_id = model_instance.send(association.name).id
          assert model_instance.destroy
          assert_raises(ActiveRecord::RecordNotFound) {associated_model.find(dependent_id)}
        end
      end
      
    end
  end
  # This test will run for any ActiveRecord model.  For each association defined in the model being tested (:belongs_to, :has_many, etc),
  # the test checks to see if a fixture corresponding to the associated model is included in the fixture list.
  def define_fixture_test(association)
    fixture_name = eval(association.class_name).table_name
    define_method "test_fixture_defined_for_#{fixture_name}" do
      assert respond_to?(association.options[:join_table]), "No fixture defined for :#{association.options[:join_table]}" if association.options[:join_table]
      assert respond_to?(fixture_name), "No fixture defined for :#{fixture_name}"
    end
  end
  
  
  # This test will run for any ActiveRecord model that uses the acts_as_versioned plugin. Versioning may fail if the versioned table is 
  # not set up correctly.  Including this test insures that versioning is set up correctly and is working as expected.
  def define_acts_as_versioned_test(base_class)
    define_method "test_acts_as_versioned" do
      model = base_class.find(:first)
      assert_equal 0, model.version
      assert model.save
      assert model.reload
      assert_equal 1, model.version
      assert_equal model.version, model.versions.size
    end
  end
  
  # This test will run for any ActiveRecord model that has a lock_version column. Optimistic locking may fail if the lock_version 
  # column is set to "not null" or does not have a default value.  Including this test insures that the lock_version column is set
  # up correctly.
  def define_optimistic_locking_test(base)
    define_method "test_optimistic_locking" do
      column = base.columns_hash['lock_version']
      assert_equal :integer, column.type, "lock_version column type should be :integer"
      assert_equal 0, column.default, "lock_version column default should be 0"
    end
  end
  
end