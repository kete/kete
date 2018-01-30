module HasContributors
  # this is where we handle contributed and created items by users
  unless included_modules.include? HasContributors
    # declarations
    def self.included(klass)
      klass.send :has_many, :contributions, as: :contributed_item, dependent: :destroy
      # :select => "distinct contributions.role, users.*",
      # creator is intended to be just one, but we need :through functionality
      klass.send :has_many, :creators, through: :contributions,
                                       source: :user,
                                       conditions: "contributions.contributor_role = 'creator'",
                                       order: 'contributions.created_at' do
        def <<(user)

          user.version = 1
          Contribution.add_as_to(user, 'creator', self)
        rescue
          logger.debug('what is contrib error: ' + $!.to_s)

        end
      end
      klass.send :has_many, :contributors, through: :contributions,
                                           source: :user,
                                           select: 'contributions.version, contributions.created_at as version_created_at, users.*',
                                           conditions: "contributions.contributor_role = 'contributor'",
                                           order: 'contributions.created_at' do
        def <<(user)
          # TODO: assumes user has a version method (virtual attribute on user set before this is called)

          Contribution.add_as_to(user, 'contributor', self)
        rescue
          logger.debug('what is contrib error: ' + $!.to_s)

        end
      end
    end

    # method definitions
    def add_as_contributor(user, version = nil)
      user.version = version.nil? ? self.version : version
      contributors << user
    end

    def creator=(user)
      creators << user
      if user.present? && user.anonymous?
        contribution = contributions.find_by_version(1)
        contribution.email_for_anonymous = user.email
        contribution.name_for_anonymous = user.display_name if user.display_name
        contribution.website_for_anonymous = user.website if user.website
        contribution.save
      end
    end

    def creator
      creator = creators.first

      if creator.present? && creator.anonymous?
        contribution =  contributions.find_by_version(1)
        creator.email = contribution.email_for_anonymous
        creator.resolved_name = contribution.name_for_anonymous if contribution.name_for_anonymous
        creator.website = contribution.website_for_anonymous if contribution.website_for_anonymous
      end
      creator
    end

    def submitter_of(version)
      submitter = nil
      if version == 1
        submitter = creator
      else
        contribution = contributions.find_by_version(version)
        begin
          submitter = contribution.user
        rescue
          # catch the ugly error message and display something nicer
          message = I18n.t('has_contributors_lib.submitter_of.no_contributor',
                           version: version.to_s,
                           item_class: self.class.name,
                           item_id: id) + "\n"
          message += I18n.t('has_contributors_lib.submitter_of.data_corruption')
          raise message
        end
      end
      submitter
    end
  end
end
