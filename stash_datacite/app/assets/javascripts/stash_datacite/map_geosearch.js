// add mapGeosearch to the map
function mapGeosearch(map){
  var customIcon = new L.Icon({
    iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0b/Blue_globe_icon.svg',
    iconSize: [25, 25], // size of the icon
    iconAnchor: [12, 25], // point of the icon which will correspond to marker's location
    popupAnchor: [0, -25] // point from which the popup should open relative to the iconAnchor
  });

  const provider = new window.GeoSearch.GoogleProvider({
    params: {
      key: googleMapsApiKey(),
    },
  });
  var gsc = new window.GeoSearch.GeoSearchControl({
    provider: provider,           // required
    style: 'bar',                   // optional: bar|button  - default button
    autoComplete: true,
    autoCompleteDelay: 250,
    autoClose: true,
    keepResult: false,
    searchLabel: 'Search location name',
    showMarker: false
  }).addTo(map);

  // fix css so it looks better in the corner of map
  $('.leaflet-control-geosearch.bar').css('margin', '10px auto 0 0').css('left', '10px');

  map.on('geosearch/showlocation', function(e) {
    // add marker on map
    location_name =  e.location.label;
    lat = e.location.y;
    lng = e.location.x;
    bnds = e.location.bounds;
    bbox = [ bnds[0][1], bnds[0][0], bnds[1][1], bnds[1][0] ];

    marker = new L.Marker([lat, lng], { icon: customIcon }).addTo(map).bindPopup(location_name).openPopup();

    // push it to the database and list below
    $.ajax({
      type: "POST",
      dataType: "script",
      url: "/stash_datacite/geolocation_places/map_coordinates",
      data: { 'geo_location_place' : location_name, 'latitude' : lat, 'longitude' : lng, 'bbox': bbox, 'resource_id' : $.urlParam('resource_id') }
    });

  });
}
