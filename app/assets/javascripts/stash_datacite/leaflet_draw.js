// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// LEAFLET DRAW PLUGIN CODE FOR CREATING MARKERS, EDITING MARKERS, DELETING MARKERS & CREATING BOUNDING BOXES
function leafletDraw() {
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
            console.log('error occured');
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
                  console.log("error occured");
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