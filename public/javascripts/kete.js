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

// Called in the account/_portraits.html.erb partial,
// so it gets updated each time the partial is rendered
function updatePortraitControls() {
  $$('.portrait_image').each(function(portrait) {
    if(!portrait) return;
    portrait.trigger = portrait.down('img');
    if(!portrait.trigger) return;
    portrait.menu = portrait.down('span')
    if(!portrait.menu) return;

    portrait.menu.hide();

    portrait.trigger.observe('mouseover', function(event) {
      portrait.menu.show();
    });
    portrait.menu.observe('mouseover', function(event) {
      portrait.menu.show();
    });
    portrait.trigger.observe('mouseout', function(event) {
      portrait.menu.hide();
    });
    portrait.menu.observe('mouseout', function(event) {
      portrait.menu.hide();
    });
  });
}

document.observe('dom:loaded', function() {
  new SubMenu("user_baskets_list");
});