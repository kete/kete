/**
 * Submenu code "borrowed" from lighthouseapp.com
 */

var SubMenu = Class.create({
  initialize: function(trigger, element) {
    if($$(trigger).size() == 0 || $$(element).size() == 0) { return; }
    this.trigger = $$(trigger).first();
    this.menu = $$(element).first();
    this.trigger.observe('click', this.respondToClick.bind(this));
    document.observe('click', function(){ this.menu.hide() }.bind(this));
  },

  respondToClick: function(event) {
    event.stop();
    this.menu.toggle();
  }
});

/**
 * Portrait Related Javascript
 */

function preventLinksExecuting() {
  $$('.portrait_image a').each(function(link) {
    link.observe('click', function(evt) {
      Event.stop(evt);
      link.stopObserving('click');
    });
  });
}

function makePortraitsSortable() {
  Sortable.create('portrait_images', {
    tag: 'div',
    constraint: false,
    overlap: false,
    containment: ['portrait_images', 'profile_avatar'],
    onChange: function(element) {
      preventLinksExecuting();
    },
    onUpdate: function(element) {
      preventLinksExecuting();
      updatePortraitPositions();
    }
  });
}

function updatePortraitPositions() {
  serialized = Sortable.serialize('portrait_images', { tag: 'div' });
  new Ajax.Request('/site/account/update_portraits', {
    method: 'get',
    parameters: { portraits: serialized }
  });
}

function enablePortraitDragAndDrop() {
  makePortraitsSortable();
  if ($$('#profile_avatar .portrait_image')) {
    Droppables.add('profile_avatar', {
      accept: 'portrait_image',
      hoverclass: 'avatar_hover',
      onDrop: function(element) {
        preventLinksExecuting();
        $('portrait_images').insert($('profile_avatar').innerHTML);
        $('profile_avatar').innerHTML = "<div id='" + element.id + "' class='portrait_image' style='position: relative;'>" + element.innerHTML + "</div>";
        element.remove();
        Sortable.destroy('portrait_images');
        makePortraitsSortable();
        updatePortraitPositions();
      }
    });
  }
}

function enabledPortraitHelpToggle() {
  $('portrait_help').down('a').observe('click', function(event) {
    $('portrait_help_div').show();
    $('portrait_help').down('a').hide();
    event.stop();
  });
  $('close_help').observe('click', function(event) {
    $('portrait_help_div').hide();
    $('portrait_help').down('a').show();
    event.stop();
  });
}

/**
 * Choice Heirarchy code (inactive)
 */

function enableCategoryListUpdater(controller_name) {
  $$('.category_list a').each(function(link) {
    link.observe('click', function(evt) {
      Event.stop(evt)
      new Ajax.Updater('category_selections', '/site/choices/categories_list', {
        method: 'get',
        parameters: {
          controller_name_for_zoom_class: controller_name,
          limit_to_choice: link.title
        },
        onLoading: function(loading) { $('categories_spinner').show(); },
        onComplete: function(complete) {
          $('categories_spinner').hide();
          enableCategoryListUpdater(controller_name);
        }
      });
    });
  });
}

/**
 * Related Items Slideshow functionality
 */

function setupRelatedCollapsableSections() {
  hideAllRelatedSections();
  // For each related items section, hide it, and add an hover event
  $$('.related-items-section').each(function(section) {
    $(section).down('a').observe('click', function(event) {
      if ($(section).down('img.expand_collapse_image').src.match('/images/related_items_expanded.gif')) {
        $(section).down('img.expand_collapse_image').src = '/images/related_items_collapsed.gif';
      } else {
        $(section).down('img.expand_collapse_image').src = '/images/related_items_expanded.gif';
      }
      $(section).down('ul').toggle();
      if ($(section).id == 'detail-linked-images') {
        $$('.slideshow_div').each(function(div) {
          $(div).toggle();
        });
      }
      // stop anything the hover might have triggered
      event.stop();
    });
  });
  // Show the contents of the first section in the related items inset
  if ($$('.related-items-section')[0]) {
    $$('.related-items-section')[0].down('img.expand_collapse_image').src = '/images/related_items_expanded.gif';
    $$('.related-items-section')[0].down('ul').show();
  }
}

function hideAllRelatedSections() {
  $$('.related-items-section').each(function(section) {
    $(section).down('img.expand_collapse_image').src = '/images/related_items_collapsed.gif';
    $(section).down('ul').hide();
  });
}

function setupRelatedImagesSlideshowPlayButton(url) {
  $('related_items_slideshow_controls').show();
  $('play_slideshow').observe('click', function(event) {
    new Ajax.Updater('related_items_slideshow', url, {
      method: 'get',
      evalScripts: true,
      onComplete: function(complete) {
        $('play_slideshow').up('.buttons').hide();
        $('related_still_image_container').hide();
      }
    });
    event.stop();
  });
}

