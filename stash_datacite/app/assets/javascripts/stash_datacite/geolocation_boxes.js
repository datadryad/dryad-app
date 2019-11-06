// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function loadGeolocationBoxes() {
  $("#geolocation_box_new_form").hide();
    $("#geo_box").on('click', function(e){
      $("#geolocation_box_new_form").show();
      $("#geolocation_point_new_form").hide();
      $('.js-location__box-button').removeClass('c-location__box-button');
      $('.js-location__box-button').addClass('c-location__box-button--active');
      $('.js-location__point-button').removeClass('c-location__point-button--active');
      $('.js-location__point-button').addClass('c-location__point-button');
    });

    // latitiude longitude validation for Geolocation Box
    $("#geo_sw_lat_point").on('blur', function(e){
      var lat = $(this).val();
      if(lat == "") {
        return false;
      }
      isLatitude(lat);
    });

    $("#geo_ne_lat_point").on('blur', function(e){
    var lat = $(this).val();
      if(lat == "") {
        return false;
      }
      isLatitude(lat);
    });

    $("#geo_sw_lng_point").on('blur', function(e){
      var lng = $(this).val();
      if(lng == "") {
        return false;
      }
      isLongitude(lng);
    });

    $("#geo_ne_lng_point").on('blur', function(e){
    var lng = $(this).val();
      if(lng == "") {
        return false;
      }
      isLongitude(lng);
    });

    $("#geolocation_box_new_form").submit(function() {
      if ($.trim($("#geo_sw_lat_point").val()) === "" || $.trim($("#geo_ne_lat_point").val()) === "" || $.trim($("#geo_sw_lng_point").val()) === "" || $.trim($("#geo_ne_lng_point").val()) === "") {
        alert('please fill in all the bounding box fields');
        return false;
      }
    });
};
