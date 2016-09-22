// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function getAndLoadGeoPlace(resource_id) {
  // Get GeoLocation Place Names from db and load on map
  var locationNames = getLocationNames(resource_id);  // Function is called, return value will end up in an array
  function getLocationNames(resource_id) {
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
      // arr = $.map(result, function(n){
      //    return [[ n["geo_location_place"], n["latitude"], n["longitude"], n["id"] ]];
      // });
      return(result);
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
};
