# Basic configuration class for external search sources
class ExternalSearchSources
  @@settings = Hash.new
  def self.settings;        @@settings;              end
  def self.[](key);         @@settings[key];         end
  def self.[]=(key, value); @@settings[key] = value; end
end

# method that tests the user is logged in and redirects if not
ExternalSearchSources[:login_method] = :login_required

# the role needed to access search sources controller as set by rails-authorization-plugin
# http://github.com/DocSavage/rails-authorization-plugin
ExternalSearchSources[:authorized_role] = "admin"

# the path to redirect to if the current user does not match the above authorized role
ExternalSearchSources[:unauthorized_path] = "/"

# default url options to use when making redirects
ExternalSearchSources[:default_url_options] = {}

# the classes for text and image results
ExternalSearchSources[:default_link_classes] = 'search_source-default-result'
ExternalSearchSources[:image_link_classes] = 'search_source-image-result'

# whether to enable caching. Disabled by default because it requires you
# to create your own cache expiry depending on where the plugin is used
ExternalSearchSources[:cache_results] = false

# an array of search source types for the search sources to choose from
# only feed is supported at the moment
ExternalSearchSources[:source_types] = %w{ feed }

# an array of source targets (something that allows you to have different
# search sources in different pages via the :target option)
ExternalSearchSources[:source_targets] = %w{ search homepage }

# an array of limit options for the search sources to choose from
ExternalSearchSources[:limit_params] = %w{ count limit num_results }

# how long should we wait to get a response before terminating the search source?
# (ensures that page load times aren't extremely high if the source is offline)
# in seconds, set to nil for no timeout (which falls back to system default)
ExternalSearchSources[:timeout] = 2
