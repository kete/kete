require File.join(File.dirname(__FILE__), 'setup_test')

class ActsAsSanitizedTest < Test::Unit::TestCase  
  def test_field_specification
    e = Entry.new(:title => "Test entry",
                  :body => "Lorem ipsum etc. etc.",
                  :extended => "Yet more lorem ipsum...",
                  :person_id => 1)
                  
    assert_equal ["title", "body"], e.acts_as_sanitized_options[:fields]
  end
  
  def test_field_discovery
    c = Comment.new(:person_id => 1,
                    :title => "Test title",
                    :body => "Test body")
    
    assert_equal ["title", "body"], c.acts_as_sanitized_options[:fields]
  end
  
  def test_uncontaminated_model
    m = Message.new(:person_id => 1, :recipient_id => 2, :body => "Test body")
  
    assert_raise(NoMethodError) { m.acts_as_sanitized_options }
  end
  
  def test_sanitization_on_specified_fields
    e = Entry.new(:title => "<script>alert('xss in title')</script>",
                  :body => "<script>alert('xss in body')</script>",
                  :extended => "<script>alert('xss in extended')</script>",
                  :person_id => 1)
    e.save
    
    assert_not_equal "<script>alert('xss in title')</script>", e.title
    assert_equal "&lt;script>alert('xss in title')&lt;/script>", e.title
    
    assert_not_equal "<script>alert('xss in body')</script>", e.body
    assert_equal "&lt;script>alert('xss in body')&lt;/script>", e.body
    
    assert_equal "<script>alert('xss in extended')</script>", e.extended
  end
  
  def test_sanitization_on_discovered_fields
    c = Comment.new(:person_id => 1,
                    :title => "<script>alert('xss in title')</script>",
                    :body => "<script>alert('xss in body')</script>")
    c.save
                    
    assert_not_equal "<script>alert('xss in title')</script>", c.title
    assert_equal "&lt;script>alert('xss in title')&lt;/script>", c.title
    
    assert_not_equal "<script>alert('xss in body')</script>", c.body
    assert_equal "&lt;script>alert('xss in body')&lt;/script>", c.body              
  end
  
  def test_html_stripping_on_discovered_fields
    m = Person.new(:name => "<strong>Mallory</strong>")
    m.save
    
    assert m.acts_as_sanitized_options[:strip_tags]
    assert_not_equal "<strong>Mallory</strong>", m.name
    assert_equal "Mallory", m.name
  end
  
  def test_html_stripping_on_specified_fields
    r = Review.new(:title => "<script>alert('xss in title')</script>",
                   :body => "<script>alert('xss in body')</script>",
                   :extended => "<script>alert('xss in extended')</script>",
                   :person_id => 1)
    r.save
    
    assert_not_equal "<script>alert('xss in title')</script>", r.title
    assert_equal "alert('xss in title')", r.title
    
    assert_not_equal "<script>alert('xss in body')</script>", r.body
    assert_equal "alert('xss in body')", r.body
    
    assert_equal "<script>alert('xss in extended')</script>", r.extended
  end
end
