// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
// these following two are supposed to be right
//= require turbolinks
// require jquery3
// require rails-ujs
// require activestorage -- this doesn't work for some reason

//
// Required by Blacklight
//= require popper
// Twitter Typeahead for autocomplete
//= require twitter/typeahead
//= require bootstrap
//= require blacklight/blacklight

// if remove require tree below then the map stops loading
//= require_tree .

Blacklight.doSearchContextBehavior = function(){
  console.log("Redefining doSearchContextBehavior so as not to intercept search results.")
};
