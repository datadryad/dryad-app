// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function getAndLoadGeoBox(resource_id) {
  // Get Bounding Box coordinates from db and load on map
  var coordinatesBBox = getCoordinatesBBox(resource_id);  // Function is called, return value will end up in an array
  function getCoordinatesBBox(resource_id) {
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
   }
// ----------------------------------------------------------------- //
};