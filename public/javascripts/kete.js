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
  console.log(serialized);
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

document.observe('dom:loaded', function() {
  new SubMenu("user_baskets_list");
  if ($('portrait_images')) { enablePortraitDragAndDrop(); }
  
  if ($('portrait_help_div')) {
    $('portrait_help_div').hide();
    $('portrait_help_div').hidden_status = 'hidden';
    $('portrait_help').show();
    $('portrait_help').down('a').observe('click', function(event) {
      if ($('portrait_help_div').hidden_status == 'hidden') {
        $('portrait_help_div').show();
        $('portrait_help_div').hidden_status = 'showing';
        $('portrait_help').down('a').update('hide help');
      } else {
        $('portrait_help_div').hide();
        $('portrait_help_div').hidden_status = 'hidden';
        $('portrait_help').down('a').update('show help');
      }
      event.stop();
    });
  }
});
