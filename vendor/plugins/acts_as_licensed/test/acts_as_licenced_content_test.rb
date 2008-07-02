require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helper')
require File.join(File.dirname(__FILE__), 'fixtures/author')
require File.join(File.dirname(__FILE__), 'fixtures/document')

#require File.join(File.dirname(__FILE__), '../tasks/licenses.rake')
#require File.join(RAILS_ROOT, '/vendor/plugins/acts_as_licensed/tasks/licenses.rake')
#require File.expand_path(File.join(File.dirname(__FILE__), '../tasks/licenses.rake'))

class ActsAsLicencedContentTest < Test::Unit::TestCase

  def setup
    Author.create( { :name => 'I. M. Contributor' } ) # we only need one author
    should_load_nz_licenses
    should_load_au_licenses
  end

  #
  # RAKE TASKS (problem with including rake task file itself, so we'll just call the function used in the rake file
  #
  def should_load_nz_licenses
    assert_difference 'License.count', 4 do
      License.import_from_yaml('nz_default_creative_commons_licenses.yml', false)
    end
  end

  def should_load_au_licenses
    assert_difference 'License.count', 4 do
      License.import_from_yaml('au_default_creative_commons_licenses.yml', false)
    end
  end

  #
  # MODELS
  #
  def test_shouldnt_re_add_nz_licenses
    assert_no_difference 'License.count' do
      License.import_from_yaml('nz_default_creative_commons_licenses.yml', false)
    end
  end

  def test_should_find_available_licenses
    License.create( { :name => 'Not Available',
                      :description => 'This license is not available',
                      :url => 'http://nothere.com/',
                      :is_available => false,
                      :image_url => 'http://nothere.com/image.png',
                      :is_creative_commons => false,
                      :metadata => '<a rel="license" href="$$license_url$$"><img alt="$$license_title$$" style="border-width:0" src="$$license_image_url$$"/></a><br/><span xmlns:dc="http://purl.org/dc/elements/1.1/" href="http://purl.org/dc/dcmitype/Text" property="dc:title" rel="dc:type">$$title$$</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="$$attribute_work_to_url$$" property="cc:attributionName" rel="cc:attributionURL">$$attribute_work_to_name$$</a> is licensed under a <a rel="license" href="$$license_url$$">$$license_title$$</a>' } )
    assert_equal (License.count - 1), License.find_available.size
  end

  def test_should_get_name_for_title
    license = License.first
    assert_equal license.name, license.title
  end

  #
  # INSTANCE METHODS
  #
  def test_document_shouldnt_be_given_license
    assert_equal false, new_document.has_license?
  end

  def test_document_should_be_given_license
    doc = new_document
    doc.license_id = License.first.id
    doc.save
    assert_equal true, doc.has_license?
  end

  def test_document_should_be_given_license_only_once
    doc = new_document
    doc.license_id = License.first.id
    doc.save
    assert_raise RuntimeError, "You may not set license_id more than once" do
      doc.license_id = License.last.id
    end
  end

  def test_document_should_not_have_metadata
    doc = new_document
    assert_nil doc.license_metadata
  end

  def test_document_should_have_metadata
    license = License.create( { :name => 'Test',
                                :description => 'Test',
                                :url => 'http://www.example.com/',
                                :is_available => true,
                                :image_url => 'http://www.example.com/image.png',
                                :is_creative_commons => true,
                                :metadata => '<a rel="license" href="$$license_url$$"><img alt="$$license_title$$" style="border-width:0" src="$$license_image_url$$"/></a><br/><span xmlns:dc="http://purl.org/dc/elements/1.1/" href="http://purl.org/dc/dcmitype/Text" property="dc:title" rel="dc:type">$$title$$</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="$$attribute_work_to_url$$" property="cc:attributionName" rel="cc:attributionURL">$$attribute_work_to_name$$</a> is licensed under a <a rel="license" href="$$license_url$$">$$license_title$$</a>' } )
    doc = new_document
    doc.license_id = license.id
    doc.save
    metadata = doc.license_metadata
    shouldbe_metadata = '<a rel="license" href="http://www.example.com/"><img alt="Test" style="border-width:0" src="http://www.example.com/image.png"/></a><br/><span xmlns:dc="http://purl.org/dc/elements/1.1/" href="http://purl.org/dc/dcmitype/Text" property="dc:title" rel="dc:type">Document</span> by <a xmlns:cc="http://creativecommons.org/ns#" href="/site/account/show/4" property="cc:attributionName" rel="cc:attributionURL">I. M. Contributor</a> is licensed under a <a rel="license" href="http://www.example.com/">Test</a>'
    assert_not_nil metadata
    assert_equal shouldbe_metadata, metadata
  end

  #
  # ASSOCIATIONS
  #
  def test_document_should_have_license_assoc
    doc = new_document
    doc.license_id = License.first.id
    doc.save
    assert_kind_of License, doc.license
  end

  def test_license_should_have_document_assocs
    doc = new_document
    doc.license_id = License.first.id
    doc.save
    license = License.first
    assert_kind_of Document, license.documents.first
  end

  private

  def new_document(options = {})
    Document.create( { :title        => 'Document',
                       :author_id    => Author.first.id,
                       :license_id   => nil }.merge(options) )
  end
end
