// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
$(document).ready(function() {

  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map').setView([36.778259, -119.417931], 12);
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';

    // add an OpenStreetMap tile layer
      L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; ' + mapLink + ' Contributors',
          maxZoom: 18,
          }).addTo(map);

  // -------------------------------- //
    // get point coordinates from db and load on map
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
            alert('Error occured');
          }
        });
        arr = $.map(result, function(n){
           return [[ n["latitude"], n["longitude"] ]];
        });
        return(arr);
    }

     //Loop through the markers array
     for (var i=0; i<coordinatesMarker.length; i++) {
        var lat = coordinatesMarker[i][0];
        var lng = coordinatesMarker[i][1];
        var markerLocation = new L.LatLng(lat, lng);
        var marker = new L.Marker(markerLocation, { draggable: true }).addTo(map).bindPopup(lat +","+ lng);
     }
  // -------------------------------- //

  // -------------------------------- //
    // get bbox coordinates from db and load on map
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
            alert('Error occured');
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
        map.fitBounds(bounds);
     }
    // -------------------------------- //


    // -------------------------------- //
      // get location names from db and load on map
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
              alert('Error occured');
            }
          });
          arr = $.map(result, function(n){
             return [[ n["geo_location_place"] ]];
          });
          return(arr);
      }

       // Loop through the bbox array
        for (var i=0; i<locationNames.length; i++) {
          var place = locationNames[i][0];
          MQ.geocode().search(place).on('success', function(e) {
              var best = e.result.best,
                  latlng = best.latlng;

          var newMarker = new L.marker([latlng.lat, latlng.lng], { draggable: true }).addTo(map).bindPopup('<strong>' + best.adminArea5 + ', ' + best.adminArea3 + ', ' + best.adminArea1);
          });
        }
      // -------------------------------- //


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
            rect: {
              shapeOptions: {
                color: 'green'
              },
            },
            marker: {
            },
          },
          edit: {
              featureGroup: drawnItems,
              remove: true
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


    // listen to the draw edited event
      map.on('draw:edited', function (e) {
          var layers = e.layers;
          layers.eachLayer(function (layer) {
              if (layer instanceof L.Marker){
                      alert(layer.getLatLng().toString());
              }
          });
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


