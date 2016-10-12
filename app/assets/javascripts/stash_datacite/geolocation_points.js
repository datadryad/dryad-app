// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadGeolocationPoints() {
  $("#geolocation_point_new_form").show();
    $("#geo_point").on('click', function(e){
      $("#geolocation_box_new_form").hide();
      $("#geolocation_point_new_form").show();
      $('.js-location__point-button').removeClass('c-location__point-button');
      $('.js-location__point-button').addClass('c-location__point-button--active');
      $('.js-location__box-button').removeClass('c-location__box-button--active');
      $('.js-location__box-button').addClass('c-location__box-button');
    });

    // latitude longitude validation for Geolcoation Point
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

    $("#geolocation_point_new_form").submit(function() {
      if ($.trim($("#geo_lat_point").val()) === "" || $.trim($("#geo_lng_point").val()) === "") {
        alert('please fill in both latitude and longitude fields');
        return false;
      }
    });
};