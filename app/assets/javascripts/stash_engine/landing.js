// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

const downloading = (function() {
    return {
        percentComplete: function(elapsed, expectedLength) {
            return Math.round(elapsed / expectedLength * 100);
        },

        neverComplete: function(elapsed, expectedLength) {
            var comp = elapsed / expectedLength;
            if(comp < 0.5) {
                return Math.round(comp * 100);
            }
            // this formula will slow progress more and more as it approaches 1 (100%)
            return Math.round((Math.pow(Math.E, comp - 0.3) / (Math.pow(Math.E, comp - 0.3) + 1.2)) * 100);
        },

        updateBar: function(elapsed, expectedLength) {
            var myPercentComplete = this.neverComplete(elapsed, expectedLength);
            if(myPercentComplete > 97 ){
                myPercentComplete = 97; // haha, never gets to 100% for wildy offbase estimates for large objects from Merritt
            }
            $( "#progressbar" ).progressbar( "option", "value", myPercentComplete );
        },

        elapsedSeconds: function(startedAt) {
            return ((new Date()).getTime() - startedAt.getTime()) / 1000;
        }
    };
})();