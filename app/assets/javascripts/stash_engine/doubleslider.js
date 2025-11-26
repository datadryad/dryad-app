'use strict';

class DoubleSlider {
  constructor(track, least, most, values) {
    this.track = track
    this.least = least
    this.most = most
    this.values = values

    this.leastVal = document.getElementById(`${least.id}-value`)
    this.leastIn = document.getElementById(`${least.id}-input`)
    this.mostVal = document.getElementById(`${most.id}-value`)
    this.mostIn = document.getElementById(`${most.id}-input`)

    window.addEventListener('load', this.fillColor.bind(this), true);
    window.addEventListener('load', this.fillColor.bind(this), true);

    this.least.addEventListener('input', this.getLeast.bind(this), true);
    this.most.addEventListener('input', this.getMost.bind(this), true);
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
    this.leastVal.textContent = this.values[this.least.value];
    this.leastIn.value = this.values[this.least.value];
    this.fillColor();
  }

  getMost(e) {
    if (parseInt(this.most.value) - parseInt(this.least.value) <= 0) {
      this.most.value = parseInt(this.least.value);
    }
    this.mostVal.textContent = this.values[this.most.value];
    this.mostIn.value = this.values[this.most.value];
    this.fillColor();
  }
}