function setupRelatedImagesSlideshowStopButton() {
  $('stop_slideshow').observe('click', function(event) {
    $('play_slideshow').up('.buttons').show();
    $('related_still_image_container').show();
    $('related_items_slideshow').innerHTML = '';
    event.stop();
  });
}

function setupRelatedImagesSlideshowPauseButton() {
  if ($('selected-image-display-paused')) {
    $('play_pause_slideshow').down('img').src = '/images/slideshow_play.gif';
  }
  $('play_pause_slideshow').observe('click', function(event) {
    if ($('selected-image-display-paused')) {
      $('selected-image-display-paused').remove();
      $('play_pause_slideshow').down('img').src = '/images/slideshow_pause.gif';
    } else {
      $('body-outer-wrapper').insert("<div id='selected-image-display-paused'></div>");
      $('play_pause_slideshow').down('img').src = '/images/slideshow_play.gif';
    }
    event.stop();
  });
}

/**
 * Extended Field Editing
 */

// Incase we add a custom choice, all choices below the
// current field should be cleared and hidden
function clearCorrespondingFieldWhenEdited(field_id, field_class, select_id, select_class) {
  $(select_id).observe('change', function(evt) {
    $(field_id).clear();
  });
  $(field_id).observe('change', function(evt) {
    first_sub_choice = null;
    reached_custom_choice = false;
    $$('select.'+select_class).each(function(select) {
      if (select.id == select_id) {
        reached_custom_choice = true;
        select.selectedIndex = 0;
      } else if (reached_custom_choice) {
        if (first_sub_choice == null) { first_sub_choice = select; }
        select.selectedIndex = 0;
        select.next('.'+field_class).clear();
      }
    });
    if (first_sub_choice != null) {
      first_sub_choice.up('div', 1).hide();
    }
  });
}

/**
 * Quick and easy expand and collapse fucntionality for Basket Profiles
 */

function quickExpandCollapse(clickable_element, affected_element, collapsed_image, expanded_image) {
  $(clickable_element).observe('click', function(event) {
    if ($(clickable_element).src.match(collapsed_image)) {
      $(clickable_element).src = expanded_image;
      new Effect.BlindDown(affected_element, {duration: .75});
    } else {
      $(clickable_element).src = collapsed_image;
      new Effect.BlindUp(affected_element, {duration: .75});
    }
    event.stop();
  });
}

/**
 * Search/Recent Topic result display
 */

function makeElementLinkable(id, url) {
  $(id).observe('click', function(event) {
    window.location = url;
  });
}

// makes the assumption that the first link points to the item
// which at the time of writing this, is correct (infact, all
// links in the div point to the item)
function makeSearchResultsDivClickable() {
  $$('.generic-result-wrapper').each(function(div) {
    if (!div.className.match('skip_div_click')) {
      makeElementLinkable(div.id, div.down('a').href);
    }
  });
  $$('.image-result-wrapper').each(function(div) {
    if (!div.className.match('skip_div_click')) {
      makeElementLinkable(div.id, div.down('a').href);
    }
  });
}

/**
 * Langauge selection dropdown
 */

function makeFooterLanguageSelectionClickable() {
  $('language_choices_dropdown').down('select').observe('change', function(event) {
    if ($('language_choices_dropdown').down('select').value != '') {
      $('language_choices_dropdown').down('form').submit();
    }
  });
}

/*
 * Show or hide the required or private only checkbox as needed on topic type or content type field mappings
 */
function showOrHideRequiredAsNeededFor(id) {
 $(id).observe('change', function(event) {
   this.up('.mapping_required_and_private_only').down('.mapping_private_only').toggle();
 });
}
function showOrHidePrivateOnlyAsNeededFor(id) {
  $(id).observe('change', function(event) {
    this.up('.mapping_required_and_private_only').down('.mapping_required').toggle();
  });
}

/**
 * Add default value to a input field that hides when element gains focus
 */
function addDefaultValueToSearchTerms(default_value) {
  if($('search_terms').value == '') {
    $('search_terms').value = default_value;
  }
  $('search_terms').observe('focus', function() {
    if($('search_terms').value == default_value) {
      $('search_terms').value = '';
    }
  });
  $('search_terms').observe('blur', function() {
    if($('search_terms').value == '' && !$('advanced_search_dropdown').visible()) {
      $('search_terms').value = default_value;
    }
  });
}

/**
 * Now setup everything to run when needed once the page is loaded
 */

document.observe('dom:loaded', function() {
  new SubMenu("#user_baskets_list em", "#user_baskets_list ul.submenu");
  if ($('portrait_images')) { enablePortraitDragAndDrop(); }
  if ($('portrait_help_div')) { enabledPortraitHelpToggle(); }
  if ($$('#related_items').size() > 0) { setupRelatedCollapsableSections(); }
  makeSearchResultsDivClickable();
  if ($('language_choices_dropdown')) { makeFooterLanguageSelectionClickable(); }
});
