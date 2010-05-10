# Allows for overriding methods from gems and plugins for kete addons
module KeteAddonSupport
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def load_addon_extensions
      key = self.name.tableize.singularize.to_sym
      if Kete.extensions[:blocks].present? && Kete.extensions[:blocks][key].present?
        Kete.extensions[:blocks][key].each do |block|
          block.call
        end
      end
    end
  end
end
