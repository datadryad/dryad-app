// var Evaporate = window.Evaporate || {};
// var Crypto = window.Crypto || {};

const Evaporate = require('evaporate');
const Crypto = require('crypto');
const AWS = require('aws-sdk');

// maybe this gets it working: https://github.com/webpack/webpack/issues/4072

window.Evaporate = Evaporate;
window.Crypto = Crypto;
window.AWS = AWS;



// This based on https://github.com/parshap/node-sanitize-filename/blob/master/index.js with some extras added
/**
 * Replaces characters in strings that are illegal/unsafe for filenames.
 * Unsafe characters are either removed or replaced by a substitute set
 * in the optional `options` object.
 *
 * Illegal Characters on Various Operating Systems
 * / ? < > \ : * | "
 * https://kb.acronis.com/content/39790
 *
 * Unicode Control codes
 * C0 0x00-0x1f & C1 (0x80-0x9f)
 * http://en.wikipedia.org/wiki/C0_and_C1_control_codes
 *
 * Reserved filenames on Unix-based systems (".", "..")
 * Reserved filenames in Windows ("CON", "PRN", "AUX", "NUL", "COM1",
 * "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
 * "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", and
 * "LPT9") case-insesitively and with or without filename extensions.
 *
 * Capped at 255 characters in length.
 * http://unix.stackexchange.com/questions/32795/what-is-the-maximum-allowed-filename-and-folder-size-with-ecryptfs
 *
 * @param  {String} input   Original filename
 * @param  {Object} options {replacement: String | Function }
 * @return {String}         Sanitized filename
 */

var truncate = require("truncate-utf8-bytes");

var illegalRe = /[\/\?<>\\:\*\|"]/g;
var controlRe = /[\x00-\x1f\x80-\x9f]/g;
var reservedRe = /^\.+$/;
var windowsReservedRe = /^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$/i;
var windowsTrailingRe = /[\. ]+$/;
var s3Baddies = /[&$@=;+,\{\}\^%`\[\]~#']/g;
var dryadUnliked = /[ ]/g

function sanitize(input, replacement) {
  if (typeof input !== 'string') {
    throw new Error('Input must be string');
  }
  var sanitized = input
      .replace(illegalRe, replacement)
      .replace(controlRe, replacement)
      .replace(reservedRe, replacement)
      .replace(windowsReservedRe, replacement)
      .replace(windowsTrailingRe, replacement)
      .replace(s3Baddies, replacement)
      .replace(dryadUnliked, replacement);
  return truncate(sanitized, 220);
}

// Space – Significant sequences of spaces might be lost in some uses (especially multiple spaces)

window.file_sanitize = function (input, options) {
  var replacement = (options && options.replacement) || '_';
  var output = sanitize(input, replacement);
  // TODO (cacods): seems `replacement` to never be equal ''
  if (replacement === '') {
    return output;
  }
  return sanitize(output, '');
};