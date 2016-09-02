// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function getAndLoadGeo() {
  // Get Point Coordinates from db and load on map
  var group , markerArray = [];
  var coordinatesMarker = getCoordinates();  // Function is called, return value will end up in an array
  function getCoordinates() {
    var resource_id = "", result = [], arr = [];
      $.ajax({
        type: "GET",
        dataType: "json",
        url: "/stash_datacite/geolocation_points/points_coordinates",
        data: { resource_id: $.urlParam('resource_id') },
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
  var marker, markerArray = [];
  for (var i=0; i<coordinatesMarker.length; i++) {
    var lat = coordinatesMarker[i][0];
    var lng = coordinatesMarker[i][1];
    var mrk_id = coordinatesMarker[i][2];
    var markerLocation = new L.LatLng(lat, lng);
    marker = new L.Marker(markerLocation, { draggable: true, id: mrk_id }).addTo(map);
    // markerArray.push(new L.Marker(markerLocation, { id: mrk_id }));
    drawPopup(marker, lat, lng);

    marker.on('dragend', function(event) {
      drawPopup(event.target, event.target.getLatLng().lat, event.target.getLatLng().lng);
      $.ajax({
          type: "PUT",
          dataType: "script",
          url: "/stash_datacite/geolocation_points/update_coordinates",
          data: { 'latitude' : marker.getLatLng().lat, 'longitude' : marker.getLatLng().lng,
                 'resource_id' : $.urlParam('resource_id'), 'id' : event.target.options.id },
          success: function() {
            updateGeolocationPointsIndex();
          },
          error: function() {
            console.log("error occured");
          }
        });
    });
  }
// ----------------------------------------------------------------- //

// ----------------------------------------------------------------- //
  // Get Bounding Box coordinates from db and load on map
  var coordinatesBBox = getCoordinatesBBox();  // Function is called, return value will end up in an array
  function getCoordinatesBBox() {
    var resource_id = "", result = [], arr = [];
      $.ajax({
        type: "GET",
        dataType: "json",
        url: "/stash_datacite/geolocation_boxes/boxes_coordinates",
        data: { resource_id: $.urlParam('resource_id') },
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
// ----------------------------------------------------------------- //

// ----------------------------------------------------------------- //
  // Get GeoLocation Place Names from db and load on map
    var locationNames = getLocationNames();  // Function is called, return value will end up in an array
    function getLocationNames() {
      var resource_id = "", result = [], arr = [];
        $.ajax({
          type: "GET",
          dataType: "json",
          url: "/stash_datacite/geolocation_places/places_coordinates",
          data: { resource_id: $.urlParam('resource_id') },
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
    // group = L.featureGroup(markerArray).addTo(map);
    // map.fitBounds(group.getBounds());
// ----------------------------------------------------------------- //


// ------------------------------------------------------------- //
  // Function to display the Locations Index partial via Ajax.
  function updateGeolocationPointsIndex() {
    $.ajax({
        type: "GET",
        dataType: "script",
        url: "/stash_datacite/geolocation_points/index",
        data: { 'resource_id' : $.urlParam('resource_id') },
        success: function() {
        },
        error: function() {
          console.log("error occured");
        }
    });
  };
  // ------------------------------------------------------------- //

  // ------------------------------------------------------------- //
  function drawPopup(marker, lat, lng){
    marker.bindPopup(lat +","+ lng + " " +"<button class='delete-button'>Delete</button>");
    marker.on("popupopen", function(event) {
      $( ".delete-button" ).click(function() {
        map.removeLayer(marker);
        $.ajax({
          type: "DELETE",
          dataType: "script",
          url: "/stash_datacite/geolocation_points/delete_coordinates",
          data: {'id' : marker.options.id, 'resource_id' : $.urlParam('resource_id') },
          success: function() {
          },
          error: function() {
          }
        });
      });
    });
  };
  // ------------------------------------------------------------- //
};