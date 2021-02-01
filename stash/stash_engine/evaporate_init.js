// var Evaporate = window.Evaporate || {};
// var Crypto = window.Crypto || {};

const Evaporate = require('evaporate');
const Crypto = require('crypto');
const AWS = require('aws-sdk');

// maybe this gets it working: https://github.com/webpack/webpack/issues/4072

window.Evaporate = Evaporate;
window.Crypto = Crypto;
window.AWS = AWS;

