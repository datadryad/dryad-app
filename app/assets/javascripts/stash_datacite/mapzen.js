// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function mapzen() {
// MAPZEN AUTOCOMPLETE SEARCH AND SAVE TO DB
  var customIcon = new L.Icon({
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

  if(lat != null && lng != null) {
    geocoder.on('reset', function (e) {
      marker = new L.Marker([lat, lng], { icon: customIcon }).addTo(map).bindPopup(location_name).openPopup();
    });
  }
  // -------------------------------- //
};