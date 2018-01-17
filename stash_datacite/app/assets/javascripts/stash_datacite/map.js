// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
function loadMap(bounds) { // bounds is optional
  // Create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map', { zoomControl: true, scrollWheelZoom: false });
  map.on('focus', function() { map.scrollWheelZoom.enable(); });
  map.on('blur', function() { map.scrollWheelZoom.disable(); });
  if(bounds === undefined){
    map.setView([36.778259, -119.417931], 3);
  }else{
    map.fitBounds(bounds);
  }

  mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';
  map.zoomControl.setPosition('bottomright');
    // add an OpenStreetMap tile layer
      L.tileLayer(
        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{retina}.png', {
          attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
          worldCopyJump: true,
          retina: '@2x',
          detectRetina: false
        }).addTo(map);
  // -------------------------------- //

  // MAPZEN autocomplete search and save to db
  // mapzen();
  mapGeosearch(map);

  // Get Point BBox and Place Coordinates from db and load on map
  var resource_id = $.urlParam('resource_id');
  getAndLoadGeoPoint(resource_id);
  getAndLoadGeoBox(resource_id);
  getAndLoadGeoPlace(resource_id);

  //LEAFLET DRAW PLUGIN
  leafletDraw();
};


$.urlParam = function(name){
  var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
  return results[1] || 0;
}
