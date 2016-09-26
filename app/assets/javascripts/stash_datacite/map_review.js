// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
function loadReviewMap(resource_id) {
  var resource_id = resource_id;
  // create a map in the "map" div, set the view to a given place and zoom
  map = L.map('map_review', { zoomControl: true }).setView([36.778259, -119.417931], 3);
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
        return(result);
      }

      //Loop through the markers array
      var marker;
      for (var i=0; i<coordinatesMarker.length; i++) {
        var lat = coordinatesMarker[i]['latitude'];
        var lng = coordinatesMarker[i]['longitude'];
        var mrk_id = coordinatesMarker[i]['id'];
        var markerLocation = new L.LatLng(lat, lng);
        marker = new L.Marker(markerLocation, { id: mrk_id }).bindPopup(lat +","+ lng).addTo(map);
      }

    getAndLoadGeoBox(resource_id);
    getAndLoadGeoPlace(resource_id);
};

/**
 * Convert bounding box string to Leaflet LatLngBounds.
 * @param {String} bbox Space-separated string of sw-lng sw-lat ne-lng ne-lat
 * @return {L.LatLngBounds} Converted Leaflet LatLngBounds object
 */
L.bboxToBounds = function(bbox) {
  bbox = bbox.split(' ');
  if (bbox.length === 4) {
    return L.latLngBounds([[bbox[1], bbox[0]], [bbox[3], bbox[2]]]);
  } else {
    return null;
  }
};

// adjusts the leaflet map to fit the points/boxes/places already defined
function mapBounds(){
  bbox = undefined;

  // remove empty data-bbox elements
  $("[data-bbox='']").each(function() {
    $( this ).removeAttr("data-bbox");
  });
  $('[data-bbox]').each(function() {
    bb = $(this).data().bbox;
    if(bb) {
      if (typeof bbox === 'undefined') {
        bbox = L.bboxToBounds(bb);
      } else {
        bbox.extend(L.bboxToBounds(bb));
      }
    }
  });

  // map has no view, so set it to california
  if (typeof bbox === 'undefined'){
    bbox = L.bboxToBounds("-124.89 32.13 -114.25 42.36");
  }

  // nudge to expand the map a bit if it's too small and looks hideous.
  ne = bbox.getNorthEast();
  sw = bbox.getSouthWest();
  small = 0.025;
  small2 = small / 2;
  if(Math.abs(ne.lat - sw.lat) < small && Math.abs(ne.lng - sw.lng) < small){
    bbox.extend(L.bboxToBounds((sw.lng - small2) + " " + (sw.lat - small2) + " " + (ne.lng + small2) + " " + (ne.lat + small2)));
  }

  return bbox;
  // return [ [bbox.getSouth(), bbox.getWest() ], [ bbox.getNorth(), bbox.getEast() ] ];
  // return [ bbox.getSouthWest(), bbox.getNorthEast() ];
}
