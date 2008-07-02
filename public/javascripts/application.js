// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

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
}

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
}
