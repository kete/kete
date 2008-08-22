module BasketsHelper
  def link_to_link_index_topic(options={})
    link_to options[:phrase], {
      :controller => 'search',
      :action => :find_index,
      :current_basket_id => options[:current_basket_id],
      :current_homepage_id => options[:current_homepage_id] },
    :popup => ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100']
  end

  def link_to_add_index_topic(options={})
    link_to options[:phrase], :controller => 'topics', :action => :new, :index_for_basket => options[:index_for_basket]
  end

  def toggle_elements_applicable(listenToThisElementID, whenElementValueCondition, whenElementValueThis, toggleThisElementID, listenToElementIsCheckbox=false)
    if listenToElementIsCheckbox
      javascript_tag "function toggle_#{toggleThisElementID}() {
        var element = $('#{listenToThisElementID}');
        if ( #{whenElementValueCondition}element.checked ) {
          new Effect.BlindDown('#{toggleThisElementID}', {duration: .75})
          enableAllFields('#{toggleThisElementID}')
        } else {
          new Effect.BlindUp('#{toggleThisElementID}', {duration: .75})
          disableAllFields('#{toggleThisElementID}')
        }
      }
      $('#{listenToThisElementID}').observe('change', toggle_#{toggleThisElementID});"
    else
      javascript_tag "function toggle_#{toggleThisElementID}() {
        var element = $('#{listenToThisElementID}');
        if ( element.value #{whenElementValueCondition} '#{whenElementValueThis}' ) {
          if (!element.blindStatus || element.blindStatus == 'up') {
            new Effect.BlindDown('#{toggleThisElementID}', {duration: .75})
            element.blindStatus = 'down';
            enableAllFields('#{toggleThisElementID}')
          }
        } else {
          if (!element.blindStatus || element.blindStatus == 'down') {
            new Effect.BlindUp('#{toggleThisElementID}', {duration: .75})
            element.blindStatus = 'up';
            disableAllFields('#{toggleThisElementID}')
          }
        }
      }
      $('#{listenToThisElementID}').observe('change', toggle_#{toggleThisElementID});"
    end
  end

  def setupEnableDisableFunctions(clearValues=false)
    clearFields = clearValues ? "$$('#'+element+' input[type=checkbox]').each( function (input) { input.checked = false; });" : ""
    javascript_tag "function disableAllFields(element) {
      $$('#'+element+' input').each( function (input) { input.disabled = true; });
      $$('#'+element+' textarea').each( function (input) { input.disabled = true; })
      $$('#'+element+' select').each( function (input) { input.disabled = true; })
      #{clearFields}
    }
    function enableAllFields(element) {
      $$('#'+element+' input').each( function (input) { input.disabled = false; });
      $$('#'+element+' textarea').each( function (input) { input.disabled = false; })
      $$('#'+element+' select').each( function (input) { input.disabled = false; })
    }"
  end

  def basket_preferences_inheritance_message
    return if @basket != @site_basket # for now, we dont need to tell them,
                                      # it's obvious with the inherit option
    @inheritance_message = "<p>"
    #if @basket != @site_basket
    #  @inheritance_message += "Unspecified settings will be inherited
    #                        from the settings of the Site."
    #else
      @inheritance_message += "These settings will be inherited by all other
baskets unless they individually specify their own policy."
    #end

    @inheritance_message += "</p>"
  end
end
