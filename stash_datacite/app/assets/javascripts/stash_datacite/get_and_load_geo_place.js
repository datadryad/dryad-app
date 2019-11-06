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
      return(result);
  }
  L.Icon.Default.imagePath = 'assets/images/stash_datacite';
  var customIcon = new L.Icon({
      // iconUrl: L.Icon.Default.imagePath +'/globe.png',
      iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0b/Blue_globe_icon.svg',
      iconSize: [25, 25], // size of the icon
      iconAnchor: [12, 25], // point of the icon which will correspond to marker's location
      popupAnchor: [0, -25] // point from which the popup should open relative to the iconAnchor
  });

  // Loop through the location names array
  for (var i=0; i<locationNames.length; i++) {
    var place = locationNames[i]['geolocation_place'];
    var lat   = locationNames[i]['latitude'];
    var lng   = locationNames[i]['longitude'];
    var mrk_id = locationNames[i]['id'];
    var newMarkerLocation = new L.LatLng(lat, lng);
    var marker = new L.marker(newMarkerLocation, { icon: customIcon, id: mrk_id }).addTo(map).bindPopup('<strong>' + place);
  }
// ----------------------------------------------------------------- //
};
