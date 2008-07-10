require File.join(File.dirname(__FILE__), 'test_helper')

# simply test whether acts_as_versioned is installed in this app
class AttachmentFuTest < Test::Unit::TestCase
  # TODO: not quite right, creates an error rather than a failed test right now
  # if attachment_fu is uninstalled
  # but has the same effect, so skipping fixing for now
  def test_has_attachment_fu
    has_attachment_fu = true
    begin
      require 'technoweenie/attachment_fu'
    rescue
      has_attachment_fu = false
    end
    assert_equal true, has_attachment_fu, "convert_attachment_to needs to have attachment_fu plugin installed."
  end
end

