require File.dirname(__FILE__) + '/integration_test_helper'

class TopMenuContactLinkTest < ActionController::IntegrationTest
  @original_contact_email = CONTACT_EMAIL
  @original_contact_url = CONTACT_URL

  context "The Contact link" do
    setup do
      configure_environment do
        set_constant :CONTACT_EMAIL, "test@test.com"
        set_constant :CONTACT_URL, ""
      end
    end

    context "when Contact Email is set, but Contact URL is not set" do
      should "be a mailto link to the designated email address" do
        visit "/"
        # hex encoded version of mailto
        body_should_contain "&#109;&#97;&#105;&#108;&#116;&#111;&#58;"
        # encoded version of test@test.com
        body_should_contain "%74%65%73%74@%74%65%73%74.%63%6f%6d"
      end
    end

    context "when Contact URL is set" do
      setup do
        configure_environment do
          set_constant :CONTACT_URL, "http://example.com/contact-test-url"
        end
      end

      should "be an href link to the designated URL" do
        visit "/"
        body_should_contain "http://example.com/contact-test-url"
        # hex encoded version of mailto
        body_should_not_contain "&#109;&#97;&#105;&#108;&#116;&#111;&#58;"
        # hex encoded version of test@test.com
        body_should_not_contain "%74%65%73%74@%74%65%73%74.%63%6f%6d"
      end
    end

    teardown do
      configure_environment do
        set_constant :CONTACT_EMAIL, @original_contact_email
        set_constant :CONTACT_URL, @original_contact_url
      end
    end
  end
end
