// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
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

// -------------------------------------------------- //
// latitidue longitude vlaidation for Geolcoation Point
$(document).ready(function(){
  $("#geo_lat_point").on('blur', function(e){
  var lat = $(this).val();
  var latReg = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lat == "") {
      return false;
    }
    else if (!latReg.test(lat)) {
      alert("Please enter valid latitude value");
      $('#geo_lat_point').val('');
    }
  });
});

$(document).ready(function(){
  $("#geo_lng_point").on('blur', function(e){
  var lng = $(this).val();
  var lngReg = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lng == "") {
      return false;
    }
    else if(!lngReg.test(lng)) {
      alert("Please enter valid longitude value")
      $('#geo_lng_point').val('');
    }
  });
});
// -------------------------------------------------- //


// -------------------------------------------------- //
// latitidue longitude vlaidation for Geolcoation Box
$(document).ready(function(){
  $("#geo_sw_lat_point").on('blur', function(e){
  var lat = $(this).val();
  var latReg = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lat == "") {
      return false;
    }
    else if (!latReg.test(lat)) {
      alert("Please enter valid latitude value");
      $('#geo_sw_lat_point').val('');
    }
  });
});


$(document).ready(function(){
  $("#geo_ne_lat_point").on('blur', function(e){
  var lat = $(this).val();
  var latReg = /^(\+|-)?(?:90(?:(?:\.0{1,6})?)|(?:[0-9]|[1-8][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lat == "") {
      return false;
    }
    else if (!latReg.test(lat)) {
      alert("Please enter valid latitude value");
      $('#geo_ne_lat_point').val('');
    }
  });
});

$(document).ready(function(){
  $("#geo_sw_lng_point").on('blur', function(e){
  var lng = $(this).val();
  var lngReg = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lng == "") {
      return false;
    }
    else if(!lngReg.test(lng)) {
      alert("Please enter valid longitude value")
      $('#geo_sw_lng_point').val('');
    }
  });
});

$(document).ready(function(){
  $("#geo_ne_lng_point").on('blur', function(e){
  var lng = $(this).val();
  var lngReg = /^(\+|-)?(?:180(?:(?:\.0{1,6})?)|(?:[0-9]|[1-9][0-9]|1[0-7][0-9])(?:(?:\.[0-9]{1,6})?))$/;
    if(lng == "") {
      return false;
    }
    else if(!lngReg.test(lng)) {
      alert("Please enter valid longitude value")
      $('#geo_ne_lng_point').val('');
    }
  });
});

// -------------------------------------------------- //