// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
$(document).ready(function() {

  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map').setView([-41.2858, 174.78682], 14);
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';

    // add an OpenStreetMap tile layer
      L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; ' + mapLink + ' Contributors',
          maxZoom: 18,
          }).addTo(map);

    // Initialize the FeatureGroup to store editable layers
      var drawnItems = new L.FeatureGroup();
      map.addLayer(drawnItems);

    // Initialize the draw control and pass it the FeatureGroup of editable layers
      var drawControl = new L.Control.Draw({
          position: 'topright',
          draw: {
            polyline : false,
            polygon : false,
            circle : false,
          },
          edit: {
              featureGroup: drawnItems
          }
      });
      map.addControl(drawControl);

    // listen to the draw created event
      map.on('draw:created', function (e) {
        var type = e.layerType,
            layer = e.layer;
      drawnItems.addLayer(layer);

        var resource_id = $.urlParam('resource_id');
        var rectangle_coordinates = getShapes(drawnItems);
        if (type == "rectangle") {
          //obtain bounding box from the shape coordinates (for rectangle) of map
          var geoJsonData = {
                            "type": "Feature",
                            "properties": {},
                            "geometry": {
                              "type": "Polygon",
                              "coordinates": [ rectangle_coordinates ]
                            }
                          };
          var geoJsonLayer = L.geoJson(geoJsonData);
          var bounding_box_sw_lat = geoJsonLayer.getBounds().getSouthWest().lat;
          var bounding_box_sw_lng = geoJsonLayer.getBounds().getSouthWest().lng;
          var bounding_box_ne_lat = geoJsonLayer.getBounds().getNorthEast().lat;
          var bounding_box_ne_lng = geoJsonLayer.getBounds().getNorthEast().lng;
          $.ajax({
            type: "POST",
            url: "/stash_datacite/geolocation_boxes/map_coordinates",
            data: { 'sw_latitude' : bounding_box_sw_lat, 'sw_longitude' : bounding_box_sw_lng,
                    'ne_latitude' : bounding_box_ne_lat, 'ne_longitude' : bounding_box_ne_lng,
                    'resource_id' : resource_id }
          });
        }

        if (type == "marker") {
          //obtain latlng coordinates from the shape marker of map
          var marker_coordinates = getShapes(drawnItems).toString().split(",");
          $.ajax({
            type: "POST",
            url: "/stash_datacite/geolocation_points/map_coordinates",
            data: { 'latitude' : marker_coordinates[0], 'longitude' : marker_coordinates[1],
                    'resource_id' : resource_id }
          });
        }
      });

      var getShapes = function(drawnItems) {
        var lng, lat;

        drawnItems.eachLayer(function(layer) {
            // Note: Rectangle extends Polygon. Polygon extends Polyline.
            // Therefore, all of them are instances of Polyline
            if (layer instanceof L.Polyline) {
              coordinates = [];
              latlngs = layer.getLatLngs();
              for (var i = 0; i < latlngs.length; i++) {
                  coordinates.push([latlngs[i].lng, latlngs[i].lat])
              }
            }

            if (layer instanceof L.Marker) {
              coordinates = [];
              coordinates.push([layer.getLatLng().lat, layer.getLatLng().lng]);
            }
        });
        return coordinates;
      };

// console.log("Bounding Box: " + geoJsonLayer.getBounds().toBBoxString());
    // listen to the draw edited event
        // map.on('draw:edited', function () {
        //     // Update db to save latest changes.
        // });

    // listen to the draw deleted event
        // map.on('draw:deleted', function () {
        //     // Update db to save latest changes.
        // });
});

$(document).ready(function() {
  $("#geolocation_box").hide();
  $("#geo_box").on('click', function(e){
    $("#geolocation_box").show();
    $("#geolocation_point").hide();
  });
});

$(document).ready(function() {
  $("#geolocation_point").show();
  $("#geo_point").on('click', function(e){
    $("#geolocation_box").hide();
    $("#geolocation_point").show();
  });
});

$(document).ready(function(){
    $("#location_section").click(function() {
        setTimeout(function() {
            map.invalidateSize();
        }, 300);
    });
});

// $(document).ready(function(){
//   $("#geo_lat_point").on('blur', function(e){
//   var lat = parseFloat($(this).val());
//   var latReg = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/;
//   if (lat == '' || lat == null) {}
//   if(!latReg.test(lat)) {
//     alert("Please enter valid latitude value")
//     }
//     else {
//       // do nothing
//     }
//   });
// });

// $(document).ready(function(){
//   $("#geo_lng_point").on('blur', function(e){
//   var lng = parseFloat($(this).val());
//   var lngReg = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/;
//   if (lng == '' || lng == null) {}
//   if(!lngReg.test(lng)) {
//     alert("Please enter valid longitude value")
//     }
//     else {
//       // do nothing
//     }
//   });
// });


$.urlParam = function(name){
  var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
  return results[1] || 0;
}


