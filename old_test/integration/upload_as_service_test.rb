require File.dirname(__FILE__) + '/integration_test_helper'

class UploadAsServiceTest < ActionController::IntegrationTest
  context "The uploading an item as a service functionality" do
    [StillImage, AudioRecording, Video, Document].each do |klass|
      context "as a normal user, when Javascript is off, when requesting new form for #{klass.name}" do
        setup do
          @controller_name = zoom_class_controller(klass.name)
          add_john_as_regular_user
          login_as('john')
        end

        def self.should_have_query_string_parameter_as_input(parameter_name)
          should "pass url query string parameter for #{parameter_name} as a hidden input if present" do
            new_url = new_url_stub + parameter_name

            value_string = String.new

            value_string = if parameter_name == 'service_target'
              '=a_test_url'
            else
              '=true'
                           end

            value_string += '&as_service=true' if parameter_name != 'as_service'

            new_url += value_string
            visit new_url

            body_should_contain parameter_name
          end
        end

        should "get a new form with minimal layout if url query string parameter for as_service is present" do
          visit new_url_stub + 'as_service=true'
          body_should_not_contain "this would be a good place for your logo"
          body_should_contain 'class="simple"'
        end

        %w(as_service service_target append_show_url).each do |parameter_name|
          should_have_query_string_parameter_as_input(parameter_name)
        end

        # should "redirect back to service_target while handling append_show_url properly" do
        # end
      end
    end
  end

  def new_url_stub
    "/site/#{@controller_name}/new?"
  end
end
