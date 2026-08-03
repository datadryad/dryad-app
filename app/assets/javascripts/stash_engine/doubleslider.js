'use strict';

class DoubleSlider {
  constructor(track, least, most, values, formatter) {
    this.track = track
    this.least = least
    this.most = most
    this.values = values
    this.formatter = formatter

    this.leastVal = document.getElementById(`${least.id}-value`)
    this.leastIn = document.getElementById(`${least.id}-input`)
    this.mostVal = document.getElementById(`${most.id}-value`)
    this.mostIn = document.getElementById(`${most.id}-input`)

    window.addEventListener('load', this.fillColor.bind(this), true);
    window.addEventListener('load', this.fillColor.bind(this), true);

    this.least.addEventListener('input', this.getLeast.bind(this), true);
    this.most.addEventListener('input', this.getMost.bind(this), true);

    this.track.addEventListener('click', this.onTrackClick.bind(this), true);
  }

  fillColor() {
    var percent1 = (this.least.value / this.least.max) * 100;
    var percent2 = (this.most.value / this.least.max) * 100;
    this.track.style.background = `linear-gradient(to right, #dadae5 ${percent1}% , #6e9c2c ${percent1}% , #6e9c2c ${percent2}%, #dadae5 ${percent2}%)`;
  }

  getLeast(e) {
    if (parseInt(this.most.value) - parseInt(this.least.value) <= 0) {
      this.least.value = parseInt(this.most.value);
    }
    const val = this.values[this.least.value]
    const formatted = this.formatter(val)
    this.least.setAttribute('aria-valuetext', formatted)
    this.leastVal.textContent = formatted;
    this.leastIn.value = val;
    this.fillColor();
  }

  getMost(e) {
    if (parseInt(this.most.value) - parseInt(this.least.value) <= 0) {
      this.most.value = parseInt(this.least.value);
    }
    const val = this.values[this.most.value]
    const formatted = this.formatter(val)
    this.most.setAttribute('aria-valuetext', formatted)
    this.mostVal.textContent = formatted;
    this.mostIn.value = val;
    this.fillColor();
  }

  onTrackClick(e) {
    e.preventDefault();
    e.stopPropagation();
    const x = e.offsetX;
    const len = this.track.offsetWidth / this.values.length;
    const loc = Math.floor(x / len);

    const diffMin = Math.abs(this.least.value - loc);
    const diffMax = Math.abs(this.most.value - loc);
    const thumb = diffMax >= diffMin ? this.least : this.most;

    thumb.value = loc;
    thumb.dispatchEvent(new Event('input'));
  }
}
