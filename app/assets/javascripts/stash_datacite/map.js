// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
$(document).ready(function() {

  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map').setView([36.778259, -119.417931], 2);
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';

    // add an OpenStreetMap tile layer
      L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; ' + mapLink + ' Contributors',
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
          marker = new L.Marker(markerLocation, { draggable: true, id: mrk_id }).addTo(map).bindPopup(lat +","+ lng + " " +"<button class='delete-button'>Delete</button>");

          marker.on("popupopen", function(event) { onPopupOpen(event.target) });

          marker.on('dragend', function(event) {
            var chagedPos = event.target.getLatLng();
            this.bindPopup(chagedPos.toString() + " " +"<button class='delete-button'>Delete</button>");
            $.ajax({
                type: "PUT",
                dataType: "script",
                url: "/stash_datacite/geolocation_points/update_coordinates",
                data: { 'latitude' : marker.getLatLng().lat, 'longitude' : marker.getLatLng().lng,
                       'resource_id' : $.urlParam('resource_id'), 'id' : marker.options.id },
                success: function() {
                },
                error: function() {
                }
              });
          });
      }

    // Delete marker from map and db
      function onPopupOpen(marker) {
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
          MQ.geocode().search(place).on('success', function(e) {
              var best = e.result.best,
                  latlng = best.latlng;

          var newMarker = new L.marker([latlng.lat, latlng.lng], { draggable: true, icon: customIcon }).addTo(map).bindPopup('<strong>' + best.adminArea5 + ', ' + best.adminArea3 + ', ' + best.adminArea1);
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
                color: 'green',
                repeatMode: true,
              },
            },
            marker: {},
          },
          edit: {
            featureGroup: drawnItems,
            edit: false,
            remove: false
          }
      });
      map.addControl(drawControl);

    // listen to the draw created event
      map.on('draw:created', function (e) {
        var type = e.layerType;
      drawnItems.addLayer(e.layer);

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
            dataType: "script",
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
              layer.dragging.enable();
              layer.bindPopup(coordinates + "<button class='delete-button'>Delete</button>");
            }
        });
        return coordinates;
      };
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
        }, 1000);
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


