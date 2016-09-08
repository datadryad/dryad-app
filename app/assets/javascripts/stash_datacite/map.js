// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
function loadMap() {
  // Create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map', { zoomControl: true }).setView([36.778259, -119.417931], 3);
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';
  map.zoomControl.setPosition('bottomright');
    // add an OpenStreetMap tile layer
      L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; ' + mapLink + ' Contributors',
          }).addTo(map);
  // -------------------------------- //

  // MAPZEN autocomplete search and save to db
  mapzen();

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
