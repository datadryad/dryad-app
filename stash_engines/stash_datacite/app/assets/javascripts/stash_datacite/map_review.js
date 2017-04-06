// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
function loadReviewMap(resource_id) {
  var resource_id = resource_id;
  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map_review', { zoomControl: true, scrollWheelZoom: false }).setView([36.778259, -119.417931], 3);
  map.on('focus', function() { map.scrollWheelZoom.enable(); });
  map.on('blur', function() { map.scrollWheelZoom.disable(); });
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';
      map.zoomControl.setPosition('bottomright');
    // add an OpenStreetMap tile layer
      var tileLayer = L.tileLayer(
        'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{retina}.png', {
          attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>',
          worldCopyJump: true,
          retina: '@2x',
          detectRetina: false
        });
      tileLayer.addTo(map);
      tileLayer.on("load",function() {
        console.log("all visible tiles have been loaded");
        $('#random_message').html('Tile layer has been loaded');
      });

  // size map to show correct scale for the items present (from list), please don't remove
  map.fitBounds(mapBounds(), { padding: [25, 25] } );

  // -------------------------------- //

  // -------------------------------- //
    // get point coordinates from db and load on map
    var coordinatesMarker = getCoordinates();  // Function is called, return value will end up in an array
    function getCoordinates() {
      var result = [], arr = [];
        $.ajax({
          type: "GET",
          dataType: "json",
          url: "/stash_datacite/geolocation_points/points_coordinates",
          data: { resource_id: resource_id },
          async: false,
          success: function(data) {
            result = data;
          },
          error: function() {
            console.log('Error occured');
          }
        });
        return(result);
      }

      //Loop through the markers array
      var marker;
      for (var i=0; i<coordinatesMarker.length; i++) {
        var lat = coordinatesMarker[i]['latitude'];
        var lng = coordinatesMarker[i]['longitude'];
        var mrk_id = coordinatesMarker[i]['id'];
        var markerLocation = new L.LatLng(lat, lng);
        marker = new L.Marker(markerLocation, { id: mrk_id }).bindPopup(lat +","+ lng).addTo(map);
      }

    getAndLoadGeoBox(resource_id);
    getAndLoadGeoPlace(resource_id);
};