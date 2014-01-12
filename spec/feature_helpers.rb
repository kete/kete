module FeatureHelpers
  def load_production_seeds
    load "#{Rails.root}/db/seeds.rb"
  end
end
