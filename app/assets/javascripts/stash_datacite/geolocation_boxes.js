// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadGeolocationBoxes() {
  $("#geolocation_box").hide();
    $("#geo_box").on('click', function(e){
      $("#geolocation_box").show();
      $("#geolocation_point").hide();
      $('.js-location__box-button').removeClass('c-location__box-button');
      $('.js-location__box-button').addClass('c-location__box-button--active');
      $('.js-location__point-button').removeClass('c-location__point-button--active');
      $('.js-location__point-button').addClass('c-location__point-button');
    });

    // latitiude longitude validation for Geolocation Box
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
};
