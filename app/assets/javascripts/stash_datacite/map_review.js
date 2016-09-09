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
        return(arr);
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

  // -------------------------------- //
    // get bbox coordinates from db and load on map
    var coordinatesBBox = getCoordinatesBBox();  // Function is called, return value will end up in an array
    function getCoordinatesBBox() {
      var result = [], arr = [];
        $.ajax({
          type: "GET",
          dataType: "json",
          url: "/stash_datacite/geolocation_boxes/boxes_coordinates",
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
           return [[ n["sw_latitude"], n["sw_longitude"], n["ne_latitude"], n["ne_longitude"] ]];
        });
        return(arr);
    }

    // Loop through the bbox array
    for (var i=0; i<coordinatesBBox.length; i++) {
      var sw_lat = coordinatesBBox[i][0];
      var sw_lng = coordinatesBBox[i][1];
      var ne_lat = coordinatesBBox[i][2];
      var ne_lng = coordinatesBBox[i][3];
      var bounds = [[sw_lat, sw_lng], [ne_lat, ne_lng]];
      var newRectangle = L.rectangle(bounds, {color: "#ff7800", weight: 1}).addTo(map).bindPopup(sw_lat + ", " + sw_lng + ", " + ne_lat + ", " + ne_lng);
      //map.fitBounds(bounds);
    }
    // -------------------------------- //

    // -------------------------------- //
    // get location names from db and load on map
    var locationNames = getLocationNames();  // Function is called, return value will end up in an array
    function getLocationNames() {
      var result = [], arr = [];
        $.ajax({
          type: "GET",
          dataType: "json",
          url: "/stash_datacite/geolocation_places/places_coordinates",
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
           return [[ n["geo_location_place"], n["latitude"], n["longitude"], n["id"] ]];
        });
        return(arr);
    }
    L.Icon.Default.imagePath = 'assets/images/stash_datacite';
    var customIcon = new L.Icon({
          // iconUrl: L.Icon.Default.imagePath +'/globe.png',
          iconUrl: 'https://thevendy.files.wordpress.com/2015/02/black-and-white-world-globe.gif',
          iconSize: [25, 25], // size of the icon
          iconAnchor: [12, 25], // point of the icon which will correspond to marker's location
          popupAnchor: [0, -25] // point from which the popup should open relative to the iconAnchor
    });
     // Loop through the location names array
    for (var i=0; i<locationNames.length; i++) {
      var place = locationNames[i][0];
      var lat   = locationNames[i][1];
      var lng   = locationNames[i][2];
      var mrk_id = locationNames[i][3];
      var newMarkerLocation = new L.LatLng(lat, lng);
      markerArray.push(new L.marker(newMarkerLocation, { icon: customIcon, id: mrk_id }).addTo(map).bindPopup('<strong>' + place));
    }
    // -------------------------------- //

    group = L.featureGroup(markerArray).addTo(map);
    map.fitBounds(mapBounds(), { padding: [25, 25] } );
};