module SslHelpers

  def self.included(klass)
    if defined?(FORCE_HTTPS_ON_RESTRICTED_PAGES) && FORCE_HTTPS_ON_RESTRICTED_PAGES
      ActionView::Base.send(:include, SslHelpers::FormTagHelper)
      ActionView::Base.send(:include, SslHelpers::PrototypeHelper)
      ActionController::UrlWriter.send(:include, SslHelpers::UrlWriter)

      klass.send :before_filter, :redirect_to_https_if_needed

      # Ensure SSL is allowed on all controllers
      klass.class_eval do

        # We need to ensure certain actions are run with SSL requirement if applicable
        include SslRequirement
        include SslHelpers::Base
        def ssl_allowed?; true; end
      end

    end
  end

  # Uses form_tag for the nuts and bolts work
  # ActionView::Helpers::FormHelper#form_for

  # Overload for ActionView::Helpers::FormTagHelper
  module FormTagHelper

    def form_tag(url_for_options = {}, options = {}, *parameters_for_url, &block)

      if url_for_options.kind_of?(Hash)
        merge_into = case url_for_options[:overwrite_params]
          when nil
            url_for_options
          else
            url_for_options[:overwrite_params]
        end

        merge_into.merge!(:protocol => 'https://', :only_path => false)
      end

      super(url_for_options, options, *parameters_for_url, &block)
    end

  end

  # Overload for ActionView::Helpers::PrototypeHelper
  module PrototypeHelper

    # Uses form_remote_tag for the nuts and bolts work
    # ActionView::Helpers::PrototypeHelper#remote_form_for

    def form_remote_tag(options = {}, &block)
      options[:url].merge!(:protocol => 'https://') if options[:url].kind_of?(Hash)
      options[:html].merge!(:protocol => 'https://') if !options[:html].nil? && options[:html].kind_of?(Hash)

      super(options, &block)
    end

  end

  # When it matters, requests are passed to ActionController::Base
  # ActionView::Helpers::UrlHelper#url_for

  # Integration::Session passes request to ActionController::Base.
  # ActionController::Integration::Session#url_for

  # Overload for ActionController::Base
  module Base

    def url_for(options = nil)
      if options.kind_of?(Hash)
        options.merge!(:protocol => "https://") if options[:private] == "true"

        # If the protocol is HTTPS and we're not already there, and we haven't explicitly
        # asked for the path only, send the whole address so we're forced to HTTPS

        # There is potential for issues with this when the only the path is expected as
        # this is normally default behaviour, and we are modifying it here.
        if options[:protocol] =~ /^https/ and !request.ssl? and !options[:only_path]
          options.merge!(:only_path => false)
        end
      end

      super(options)
    end

    def polymorphic_url(record_or_hash_or_array, options = {})
      raise "called polymorphic_url"
      options.merge!(:protocol => 'https://') if options.kind_of?(Hash)
      super(record_or_hash_or_array, options)
    end

  end

  # Overload for ActionController::UrlWriter
  module UrlWriter

    # Used in contexts other than ActionController and ActionView
    def url_for(options)
      if options.kind_of?(Hash) && options[:private] == "true"
        options.merge!(:protocol => "https://")
      end

      super(options)
    end

  end

  private

  def redirect_to_https_if_needed
    if (params[:privacy_type] == 'private' || params[:private] == 'true') && request.port == 80
      redirect_to params.merge(:protocol => 'https')
      return false
    end
    true
  end

end
