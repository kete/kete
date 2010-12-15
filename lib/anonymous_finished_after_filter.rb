module AnonymousFinishedAfterFilter
  unless included_modules.include? AnonymousFinishedAfterFilter
    def self.included(klass)
      class_key = klass.name.sub('Controller', '').tableize
      class_key = class_key.singularize if %w(audio video).include?(class_key.singularize)

      specs = Array.new
      if Kete.respond_to?(:allowed_anonymous_actions) && Kete.allowed_anonymous_actions.present?
        specs = Kete.allowed_anonymous_actions.collect do |h|
          h[:finished_after]
        end.flatten.select do |s|
          s.include?(class_key)
        end
      end

      finished_after_actions = specs.collect { |pair| pair.split('/')[1].to_sym }

      klass.send :after_filter, :finished_as_anonymous_after, :only => finished_after_actions
    end
  end
end
