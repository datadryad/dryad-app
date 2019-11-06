// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function getAndLoadGeoPoint(resource_id) {
  // Get Point Coordinates from db and load on map
  var coordinatesMarker = getCoordinates(resource_id);  // Function is called, return value will end up in an array
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
  var marker, markerArray = [];
  for (var i=0; i<coordinatesMarker.length; i++) {
    var lat = coordinatesMarker[i]['latitude'];
    var lng = coordinatesMarker[i]['longitude'];
    var mrk_id = coordinatesMarker[i]['id'];
    var markerLocation = new L.LatLng(lat, lng);
    marker = new L.Marker(markerLocation, { draggable: true, id: mrk_id }).addTo(map);
    drawPopup(marker, lat, lng);

    marker.on('dragend', function(event) {
      drawPopup(event.target, event.target.getLatLng().lat, event.target.getLatLng().lng);
      $.ajax({
          type: "PUT",
          dataType: "script",
          url: "/stash_datacite/geolocation_points/update_coordinates",
          data: { 'latitude' : marker.getLatLng().lat, 'longitude' : marker.getLatLng().lng,
                 'resource_id' : resource_id, 'id' : event.target.options.id },
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

// ------------------------------------------------------------- //
  // Function to display the Locations Index partial via Ajax.
  function updateGeolocationPointsIndex() {
    $.ajax({
        type: "GET",
        dataType: "script",
        url: "/stash_datacite/geolocation_points/index",
        data: { 'resource_id' : resource_id },
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
          data: {'id' : marker.options.id, 'resource_id' : resource_id },
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