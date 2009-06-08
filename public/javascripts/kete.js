/**
 * Submenu code "borrowed" from lighthouseapp.com
 */

var SubMenu = Class.create({
  initialize: function(li) {
    if(!$(li)) return;
    this.trigger = $(li).down('em');
    if(!this.trigger) return;
    this.menu = $(li).down('ul');
    this.trigger.observe('click', this.respondToClick.bind(this));
    document.observe('click', function(){ this.menu.hide() }.bind(this));
  },

  respondToClick: function(event) {
    event.stop();
    $$('ul.submenu').without(this.menu).invoke('hide');
    this.menu.toggle()
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
    makeElementLinkable(div.id, div.down('a').href);
  });
  $$('.image-result-wrapper').each(function(div) {
    makeElementLinkable(div.id, div.down('a').href);
  });
}

/**
 * Now setup everything to run when needed once the page is loaded
 */

document.observe('dom:loaded', function() {
  new SubMenu("user_baskets_list");
  if ($('portrait_images')) { enablePortraitDragAndDrop(); }
  if ($('portrait_help_div')) { enabledPortraitHelpToggle(); }
  makeSearchResultsDivClickable();
});
