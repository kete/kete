module HasContributors
  # this is where we handle contributed and created items by users
  unless included_modules.include? HasContributors
    # declarations
    def self.included(klass)
      klass.send :has_many, :contributions, :as => :contributed_item, :dependent => :destroy
      # :select => "distinct contributions.role, users.*",
      # creator is intended to be just one, but we need :through functionality
      klass.send :has_many, :creators, :through => :contributions,
      :source => :user,
      :conditions => "contributions.contributor_role = 'creator'",
      :order => 'contributions.created_at' do
        def <<(user)
          begin
            user.version = 1
            Contribution.add_as_to(user, 'creator', self)
          rescue
            logger.debug("what is contrib error: " + $!.to_s)
          end
        end
      end
      klass.send :has_many, :contributors, :through => :contributions,
      :source => :user,
      :select => "contributions.version, contributions.created_at as version_created_at, users.*",
      :conditions => "contributions.contributor_role = 'contributor'",
      :order => 'contributions.created_at' do
        def <<(user)
          # TODO: assumes user has a version method (virtual attribute on user set before this is called)
          begin
            Contribution.add_as_to(user, 'contributor', self)
          rescue
            logger.debug("what is contrib error: " + $!.to_s)
          end
        end
      end
    end
    # method definitions
    def add_as_contributor(user, version = nil)
      user.version = version.nil? ? self.version : version
      logger.debug("Adding contributor to version #{user.version} of item #{self.id}")
      self.contributors << user
    end

    def creator=(user)
      self.creators << user
    end

    def creator
      creators.first
    end

    def submitter_of(version)
      submitter = nil
      if version == 1
        submitter = self.creator
      else
        contribution = self.contributions.find_by_version(version)
        begin
          submitter = contribution.user
        rescue
          # catch the ugly error message and display something nicer
          message = I18n.t('has_contributors_lib.submitter_of.no_contributor',
                           :version => version.to_s,
                           :item_class => self.class.name,
                           :item_id => self.id) + "\n"
          message += I18n.t('has_contributors_lib.submitter_of.data_corruption')
          raise message
        end
      end
      submitter
    end
  end
end
