// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var group , markerArray = [];
function loadReviewMap(resource_id) {
  var resource_id = resource_id;
  // create a map in the "map" div, set the view to a given place and zoom
  var map = L.map('map_review', { zoomControl: true }).setView([36.778259, -119.417931], 12);
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
        arr = $.map(result, function(n){
           return [[ n["latitude"], n["longitude"], n["id"] ]];
        });
        return(result);
      }

      //Loop through the markers array
      var marker;
      for (var i=0; i<coordinatesMarker.length; i++) {
        var lat = coordinatesMarker[i][0];
        var lng = coordinatesMarker[i][1];
        var mrk_id = coordinatesMarker[i][2];
        var markerLocation = new L.LatLng(lat, lng);
        markerArray.push(new L.Marker(markerLocation, { id: mrk_id }).bindPopup(lat +","+ lng));
      }


    getAndLoadGeoBox(resource_id);
    getAndLoadGeoPlace(resource_id);

    group = L.featureGroup(markerArray).addTo(map);
    // map.fitBounds(mapBounds(), { padding: [25, 25] } );
};