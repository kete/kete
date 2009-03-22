// Submenu code "borrowed" from lighthouseapp.com

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
      $$('.slideshow_div').each(function(div) {
        $(div).toggle();
      });
      // stop anything the hover might have triggered
      event.stop();
    });
  });
  // Show the contents of the first section in the related items inset
  $$('.related-items-section')[0].down('img.expand_collapse_image').src = '/images/related_items_expanded.gif';
  $$('.related-items-section')[0].down('ul').show();
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
        $('play_slideshow').hide();
        $('related_still_image_container').hide();
      }
    });
    event.stop();
  });
}

function setupRelatedImagesSlideshowStopButton() {
  $('stop_slideshow').observe('click', function(event) {
    $('play_slideshow').show();
    $('related_still_image_container').show();
    $('related_items_slideshow').innerHTML = '';
    event.stop();
  });
}

function setupRelatedImagesSlideshowPauseButton() {
  $('play_pause_slideshow').observe('click', function(event) {
    if ($('selected-image-display-paused')) {
      $('selected-image-display-paused').remove();
      $('play_pause_slideshow').down('img').src = '/images/related_items_expanded.gif';
    } else {
      document.body.insert("<div id='selected-image-display-paused'></div>");
      $('play_pause_slideshow').down('img').src = '/images/slideshow_play.gif';
    }
    event.stop();
  });
}

document.observe('dom:loaded', function() {
  new SubMenu("user_baskets_list");
  if ($('portrait_images')) { enablePortraitDragAndDrop(); }
  
  if ($('portrait_help_div')) {
    $('portrait_help').down('a').observe('click', function(event) {
      $('portrait_help_div').show();
      $('portrait_help').down('a').hide();
      event.stop();
    });
    $('close_help').observe('click', function(event) {
      $('portrait_help_div').hide();
      $('portrait_help').down('a').show();
      event.stop();
    })
  }

  if ($$('#related_items.inset').size() > 0) { setupRelatedCollapsableSections(); }
});
