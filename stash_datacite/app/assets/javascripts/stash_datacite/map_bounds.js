/**
 * Convert bounding box string to Leaflet LatLngBounds.
 * @param {String} bbox Space-separated string of sw-lng sw-lat ne-lng ne-lat
 * @return {L.LatLngBounds} Converted Leaflet LatLngBounds object
 */
L.bboxToBounds = function(bbox) {
  bbox = bbox.split(' ');
  if (bbox.length === 4) {
    return L.latLngBounds([[bbox[1], bbox[0]], [bbox[3], bbox[2]]]);
  } else {
    return null;
  }
};

// adjusts the leaflet map to fit the points/boxes/places already defined
function mapBounds(){
  bbox = undefined;

  // remove empty data-bbox elements
  $("[data-bbox='']").each(function() {
    $( this ).removeAttr("data-bbox");
  });
  $('[data-bbox]').each(function() {
    bb = $(this).data().bbox;
    if(bb) {
      if (typeof bbox === 'undefined') {
        bbox = L.bboxToBounds(bb);
      } else {
        bbox.extend(L.bboxToBounds(bb));
      }
    }
  });

  // map has no view, so set it to california
  if (typeof bbox === 'undefined'){
    bbox = L.bboxToBounds("-124.89 32.13 -114.25 42.36");
  }

  // nudge to expand the map a bit if it's too small and looks hideous.
  ne = bbox.getNorthEast();
  sw = bbox.getSouthWest();
  small = 0.025;
  small2 = small / 2;
  if(Math.abs(ne.lat - sw.lat) < small && Math.abs(ne.lng - sw.lng) < small){
    bbox.extend(L.bboxToBounds((sw.lng - small2) + " " + (sw.lat - small2) + " " + (ne.lng + small2) + " " + (ne.lat + small2)));
  }

  return bbox;
  // return [ [bbox.getSouth(), bbox.getWest() ], [ bbox.getNorth(), bbox.getEast() ] ];
  // return [ bbox.getSouthWest(), bbox.getNorthEast() ];
}