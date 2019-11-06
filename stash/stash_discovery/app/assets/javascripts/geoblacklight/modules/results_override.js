Blacklight.onLoad(function() {
  var historySupported = !!(window.history && window.history.pushState);

  if (historySupported) {
    History.Adapter.bind(window, 'statechange', function() {
      var state = History.getState();
      updatePage(state.url);
    });
  }

  $('[data-map="index"]').each(function() {
    var data = $(this).data(),
    opts = { baseUrl: data.catalogPath },
    geoblacklight, bbox;

    if (typeof data.mapBbox === 'string') {
      bbox = L.bboxToBounds(data.mapBbox);
    } else {
      $('.document [data-bbox]').each(function() {
        bb = $(this).data().bbox;
        if(bb) {
          if (typeof bbox === 'undefined') {
            bbox = L.bboxToBounds(bb);
          } else {
            bbox.extend(L.bboxToBounds(bb));
          }
        }
      });
    }

    // map has no view, so set it to the world
    if (typeof bbox === 'undefined'){
      bbox = L.bboxToBounds("-180 -89.154124 180 89.154124");
    }

    // nudge to expand the map a bit if it's too small and looks hideous.
    ne = bbox.getNorthEast();
    sw = bbox.getSouthWest();
    small = 0.025;
    small2 = small / 2;
    if(Math.abs(ne.lat - sw.lat) < small && Math.abs(ne.lng - sw.lng) < small){
      bbox.extend(L.bboxToBounds((sw.lng - small2) + " " + (sw.lat - small2) + " " + (ne.lng + small2) + " " + (ne.lat + small2)));
    }


    if (!historySupported) {
      $.extend(opts, {
        dynamic: false,
        searcher: function() {
          window.location.href = this.getSearchUrl();
        }
      });
    }

    // instantiate new map
    geoblacklight = new GeoBlacklight.Viewer.Map(this, { bbox: bbox });

    // set hover listeners on map
    $('#content')
      .on('mouseenter', '#documents [data-layer-id]', function() {
        var bounds = L.bboxToBounds($(this).data('bbox'));
        geoblacklight.addBoundsOverlay(bounds);
      })
      .on('mouseleave', '#documents [data-layer-id]', function() {
        geoblacklight.removeBoundsOverlay();
      });

    // add geosearch control to map
    geoblacklight.map.addControl(L.control.geosearch(opts));
  });

  function updatePage(url) {
    $.get(url).done(function(data) {
      // var resp = $.parseHTML(data);
      // $doc = $(resp);
      $doc = $('<div/>').append(data);
      $('#documents').replaceWith($doc.find('#documents'));
      // keeps layout from going wonky (Stanford defaults) when no results from moving map.
      if($('#documents').hasClass('noresults')){
        $('#documents').removeClass('noresults').addClass('docView').addClass('col-md-6');
      }
      $('#sidebar').replaceWith($doc.find('#sidebar'));
      $('#sortAndPerPage').replaceWith($doc.find('#sortAndPerPage'));
      $('#appliedParams').replaceWith($doc.find('#appliedParams'));
      if ($('#map').next().length) {
        $('#map').next().replaceWith($doc.find('#map').next());
      } else {
        $('#map').after($doc.find('#map').next());
      }
    });
  }

});
