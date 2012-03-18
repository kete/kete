# caching related
module CacheControllerHelpers
  unless included_modules.include? CacheControllerHelpers
    include GenericMutedWorkerCallingHelpers

    # TODO: this isn't having it fragment file named properly for show pages
    # see ticket #297
    LAYOUT_PARTS = ['accessibility']

    SHOW_PARTS = ['page_title_[privacy]', 'page_keywords_[privacy]', 'dc_metadata_[privacy]',
                  'page_description_[privacy]', 'google_map_api_[privacy]', 'edit_[privacy]',
                  'details_first_[privacy]', 'details_second_[privacy]',
                  'contributor_[privacy]', 'flagging_[privacy]',
                  'secondary_content_tags_[privacy]', 'secondary_content_extended_fields_[privacy]',
                  'secondary_content_extended_fields_embedded_[privacy]',
                  'secondary_content_license_metadata_[privacy]', 'history_[privacy]'] + LAYOUT_PARTS

    PUBLIC_SHOW_PARTS = ['comments-link_[privacy]', 'comments_[privacy]']
    MODERATOR_SHOW_PARTS = ['delete', 'comments-moderators_[privacy]']
    ADMIN_SHOW_PARTS = ['zoom_reindex']
    PRIVACY_SHOW_PARTS = ['privacy_chooser_[privacy]']

    INDEX_PARTS = ['page_keywords_[privacy]', 'page_description_[privacy]', 'google_map_api_[privacy]',
                   'details_[privacy]', 'license_[privacy]', 'extended_fields_[privacy]', 'edit_[privacy]',
                   'privacy_chooser_[privacy]', 'tools_[privacy]', 'recent_topics_[privacy]', 'search',
                   'extra_side_bar_html', 'archives_[privacy]', 'tags_[privacy]', 'contact'] + LAYOUT_PARTS

    # the following method is used when clearing show caches
    def all_show_parts
      SHOW_PARTS + PUBLIC_SHOW_PARTS + MODERATOR_SHOW_PARTS + ADMIN_SHOW_PARTS + PRIVACY_SHOW_PARTS
    end

    # the following method is used when seeing if all fragments are present
    # for example, we dont want to stop optimization if an admin fragment is missing for a logged out user
    def relevant_show_parts
      show_parts = SHOW_PARTS
      if logged_in? and @at_least_a_moderator
        show_parts += MODERATOR_SHOW_PARTS
      else
        show_parts += PUBLIC_SHOW_PARTS
      end
      if logged_in? and @site_admin
        show_parts += ADMIN_SHOW_PARTS
      end
      if @show_privacy_chooser
        show_parts += PRIVACY_SHOW_PARTS
      end
      show_parts
    end

    def cache_name_for(part, privacy)
      if part.include?('_[privacy]')
        part.sub(/\[privacy\]/, privacy)
      else
        part
      end
    end

    # if anything is added, edited, or destroyed in a basket
    # expire the basket index page caches
    def expire_basket_index_caches
      # we always expire the site basket index page, too
      # since items added, edited, or destroyed from any basket
      # show up in the contents list, as well as most recent topics, etc.
      INDEX_PARTS.each do |part|
        public_part = cache_name_for(part, 'public')
        private_part = cache_name_for(part, 'private')
        [public_part, private_part].each do |part|
          expire_basket_index_caches_for(part)
        end
      end
    end

    def expire_basket_index_caches_for(part)
      baskets_to_expire = [@current_basket, @site_basket]
      baskets_to_expire.each do |basket|
        expire_fragment(:controller => 'index_page',
                        :action => 'index',
                        :urlified_name => basket.urlified_name,
                        :part => part)
      end
    end

    def expire_fragment_for_all_versions(item, name = {})
      name = name.merge(:id => item.id)
      file_path = "#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub(/(\?|:)/, '.')}.cache"
      File.delete(file_path) if File.exists?(file_path)

      # Kieran Pilkington, 2008-12-15
      # Caches no longer store the title in the cache name, only the id, so we no
      # longer need to loop over past version titles and clear them out one by one
      #item.versions.find(:all, :select => 'distinct title, version').each do |version|
      #  expire_fragment(name.merge(:id => item.id.to_s + format_friendly_for(version.title)))
      #end
    end

    # expire the cache fragments for the show action
    # excluding the related cache, this we handle separately
    def expire_show_caches
      if CACHES_CONTROLLERS.include?(params[:controller])
        # James - 2008-07-01
        # Ensure caches are expired in the context of privacy.
        item = item_from_controller_and_id(false)
        public_or_private_version_of(item)
        expire_show_caches_for(item)
      end
    end
    alias :expire_show_caches_on_destroy :expire_show_caches

    def expire_show_caches_for(item)
      # only do this for zoom_classes
      item_class = item.class.name
      controller = zoom_class_controller(item_class)
      return unless ZOOM_CLASSES.include?(item_class)

      @privacy_type ||= (item.private? ? "private" : "public")

      all_show_parts.each do |part|

        # James - 2008-07-01
        # Most cache keys have a privacy scope, indicated by [privacy] in the key name.
        # In these cases, replace this with the actual item's current privacy.
        # I.e. secondary_content_tags_[privacy] => secondary_content_tags_private where
        # the current item is private.
        if params[:action] == 'destroy'
          resulting_part = cache_name_for(part, 'public')
          expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => resulting_part })
          resulting_part = cache_name_for(part, 'private')
          expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => resulting_part })
        else
          resulting_part = cache_name_for(part, @privacy_type)
          expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => resulting_part })
        end
      end

      # images have an additional cache
      # and topics may also have a basket index page cached
      if controller == 'images'
        expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => "caption_#{@privacy_type}" })
      elsif controller == 'topics'
        if item.index_for_basket.is_a?(Basket)
          # slight overkill, but most parts
          # would need to be expired anyway
          expire_fragment(/#{item.index_for_basket.urlified_name}\/index_page\/index\/(.+)/)
        end
      end

      # clear any search sources for this item (incase title has changed)
      expire_search_source_caches(true)

      # if we are deleting the thing
      # also delete it's related caches
      # as well as related caches of things it's related to
      if %w{ update destroy }.include?(params[:action])
        if controller != 'topics'
          expire_related_caches_for(item, 'topics')
          # expire any related topics related caches
          # comments don't have related topics, so skip it for them
          if item_class != 'Comment' && item.topics.count > 0
            expire_related_caches_for_batch_of(item.topics, controller)
          end
        else
          # topics need all it's related things expired
          ZOOM_CLASSES.each do |zoom_class|
            expire_related_caches_for(item, zoom_class_controller(zoom_class))
            related_items = Array.new
            if zoom_class == 'Topic'
              related_items += item.related_topics
            else
              related_items += item.send(zoom_class.tableize)
            end
            expire_related_caches_for_batch_of(related_items, 'topics') if related_items.count > 0
          end
        end
      end
    end

    def expire_group_of_related_caches(items, controller)
      items.each do |related_item|
        expire_related_caches_for(related_item, controller)
      end
    end

    def worker_expire_related_caches_for_batch_of(options)
      items = options[:items]
      controller = options[:controller]
      unless items
        Rails.logger.info("Error in worker_expire_related_caches_for_batch_of call, items not specified. Passed in options are: " + options.inspect)
        raise ArguementError
      end
      unless controller
        Rails.logger.info("Error in worker_expire_related_caches_for_batch_of call, controller not specified. Passed in options are: " + options.inspect)
        raise ArguementError
      end
      expire_group_of_related_caches(items, controller)
    end

    def expire_related_caches_for_batch_of(items, controller, options = { })
      # we want to flush related items caches incase they updated something we display
      unless call_generic_muted_worker_with(options.merge({ :method_name => "worker_expire_related_caches_for_batch_of",
                                                            :items => items,
                                                            :controller => controller}))
        # fallback to inline if worker fails
        expire_group_of_related_caches(items, controller)
      end
    end

    def expire_related_caches_for(item, controller = nil)
      related = Array.new
      if !controller.nil?
        related << controller
      else
        if item.class.name != 'Topic'
          related << 'topics'
        else
          # topics need all it's related things expired
          ZOOM_CLASSES.each do |zoom_class|
            related << zoom_class_controller(zoom_class)
          end
        end
      end
      related << 'public_query'
      related << 'related-tools-create-or-link-or-remove'
      related << 'related-tools-restore'
      related << 'related-tools-import'
      related.each do |related_controller|
        expire_fragment_for_all_versions(item,
                                         { :urlified_name => item.basket.urlified_name,
                                           :controller => zoom_class_controller(item.class.name),
                                           :action => 'show',
                                           :id => item,
                                           :related => related_controller} )
      end
    end

    def clear_caches_and_update_zoom_for_commented_item(item)
      if item.class.name == 'Comment'
        commented_item = item.commentable
        expire_caches_after_comments(commented_item, item.private?)
        commented_item.prepare_and_save_to_zoom
      end
    end

    def clear_caches_and_search_records_for(options)
      user = options[:user]
      unless user
        Rails.logger.info("Error in clear_caches_and_search_records_for call, user not specified. Passed in options are: " + options.inspect)
        raise ArguementError
      end

      user.distinct_contributions.each do |contribution|
        if contribution.is_a?(Comment)
          clear_caches_and_update_zoom_for_commented_item(contribution)
        else
          expire_contributions_caches_for(contribution)
        end
        contribution.prepare_and_save_to_zoom unless options[:dont_rebuild_zoom]
      end
    end

    def expire_contributions_caches_for(item_or_user, options = {})
      if item_or_user.kind_of?(User)
        # we want to flush contribution caches incase they updated something we display
        # we also want to update zoom for all items they have contributed to
        unless call_generic_muted_worker_with(options.merge({ :method_name => "clear_caches_and_search_records_for",
                                                              :class_key => :user,
                                                              :object => item_or_user }))

          clear_caches_and_search_records_for(options.merge({ :user => item_or_user }))
        end
      else
        # rather than find out if the contribution is for a public/private item
        # just clear both the caches
        ['contributor_public', 'contributor_private'].each do |part|
          expire_fragment_for_all_versions(item_or_user,
                                           { :urlified_name => item_or_user.basket.urlified_name,
                                             :controller => zoom_class_controller(item_or_user.class.name),
                                             :action => 'show',
                                             :id => item_or_user,
                                             :part => part })
        end
      end
    end

    def expire_caches_after_comments(item, private_comment)
      [ 'zoom_reindex',
        'comments-link_[privacy]',
        'comments-moderators_[privacy]',
        'comments_[privacy]' ].each do |part|

        @privacy_type ||= (private_comment ? "private" : "public")
        resulting_part = cache_name_for(part, @privacy_type)
        expire_fragment_for_all_versions(item,
                                         { :urlified_name => item.basket.urlified_name,
                                           :controller => zoom_class_controller(item.class.name),
                                           :action => 'show',
                                           :id => item,
                                           :part => resulting_part } )
      end
    end

    def expire_search_source_caches(force=false)
      return unless ZOOM_CLASSES.include?(zoom_class_from_controller(params[:controller]))
      SearchSource.all.each do |source|
        next unless ((Time.now - source.updated_at) / 60 > source.cache_interval)
        expire_fragment({ :action => 'show', :id => @cache_id, :search_source => source.title_id, :title => @current_item.to_param })
        source.update_attribute(:updated_at, Time.now)
      end
    end

    # cheating, we know that we are using file store, rather than mem_cache
    # TODO: put an if mem_cache ... use read_fragment({:part => part})
    # wrapped in this method
    def has_fragment?(name = {})
      # strip out everything after id (title in friendly url)
      name[:id] = name[:id].to_i unless name[:id].blank?
      File.exist?("#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub(/(\?|:)/, '.')}.cache")
    end

    # rss fragment caching
    # is only one big fragment now
    # so we can do a simple implementation
    def has_all_rss_fragments?(cache_key_hash)
      has_fragment?(cache_key_hash)
    end

    # used by show actions to determine whether to load item
    def has_all_fragments?
      #logger.info('Looking for all fragments')

      @privacy_type ||= get_acceptable_privacy_type_for(nil)

      # we are going a bit overboard with the params[:id].to_i bit
      # but we need to be consistent
      name = params[:id].blank? ? Hash.new : { :id => params[:id].to_i }
      if params[:controller] != 'index_page'
        relevant_show_parts.each do |part|
          resulting_part = cache_name_for(part, @privacy_type)
          return false unless has_fragment?(name.merge(:part => resulting_part))
        end
      end
      #logger.info('Has all show fragments')

      case params[:controller]
      when 'index_page'
        INDEX_PARTS.each do |part|
          resulting_part = cache_name_for(part, @privacy_type)
          return false unless has_fragment?({:part => resulting_part})
        end
      when 'topics'
        ZOOM_CLASSES.each do |zoom_class|
          if zoom_class != 'Comment'
            return false unless has_fragment?(name.merge(:related => zoom_class_controller(zoom_class)))
          end
        end
      else
        return false unless has_fragment?(name.merge(:related => 'topics'))
      end
      #logger.info('Has all related/index parts')
      return true
    end

    # remove rss feeds under all and search directories
    # for the class of thing that was just added
    def expire_rss_caches(basket = nil)
      # only applicable to zoom classes
      return unless ZOOM_CLASSES.include?(zoom_class_from_controller(params[:controller]))

      basket ||= @current_basket

      if @current_basket.nil?
        load_basket
        basket ||= @current_basket
      end

      # we go with a regexp (WARNING, assumes fs caching)
      # so we can clear 'all' and 'search' caches that might need to be expired
      # since site searches all other baskets, too
      # we need to expire it's cache, too
      %w(all search).each do |pattern|
        unless basket == @site_basket
          r = /#{@site_basket.urlified_name}\/#{pattern}\/.+/
          expire_fragment(r)
        end

        r = /#{basket.urlified_name}\/#{pattern}\/.+/
        expire_fragment(r)
      end
    end
  end
end
