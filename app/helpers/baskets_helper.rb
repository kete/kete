module BasketsHelper
  def link_to_link_index_topic(options={})
    link_to options[:phrase], {
      :controller => 'search',
      :action => :find_index,
      :index_for_basket => options[:index_for_basket] },
    :popup => ['links', 'height=300,width=740,scrollbars=yes,top=100,left=100']
  end

  def link_to_add_index_topic(options={})
    link_to options[:phrase], :controller => 'topics', :action => :new, :index_for_basket => options[:index_for_basket]
  end

  def full_moderation_exceptions_js_helper
    javascript_tag "function toggleHiddenModeratedExcept(event) {
    var element = Event.element(event);

    if ( element.options[element.selectedIndex].value == \"false\" ) {

    // uncheck all moderated_except boxes and hide them
    $$('#settings_moderated_except input[type=checkbox]').each( function(box) {
    box.checked = false;
    box.disabled = true;
    });

    $('empty_settings_moderated_except').disabled = false;

    new Effect.BlindUp('settings_moderated_except', {duration: .75})

    } else {
    new Effect.BlindDown('settings_moderated_except', {duration: .75})

    $$('#settings_moderated_except input[type=checkbox]').each( function(box) { box.disabled = false; });
    }

    }

    $('settings[fully_moderated]').observe('change', toggleHiddenModeratedExcept);"
  end
end
