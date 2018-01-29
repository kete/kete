# James Stradling <james@katipo.co.nz>
# 2008-04-15

module ItemPrivacyTestHelper
  module Model
    # Normally, testing attachment_fu methods will cause real files to be written into your
    # development and production environment file folders, as defined in the models.
    # To work around this, this override forces the files to be saved into the
    # tmp/attachment_fu_test/.. folder instead of RAILS_ROOT/..

    # Based on work-around described here http://www.fngtps.com/2007/04/testing-with-attachment_fu
    def full_filename(thumbnail = nil)
      file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:path_prefix].to_s.gsub('public', '')
      File.join(RAILS_ROOT, 'tmp', 'attachment_fu_test', attachment_path_prefix, file_system_path, *partitioned_path(thumbnail_name_for(thumbnail)))
    end
  end

  module TestHelper
    # Generate a regex for us to test against to ensure the files are saved in the correct place.
    # Use this in your tests.
    def attachment_fu_test_path(base_folder, sub_folder)
      /^[a-zA-Z0-9\/\-_\s\.]+\/#{base_folder}\/#{sub_folder}\/[a-zA-Z0-9\/\-_\s\.]+$/
    end

    private

    # Generate a new record for a test
    # Returns the ID of the new record.
    def create_record(attributes = {}, user = :admin)
      login_as(user)
      eval("post :create, :#{@base_class.singularize.downcase} => @new_model.merge(attributes), :urlified_name => 'site'")

      # Reload the test environment.
      load_test_environment

      eval("#{@base_class.classify}.find(:first, :order => 'id DESC').id")
    end

    def load_test_environment
      @controller = eval("#{@base_class.classify.pluralize}Controller.new")
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end
  end

  module Tests
    module FilePrivate
      def test_attachment_fu_uses_correct_path_prefix
        item = eval(@base_class).create(@new_model.merge(file_private: false))
        assert_match(attachment_fu_test_path('public', @uploads_folder), item.full_filename)
        assert File.exist?(item.full_filename)
        assert item.valid?
      end

      def test_attachment_fu_uses_correct_path_prefix2
        item2 = eval(@base_class).create(@new_model.merge(file_private: true))
        assert_match(attachment_fu_test_path('private', @uploads_folder), item2.full_filename)
        assert File.exist?(item2.full_filename)
        assert item2.valid?
      end

      def test_attachment_fu_does_not_move_files_when_going_from_public_to_private
        item = eval(@base_class).create(@new_model.merge(file_private: false))
        assert_match(attachment_fu_test_path('public', @uploads_folder), item.full_filename)
        assert File.exist?(item.full_filename)
        assert item.valid?
        old_filename = item.full_filename
        id = item.id

        item = eval(@base_class).find(id)
        item.update_attributes(file_private: true)
        assert_match(attachment_fu_test_path('public', @uploads_folder), item.full_filename)
        assert File.exist?(item.full_filename), "File is not where we expected. Should be at #{item.full_filename} but is not present."
        assert_equal old_filename, item.full_filename
        assert item.valid?
      end

      def test_attachment_fu_moves_files_to_correct_path_when_going_from_private_to_public
        item = eval(@base_class).create(@new_model.merge(file_private: true))
        assert_match(attachment_fu_test_path('private', @uploads_folder), item.full_filename)
        assert File.exist?(item.full_filename)
        assert item.valid?
        old_filename = item.full_filename
        id = item.id

        item = eval(@base_class).find(id)
        item.update_attributes(file_private: false)
        assert_match(attachment_fu_test_path('public', @uploads_folder), item.full_filename)
        assert File.exist?(item.full_filename), "File is not where we expected. Should be at #{item.full_filename} but is not present."
        assert !File.exist?(old_filename), "File is not where we expected. Should NOT be at #{old_filename} but IS present."
        assert item.valid?
      end

      def test_attachment_path_prefix
        d = eval(@base_class).create(@new_model.merge(file_private: true))
        assert_equal d.send(:attachment_path_prefix), 'private'

        d = eval(@base_class).create(@new_model.merge(file_private: false))
        assert_equal d.send(:attachment_path_prefix), 'public'
      end

      def test_attachment_full_filename
        d = eval(@base_class).create(@new_model.merge(file_private: true))
        assert_equal File.join(RAILS_ROOT, 'tmp', 'attachment_fu_test', 'private', @uploads_folder, *d.send(:partitioned_path, d.send(:thumbnail_name_for, nil))), d.full_filename

        d = eval(@base_class).create(@new_model.merge(file_private: false))
        assert_equal File.join(RAILS_ROOT, 'tmp', 'attachment_fu_test', 'public', @uploads_folder, *d.send(:partitioned_path, d.send(:thumbnail_name_for, nil))), d.full_filename
      end

      def test_file_private_setter_false_to_true_does_not_work
        d = eval(@base_class).create(@new_model.merge(file_private: false))
        d.file_private = true
        assert d.save

        assert !d.file_private?
      end

      def create_user_with_permission(role, basket_instance)
        raise 'Unknown role' unless
          ['member', 'moderator', 'administrator', 'site_admin', 'tech_admin'].member?(role)

        user = User.create(
          login: 'quire',
          email: 'quire@example.com',
          password: 'quire',
          password_confirmation: 'quire',
          agree_to_terms: '1',
          security_code: 'test',
          security_code_confirmation: 'test',
          locale: 'en'
        )
        basket_instance.accepts_role(role, user)

        assert user.has_role?(role, basket_instance)
      end

      def test_create_user_with_permission
        create_user_with_permission('member', Basket.find(:first))
      end
    end

    module VersioningAndModeration
      def test_responds_to_private_and_is_set_properly_with_private_false
        doc = eval(@base_class).create(@new_model.merge(private: false))
        assert_equal false, doc.private?
      end

      def test_responds_to_private_and_is_set_properly_with_private_true
        doc = eval(@base_class).create(@new_model.merge(private: true))
        assert_equal false, doc.private?
        assert_equal 2, doc.versions.size
        assert_equal true, doc.versions.find_by_version(1).private?
        assert_equal false, doc.versions.find_by_version(2).private?
      end

      def test_latest_version
        # Set up some versions
        d = eval(@base_class).create(@new_model.merge(private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3')
        d.update_attributes(description: 'Version 4', private: true)
        d.update_attributes(description: 'Version 5', private: true)

        d.reload

        assert_equal 3, d.send(:latest_public_version).version
        assert_equal d.version, d.send(:latest_public_version).version
        assert_equal 'Version 3', d.send(:latest_public_version).description
        assert !d.send(:latest_public_version).private?
        assert !d.private?
      end

      def test_revert_to
        # Set up some versions
        d = eval(@base_class).create(@new_model.merge(private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3')
        d.update_attributes(description: 'Version 4', private: true)
        d.update_attributes(description: 'Version 5')

        d.reload

        d.revert_to(d.versions.find_by_version(3))

        assert_equal d.version, 3
        assert_equal d.description, 'Version 3'
        assert !d.private?
      end

      def test_private_version_newest_public
        # Set up some versions
        d = eval(@base_class).create(@new_model.merge(private: false))
        d.update_attributes!(description: 'Version 2')
        d.update_attributes!(description: 'Version 3')
        d.update_attributes!(description: 'Version 4', private: true)
        d.update_attributes!(description: 'Version 5', private: false)
        d.reload

        assert_not_nil d.private_version_serialized
        assert_kind_of Array, YAML.load(d.private_version_serialized)
        assert_equal 5, d.versions.size
        assert_equal 'Version 5', d.description
        assert_equal false, d.private?

        d.private_version!
        assert_equal 'Version 4', d.description
        assert_equal true, d.private?
      end

      def test_private_version_newest_private
        # Set up some versions
        d = eval(@base_class).create(@new_model.merge(private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3')
        d.update_attributes(description: 'Version 4')
        d.update_attributes(description: 'Version 5', private: true)
        d.reload

        assert_equal 'Version 4', d.description
        assert_equal false, d.private?
        assert_equal 4, d.version
        d.send(:private_version!)
        assert_equal 'Version 5', d.description
        assert_equal true, d.private?
        assert_equal 5, d.version
      end

      def test_private_version_returns_nil_when_no_private_version!
        d = eval(@base_class).create(@new_model.merge(private: false))
        d.update_attributes(description: 'Version 2')
        d.reload

        assert_equal 'Version 2', d.description
        assert_equal nil, d.private_version!
      end

      def test_store_correct_version_after_save
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2', private: true)
        d.reload

        assert_equal 'Version 1', d.description
        assert_not_nil d.private_version_serialized
      end

      def test_has_private_version!
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2')

        assert_equal false, d.has_private_version?
        assert_nil d.private_version!
      end

      def test_has_private_version2
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2', private: true)
        d.update_attributes(description: 'Version 3')

        assert_not_nil d.private_version_serialized
        assert_kind_of Array, YAML.load(d.private_version_serialized)
        assert_equal true, d.has_private_version?
        assert_nothing_raised do
          d = d.send :load_private!
        end
        assert_not_nil d
      end

      def test_latest_public_version_and_has_public_version
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2', private: true)
        d.update_attributes(description: 'Version 3')

        assert_equal 3, d.send(:latest_public_version).version
        assert_equal true, d.has_private_version?
      end

      def test_latest_public_version_and_has_public_version_again
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3', private: true)

        assert_equal 2, d.send(:latest_public_version).version
        assert_equal true, d.has_private_version?
      end

      def test_latest_public_version_and_has_public_version_with_none
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true))
        d.update_attributes(description: 'Version 2', private: true)
        d.update_attributes(description: 'Version 3', private: true)
        d.reload

        assert_equal 4, d.versions.size
        assert_not_nil d
        assert_kind_of eval(@base_class), d
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal SystemSetting.no_public_version_description, d.description
        assert_equal true, d.has_private_version?
      end

      def test_revert_to_latest_unflagged_version_or_create_new_version_public
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3', private: true)

        # Check flagging a public version works as expected
        assert_equal 2, d.version
        assert_equal 0, d.tags.size
        d.flag_live_version_with('PENDING', 'Pending')
        assert_equal 1, d.versions.find_by_version(2).tags.size
        assert_equal 1, d.version
        assert_equal false, d.private?
        assert d.versions.reject { |v| v.version == 2 }.all? { |v| v.tags.size == 0 }
      end

      def test_revert_to_latest_unflagged_version_or_create_new_version_private
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3', private: true)
        d.reload
        assert_equal 2, d.version

        # Check pre-conditions
        d.private_version!
        assert_equal 3, d.version

        # Check tagging tags the correct item
        assert_equal 0, d.tags.size

        # Flat the version and run the callback that we expect to be run..
        d.flag_live_version_with('PENDING', 'Pending')
        d.send :store_correct_versions_after_save

        assert_equal 1, d.versions.find_by_version(3).tags.size
        assert d.versions.reject { |v| v.version == 3 }.all? { |v| v.tags.size == 0 }

        d.private_version do
          assert_equal 4, d.version
          assert_equal true, d.private?
        end

        d = eval(@base_class).find(d.id)
        assert_equal 2, d.version
        assert_equal false, d.private?
      end

      def test_reload_returns_model_to_public_version
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2', private: true)
        d.reload

        assert_equal false, d.private?
        assert_equal 1, d.version
        assert_equal 'Version 1', d.description

        d.private_version!

        assert_equal true, d.private?
        assert_equal 2, d.version
        assert_equal 'Version 2', d.description

        d.reload

        assert_equal false, d.private?
        assert_equal 1, d.version
        assert_equal 'Version 1', d.description
      end

      def test_new_private_item_with_moderated_basket
        # Set up
        d = eval(@base_class).new(@new_model.merge(description: 'Version 1', private: true))
        d.instance_eval do
          def fully_moderated?
            true
          end
        end
        d.save!
        d.reload

        assert_equal true, d.fully_moderated?

        # Should be three, 1 for private, 1 for public and 1 for pending blank private..
        assert_equal 3, d.versions.size

        assert_equal 1, d.versions.find_by_version(1).tags.size
        assert_equal 'test item', d.versions.find_by_version(1).title
        assert_equal 'Version 1', d.versions.find_by_version(1).description
        assert_equal true, d.versions.find_by_version(1).private?

        assert_equal 0, d.versions.find_by_version(2).tags.size
        assert_equal SystemSetting.blank_title, d.versions.find_by_version(2).title
        assert_equal nil, d.versions.find_by_version(2).description
        assert_equal true, d.versions.find_by_version(2).private?

        assert_equal 0, d.versions.find_by_version(3).tags.size
        assert_equal SystemSetting.no_public_version_title, d.versions.find_by_version(3).title
        assert_equal SystemSetting.no_public_version_description, d.versions.find_by_version(3).description
        assert_equal false, d.versions.find_by_version(3).private?

        assert_equal 3, d.version
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal SystemSetting.no_public_version_description, d.description

        d.private_version!

        assert_equal 2, d.version
        assert_equal SystemSetting.blank_title, d.title
        assert_equal nil, d.description
      end

      def test_new_public_item_with_moderated_basket
        # Set up
        d = eval(@base_class).new(@new_model.merge(description: 'Version 1', private: false))
        d.instance_eval do
          def fully_moderated?
            true
          end
        end
        d.save!
        d.reload

        assert_equal true, d.fully_moderated?

        # Should be three, 1 for private, 1 for public and 1 for pending blank private..
        assert_equal 2, d.versions.size

        assert_equal 1, d.versions.find_by_version(1).tags.size
        assert_equal 'test item', d.versions.find_by_version(1).title
        assert_equal 'Version 1', d.versions.find_by_version(1).description
        assert_equal false, d.versions.find_by_version(1).private?

        assert_equal 0, d.versions.find_by_version(2).tags.size
        assert_equal SystemSetting.blank_title, d.versions.find_by_version(2).title
        assert_equal nil, d.versions.find_by_version(2).description
        assert_equal false, d.versions.find_by_version(2).private?

        assert_equal 2, d.version
        assert_equal SystemSetting.blank_title, d.title
        assert_equal nil, d.description

        assert_nil d.private_version!

        assert_equal 2, d.version
        assert_equal SystemSetting.blank_title, d.title
        assert_equal nil, d.description
      end

      def test_moderated_public_item
        # Set up
        d = new_moderated_public_item

        assert_equal true, d.fully_moderated?

        # Should be three, 1 for private, 1 for public and 1 for pending blank private..
        assert_equal 3, d.versions.size

        version1 = d.versions.find_by_version(1)
        assert_equal 1, version1.tags.size
        assert_equal 'Version 1', version1.title
        assert_equal 'Version 1', version1.description
        assert_equal false, version1.private?

        version2 = d.versions.find_by_version(2)
        assert_equal 0, version2.tags.size
        assert_equal SystemSetting.blank_title, version2.title
        assert_equal nil, version2.description
        assert_equal false, version2.private?

        assert_equal 3, d.version
        assert_equal 'Version 3', d.title
        assert_equal 'Version 3', d.description
        assert_equal false, d.private?

        assert_nil d.private_version!
      end

      def test_new_version_of_moderated_public_item
        d = new_moderated_public_item
        # this will save as version 4
        # (but because basket is moderated, result will revert to public version 3)
        d.update_attributes!(title: 'Version 4', description: 'Version 4')

        assert_equal 4, d.versions.size
        assert_equal 3, d.version
        assert_equal 'Version 3', d.description

        assert_equal 1, d.versions.find_by_version(4).tags.size
        assert_equal 'Version 4', d.versions.find_by_version(4).description
      end

      def test_new_private_version_of_moderated_public_item
        d = new_moderated_public_item
        # this will save as version 4
        # (but because basket is moderated, result will revert to public version 3)
        d.update_attributes!(title: 'Version 4', description: 'Version 4', private: true)

        assert_equal 5, d.versions.size

        assert_equal 3, d.version
        assert_equal 'Version 3', d.description

        assert_equal 1, d.versions.find_by_version(4).tags.size
        assert_equal 'Version 4', d.versions.find_by_version(4).description

        assert_equal SystemSetting.blank_title, d.versions.find_by_version(5).title
        assert_equal nil, d.versions.find_by_version(5).description
      end

      def test_private_version_with_block
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false))
        d.update_attributes(description: 'Version 2')
        d.update_attributes(description: 'Version 3', private: true)
        d.reload
        assert_equal 2, d.version

        d.private_version do
          assert_equal true, d.private?
          assert_equal 3, d.version
        end

        assert_equal false, d.private?
        assert_equal 2, d.version
      end
    end

    module TaggingWithPrivacyContext
      def test_class_responds_to_class_methods_as_expected
        klass = eval(@base_class)

        should_respond_to = %i[
          tag_counts
          private_tag_counts
          public_tag_counts
        ]

        should_respond_to.each do |method|
          assert_respond_to klass, method
        end
      end

      def test_class_tag_counts_accepts_an_required_argument_and_one_optional_one
        assert_equal -2, eval(@base_class).method(:tag_counts).arity
      end

      def test_instances_respond_to_instance_methods_as_expected
        instance = eval(@base_class).create(@new_model)

        should_respond_to = %i[
          tags
          tag_list
          tag_list=
          public_tags
          public_tags=
          public_tag_list
          public_tag_list=
          private_tags
          private_tags=
          private_tag_list
          private_tag_list=
        ]

        should_respond_to.each do |method|
          assert_respond_to instance, method
        end
      end

      def test_tags_are_preserved_on_public_items
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))
        d.reload

        assert_equal 1, d.versions.size
        assert_equal 'Version 1', d.description
        assert_equal 3, d.tags.size
        assert %w{one two three}.all? { |t| d.tags.map { |g| g.name }.member?(t) }
        assert_equal d.tags.sort_by(&:id), d.public_tags.sort_by(&:id)
        assert d.private_tags.empty?
      end

      def test_tags_are_preserved_on_private_items
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))

        assert_equal 0, d.tags.size

        d.private_version do
          assert_equal true, d.private?
          assert_equal 3, d.tags.size
          assert_equal 'Version 1', d.description
          assert %w{one two three}.all? { |t| d.tags.map { |v| v.name }.member?(t) }
          assert_equal d.tags, d.private_tags
          assert d.public_tags.empty?
        end
      end

      def test_tags_on_private_items_are_kept_private
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))
        d.reload

        # Check there are no tags on public version
        assert_equal false, d.private?
        assert_equal 2, d.versions.size
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal 0, d.tags.size

        # Topic#raw_tag_list is set in the controllers, so cannot be tested here.
        # assert_equal nil, d.raw_tag_list

        # Check the original tags are present on the private version
        d.private_version do
          assert_equal true, d.private?

          # Topic#raw_tag_list is set in the controllers, so cannot be tested here.
          # assert_equal "one, two, three", d.raw_tag_list

          assert_equal 3, d.tags.size
          assert_equal 'Version 1', d.description
          assert %w{one two three}.all? { |t| d.tags.collect { |tag| tag.name }.member?(t) }
        end

        # Check there are no tags on public version upon restoration
        assert_equal false, d.private?
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal 0, d.tags.size

        # Topic#raw_tag_list is set in the controllers, so cannot be tested here.
        # assert_equal nil, d.raw_tag_list
      end

      def test_tags_on_private_items_are_kept_private_on_re_find
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))

        d = eval(@base_class).find(d.id)

        # Check there are no tags on public version
        assert_equal false, d.private?
        assert_equal 2, d.versions.size
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal 0, d.tags.size
        # assert_equal nil, d.raw_tag_list

        # Check the original tags are present on the private version
        d.private_version do
          assert_equal true, d.private?
          # assert_equal "one, two, three", d.raw_tag_list
          assert_equal 3, d.tags.size
          assert_equal 'Version 1', d.description
          assert %w{one two three}.all? { |t| d.tags.collect { |tag| tag.name }.member?(t) }
        end

        # Check there are no tags on public version upon restoration
        assert_equal false, d.private?
        assert_equal SystemSetting.no_public_version_title, d.title
        assert_equal 0, d.tags.size
        # assert_equal nil, d.raw_tag_list
      end

      def test_tags_are_preserved_separately_by_privacy_setting
        # Create a private version
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))
        d.reload

        # Create a public version with different tags
        d.update_attributes!(private: false, title: 'A public version', description: 'Version 3', tag_list: 'four, five, six', raw_tag_list: 'four, five, six')

        # Create a second private version without tags
        d.private_version!
        d.update_attributes!(private: true, title: 'Another private version', description: 'Version 4')

        # Check the public version has tags from public version
        assert_equal false, d.private?
        assert_equal 3, d.tags.size
        # assert_equal "four, five, six", d.raw_tag_list
        assert_equal 'four, five, six', d.tags.collect { |t| t.name }.join(', ')

        # Check the private version has tags from the private version
        d.private_version!
        assert_equal true, d.private?
        assert_equal 3, d.tags.size
        # assert_equal "one, two, three", d.raw_tag_list
        assert_equal 'one, two, three', d.tags.collect { |t| t.name }.join(', ')

        # Check the public tags present on natural version
        e = eval(@base_class).find(d.id)
        assert_equal false, e.private?
        assert_equal 3, e.tags.size
        # assert_equal "four, five, six", e.raw_tag_list
        assert_equal 'four, five, six', e.tags.collect { |t| t.name }.join(', ')
      end

      def test_tags_on_private_items_are_of_private_context
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: true, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))
        d.reload

        d.private_version!

        assert_equal true, d.private?
        assert_equal d.tags, d.private_tags
        assert_equal 3, d.tags.size
        assert_equal 'one, two, three', d.tags.collect { |t| t.name }.join(', ')
        assert d.public_tags.empty?
      end

      def test_tags_on_public_items_are_of_public_context
        d = eval(@base_class).create(@new_model.merge(description: 'Version 1', private: false, tag_list: 'one, two, three', raw_tag_list: 'one, two, three'))
        d.reload

        assert_equal false, d.private?
        assert_equal d.tags.sort_by(&:id), d.public_tags.sort_by(&:id)
        assert_equal 3, d.tags.size
        assert_equal 'one, two, three', d.tags.collect { |t| t.name }.join(', ')
        assert d.private_tags.empty?
      end

      protected

      def new_moderated_public_item
        d = eval(@base_class).new(@new_model.merge(title: 'Version 1', description: 'Version 1', private: false))
        d.instance_eval do
          def fully_moderated?
            true
          end
        end
        # this will save the above as version 1
        # then make a 'Pending Moderation' as version 2
        d.save!
        d.reload

        d.strip_flags_and_mark_reviewed(1)
        d.revert_to(1)
        d.title = 'Version 3'
        d.description = 'Version 3'
        d.version_comment = 'Content from revision # 1.'
        d.do_not_moderate = true
        # this will save the above as version 3
        # (and will be the current public version)
        d.save!
        d.reload
        d.do_not_moderate = false
        d
      end
    end

    module MovingItemsBetweenBasketsWithDifferentPrivacies
      def test_moving_public_item_to_public_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: false, basket: @new_either_basket))
        @new_topic.update_attributes(basket: @new_public_basket)
        assert_equal @new_public_basket, @new_topic.basket
        assert !@new_topic.has_private_version?
      end

      def test_moving_private_item_to_public_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: true, basket: @new_either_basket))
        assert @new_topic.has_private_version?
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_either_basket, @new_topic.basket
        @new_topic.update_attributes(basket: @new_public_basket)
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_public_basket, @new_topic.basket
      end

      def test_moving_public_item_to_private_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: false, basket: @new_either_basket))
        @new_topic.update_attributes(basket: @new_private_basket)
        assert_equal @new_private_basket, @new_topic.basket
        assert !@new_topic.has_private_version?
      end

      def test_moving_private_item_to_private_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: true, basket: @new_either_basket))
        assert @new_topic.has_private_version?
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_either_basket, @new_topic.basket
        @new_topic.update_attributes(basket: @new_private_basket)
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_private_basket, @new_topic.basket
      end

      def test_not_moving_public_item_to_new_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: false, basket: @new_either_basket))
        @old_basket = @new_topic.basket
        @new_topic.update_attributes(description: 'hey')
        assert_equal @old_basket, @new_topic.basket
        assert !@new_topic.has_private_version?
      end

      def test_not_moving_private_item_to_new_basket
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: true, basket: @new_either_basket))
        assert @new_topic.has_private_version?
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_either_basket, @new_topic.basket
        @new_topic.update_attributes(description: 'hey')
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_either_basket, @new_topic.basket
      end

      def test_moving_public_version_updates_private_version_basket_id
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: false, basket: @new_either_basket))
        @new_topic.update_attributes(private: true, description: 'hey')
        assert @new_topic.has_private_version?
        @new_topic.update_attributes(basket: @new_private_basket)
        assert_equal @new_private_basket, @new_topic.basket
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_private_basket, @new_topic.basket
      end

      def test_moving_private_version_updates_public_version_basket_id
        setup_new_baskets
        @new_topic = @base_class.constantize.create(@new_model.merge(private: false, basket: @new_either_basket))
        @new_topic.update_attributes(private: true, description: 'hey')
        assert @new_topic.has_private_version?
        @new_topic.private_version!
        assert @new_topic.is_private?
        @new_topic.update_attributes(basket: @new_private_basket)
        assert_equal @new_private_basket, @new_topic.basket
        @new_topic.private_version!
        assert @new_topic.is_private?
        assert_equal @new_private_basket, @new_topic.basket
      end

      private

      def setup_new_baskets
        @new_either_basket = Basket.create(name: 'Either Basket', show_privacy_controls: true, private_default: false)
        @new_public_basket = Basket.create(name: 'Public Basket', show_privacy_controls: false, private_default: false)
        @new_private_basket = Basket.create(name: 'Private Basket', show_privacy_controls: true, private_default: true)
      end
    end
  end
end
