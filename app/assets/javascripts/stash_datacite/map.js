// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
function loadMap() {
  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map', { zoomControl: true }).setView([36.778259, -119.417931], 6);
      mapLink = '<a href="https://openstreetmap.org">OpenStreetMap</a>';
  map.zoomControl.setPosition('bottomright');
    // add an OpenStreetMap tile layer
      L.tileLayer(
          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; ' + mapLink + ' Contributors',
          }).addTo(map);
  // -------------------------------- //

  // mapzen autocomplete search and save to db
  var customIcon = new L.Icon({
    // iconUrl: L.Icon.Default.imagePath +'/globe.png',
    iconUrl: 'https://thevendy.files.wordpress.com/2015/02/black-and-white-world-globe.gif',
    iconSize: [25, 25], // size of the icon
    iconAnchor: [12, 25], // point of the icon which will correspond to marker's location
    popupAnchor: [0, -25] // point from which the popup should open relative to the iconAnchor
  });

  var geocoder = L.control.geocoder('search-OJQOSkw', {
      placeholder: 'Add by Location Name',
      pointIcon: false,
      polygonIcon: false,
      position: 'topleft',
      markers: { icon: customIcon },
      expanded: true
  }).addTo(map);

  var lat, lng, location_name;
  geocoder.on('select', function (e) {
    location_name =  e.feature.properties.label;
    lat = e.latlng.lat;
    lng = e.latlng.lng;
    $.ajax({
        type: "POST",
        dataType: "script",
        url: "/stash_datacite/geolocation_places/map_coordinates",
        data: { 'geo_location_place' : location_name, 'latitude' : lat, 'longitude' : lng, 'resource_id' : $.urlParam('resource_id') }
      });
    marker = new L.Marker([lat, lng], { icon: customIcon }).addTo(map).bindPopup(location_name).openPopup();
  });

  // if(lat != null && lng != null) {
  //   geocoder.on('reset', function (e) {
  //     marker = new L.Marker([lat, lng], { icon: customIcon }).addTo(map).bindPopup(location_name).openPopup();
  //   });
  // }
  // -------------------------------- //

  // -------------------------------- //
  var group , markerArray = [];
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
      marker = new L.Marker(markerLocation, { draggable: true, id: mrk_id }).addTo(map);
      markerArray.push(new L.Marker(markerLocation, { id: mrk_id }));
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
              alert("error occured");
            }
          });
      });
    }

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
        // map.fitBounds(bounds);
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


      group = L.featureGroup(markerArray).addTo(map);
      map.fitBounds(group.getBounds());
  // -------------------------------- //


  // LEAFLET DRAW PLUGIN CODE FOR CREATING MARKERS, EDITING MARKERS, DELETING MARKERS & CREATING BOUNDING BOXES
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

        // ----------------------------Bounding Box--------------------------------- //
        if (type == "rectangle") {
          var rectangle_coordinates = getShapes(drawnItems);
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
        // ------------------------------------------------------------- //

        // -------------------------------Marker------------------------------ //
        if (type == "marker") {
          //obtain latlng coordinates from the shape marker of map
          var marker_coordinates = getShapes(drawnItems).toString().split(",");
          var result = false;
          $.ajax({
            type: "POST",
            dataType: "json",
            async: false,
            url: "/stash_datacite/geolocation_points/map_coordinates",
            data: { 'latitude' : marker_coordinates[0], 'longitude' : marker_coordinates[1],
                    'resource_id' : resource_id, 'id': marker_coordinates[2] },
            success: function(data) {
              result = data;
              updateGeolocationPointsIndex();
            },
            error: function() {
              alert('error occured');
            }
          });
            e.layer.options.id = result;
        }

        // ------------------------------------------------------------- //

        dragMarker(drawnItems);
        // e.layer.on("popupopen", onPopupClick);
      });


    // ------------------------------------------------------------- //
      // Function to get coordinates based on the layer drawn.
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
              var id = "";
              coordinates.push([layer.getLatLng().lat, layer.getLatLng().lng], id);
              layer.dragging.enable();
              drawPopup(layer, layer.getLatLng().lat, layer.getLatLng().lng);
            }
        });
        return coordinates;
      };
    // ------------------------------------------------------------- //
    // ------------------------------------------------------------- //
      // Function to Drag a Marker and Update to db.
        var dragMarker =  function(drawnItems) {
          drawnItems.eachLayer(function(layer) {
            var changedPos;
            if (layer instanceof L.Marker) {
                layer.on('dragend', function(event) {
                  changedPos = event.target.getLatLng();
                  drawPopup(layer, changedPos.lat, changedPos.lng);
                  $.ajax({
                    type: "PUT",
                    dataType: "script",
                    url: "/stash_datacite/geolocation_points/update_coordinates",
                    data: { 'latitude' :  changedPos.lat, 'longitude' :  changedPos.lng,
                           'resource_id' : $.urlParam('resource_id'), 'id' : layer.options.id },
                    success: function() {
                      updateGeolocationPointsIndex();
                    },
                    error: function() {
                      alert("error occured");
                    }
                  });
                });
            };
          });
        };

    // ------------------------------------------------------------- //
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
                alert("error occured");
              }
          });
        }

    // ------------------------------------------------------------- //
};

$.urlParam = function(name){
  var results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href);
  return results[1] || 0;
}

// Delete marker from map and db
function onPopupOpen(marker) {

}

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
}
// -------------------------------- //