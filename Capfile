require 'capistrano/version'
load 'deploy' if respond_to?(:namespace) # cap2 differentiator

# cap 2 now supports plugins:
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

# =============================================================
# bells recipes and kete specific recipes
# as well as any custom recipes you may add
Dir['lib/recipes/*.rb'].each { |recipe_file| load(recipe_file) }

load 'config/deploy'

