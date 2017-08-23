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

    // latitude validation for Geolcoation Point
    $("#geo_lat_point").on('blur', function(e){
      var lat = $(this).val();
      if(lat == "") {
        return false;
      }
      isLatitude(lat);
    });

    //longitude validation for Geolcoation Point
    $("#geo_lng_point").on('blur', function(e){
      var lng = $(this).val();
      if(lng == "") {
        return false;
      }
      isLongitude(lng);
    });

    $("#geolocation_point_new_form").submit(function() {
      if ($.trim($("#geo_lat_point").val()) === "" || $.trim($("#geo_lng_point").val()) === "") {
        alert('please fill in both latitude and longitude fields');
        return false;
      }
    });
};

function isLatitude(lat) {
  if(isFinite(lat) && Math.abs(lat) <= 90) {
    return lat;
  }
  else {
    alert("Please enter a valid latitude value. The valid range is -90 to +90 degrees from the equator.");
    $('#geo_lat_point').val('');
  }
}

function isLongitude(lng) {
  if(isFinite(lng) && Math.abs(lng) <= 180){
    return lng;
  }
  else {
    alert("Please enter a valid longitude value.The valid range is -180 to +180 degrees from the prime meridian.")
    $('#geo_lng_point').val('');
  }
}