# wrap the action rendering for ActiveScaffold controllers
module ActionController #:nodoc:
  class Base
    def render_with_active_scaffold(*args, &block)
      # ACC I'm never seeing this params[:adapter] value being passed in, only args[0][:action]
      options = args.find {|a| a.is_a?(Hash) } || {}
      if self.class.uses_active_scaffold? and ( params[:adapter] || options[:action] ) and @rendering_adapter.nil?
        @rendering_adapter = true # recursion control
        # if we need an adapter, then we render the actual stuff to a string and insert it into the adapter template
        path_val = params[:adapter] || options[:action]
        # ACC I'm setting use_full_path to false here and rewrite_template_path_for_active_scaffold has been
        # modified to return an absolute path
        show_layout = options.has_key?(:layout) ? options[:layout] : (options[:partial] ? false : true)
        render_without_active_scaffold(
          :file          => rewrite_template_path_for_active_scaffold(path_val),
          :locals        => {:payload => render_to_string(options.merge(:layout => false), &block)},
          :use_full_path => false,
          :layout        => show_layout
        )
        @rendering_adapter = nil # recursion control
      else
        render_without_active_scaffold(*args, &block)
      end
    end
    alias_method_chain :render, :active_scaffold unless method_defined?(:render_without_active_scaffold)

    private

    def rewrite_template_path_for_active_scaffold(path)
      base = File.join RAILS_ROOT, 'app', 'views'
      # check the ActiveScaffold-specific directories
      active_scaffold_config.template_search_path.each do |template_path|
        search_dir = File.join base, template_path
        next unless File.exists?(search_dir)
        # ACC I'm using this regex directory search because I don't know how to hook into the
        # rails code that would do this for me. I am assuming here that path is a non-nested
        # partial, so my regex is fragile, and will only work in that case. 
        template_file = Dir.entries(search_dir).find {|f| f =~ /^#{path}/ }
        # ACC pick_template and template_exists? are the same method (aliased), using both versions
        # to express intent.
        return File.join(search_dir, template_file) if !template_file.nil? && template_exists?(template_file)
      end
      return path
    end
  end
end