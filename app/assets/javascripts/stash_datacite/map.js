// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
var map;
$(document).ready(function() {
  map = L.map('map', {
    layers: MQ.mapLayer()
  });


 var place = $('#geo_place').val();

  MQ.geocode().search(place)
     .on('success', function(e) {
         var best = e.result.best,
             latlng = best.latlng;

         map.setView(latlng, 12);

         L.marker([ latlng.lat, latlng.lng ])
             .addTo(map)
             .bindPopup( place )
             .openPopup()
         });

  // map = L.map('map').setView([51.505, -0.09], 13);
  // var layer = L.tileLayer("http://otile{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png", {
  //     subdomains: "1234",
  //     attribution: "&copy; <a href='http://www.openstreetmap.org/'>OpenStreetMap</a> and contributors, under an <a href='http://www.openstreetmap.org/copyright' title='ODbL'>open license</a>. Tiles Courtesy of <a href='http://www.mapquest.com/'>MapQuest</a> <img src='http://developer.mapquest.com/content/osm/mq_logo.png'>"
  // })

  // layer.addTo(map);
  // map.attributionControl.setPrefix(''); // Don't show the 'Powered by Leaflet' text. Attribution overload

  // var marker = L.marker([51.5, -0.09]).addTo(map);

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
