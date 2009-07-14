module KeteTestFunctionalHelper
  unless included_modules.include? KeteTestFunctionalHelper

    def self.included(klass)
      klass.send :include, AuthenticatedTestHelper
      klass.send :include, KeteTestFunctionalHelper::TestHelper
    end

    module TestHelper
      private

      #
      # Setup some variables for use in functional tests
      #

      def load_test_environment
        @request.host = SITE_NAME
      end

      #
      # Setup a few path conveniance methods
      #

      def index_path(attributes = {})
        { :urlified_name => 'site', :controller => @base_class.tableize, :action => 'index' }.merge(attributes)
      end

      def show_path(attributes = {})
        { :urlified_name => 'site', :controller => @base_class.tableize, :action => 'show', :id => 1 }.merge(attributes)
      end

      def new_path(attributes = {})
        { :urlified_name => 'site', :controller => @base_class.tableize, :action => 'new' }.merge(attributes)
      end

      def create_record(attributes = {}, location = {})
        attributes_name = @assignment_var || @base_class.underscore
        assert_difference("#{@base_class}.count") do
          eval("post :create, { :#{attributes_name} => @new_model.merge(attributes), :urlified_name => 'site', :controller => @base_class.tableize }.merge(location)")
        end
      end

      def edit_path(attributes = {})
        { :urlified_name => 'site', :controller => @base_class.tableize, :action => 'edit', :id => 1 }.merge(attributes)
      end

      def update_record(attributes = {}, location = {})
        attributes_name = @assignment_var || @base_class.underscore
        assert_no_difference("#{@base_class}.count") do
          eval("post :update, { :#{attributes_name} => @updated_model.merge(attributes), :urlified_name => 'site', :controller => @base_class.tableize, :id => 1 }.merge(location)")
        end
      end

      def destroy_record(location = {})
        assert_difference("#{@base_class}.count", -1) do
          eval("post :destroy, { :urlified_name => 'site', :controller => @base_class.tableize, :id => 1 }.merge(location)")
        end
      end

      #
      # Setup a few assertion conveniance methods
      #

      def assert_viewing_template(template)
        assert_response :success
        assert_template template
      end

      def assert_redirect_to(location)
        assert_response :redirect
        assert_redirected_to location
      end

      def assert_var_assigned(plural = false)
        var = @assignment_var || @base_class
        var = plural ? var.tableize : var.underscore
        assert_not_nil assigns(var.to_sym)
      end

      def assert_attributes_same_as(should_be, plural = false)
        var = @assignment_var || @base_class
        var = plural ? var.tableize : var.underscore
        should_be.each do |key, value|
          assert_equal value, eval("assigns(:#{var}).#{key}")
        end
      end
    end

  end
end
