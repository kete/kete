// TODO: is all of this stuff still required?
//= require prototype
//= require prototype_ujs
//= require effects
//= require dragdrop
//= require controls
//= require_tree ./active_scaffold
//= require_tree ./anarchy_media
//= require controls.js
//= require dhtml_history.js
//= require dragdrop.js
//= require effects.js
//= require_tree ./gmaps4rails
//= require_tree ./image_selector_config
//= require kete.js
//= require redbox.js
//= require rico_corner.js

window.onload = function(){
  if (parseInt(navigator.appVersion)>3) {
    if (navigator.appName=="Netscape") {
      winW = window.innerWidth;
      winH = window.innerHeight;
    }
    if (navigator.appName.indexOf("Microsoft")!=-1) {
      winW = document.body.offsetWidth;
      winH = document.body.offsetHeight;
    }
  }

  if(winW < 1160) {
    if(document.getElementById('home-second-row')){
      document.getElementById('home-second-row').style.clear = "both";
      document.getElementById('home-second-row').style.paddingTop = "20px";
    }
  } else {
    if(document.getElementById('home-second-row')){
      document.getElementById('home-second-row').style.clear = "none";
      document.getElementById('home-second-row').style.paddingTop = "0px";
    }
  }
};

window.onresize = function(){
  if (parseInt(navigator.appVersion)>3) {
    if (navigator.appName=="Netscape") {
      winW = window.innerWidth;
      winH = window.innerHeight;
    }
    if (navigator.appName.indexOf("Microsoft")!=-1) {
      winW = document.body.offsetWidth;
      winH = document.body.offsetHeight;
    }
  }

  if(winW < 1160) {
    if(document.getElementById('home-second-row')){
      document.getElementById('home-second-row').style.clear = "both";
      document.getElementById('home-second-row').style.paddingTop = "20px";
    }
  } else {
    if(document.getElementById('home-second-row')){
      document.getElementById('home-second-row').style.clear = "none";
      document.getElementById('home-second-row').style.paddingTop = "0px";
    }
  }
};
