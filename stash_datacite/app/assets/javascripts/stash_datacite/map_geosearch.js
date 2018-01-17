// add mapGeosearch to the map
function mapGeosearch(map){
  const provider = new window.GeoSearch.OpenStreetMapProvider();
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
    $('.glass').val('');
  });
}