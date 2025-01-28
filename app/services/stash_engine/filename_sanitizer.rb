# frozen_string_literal: true

# similar with app/javascript/lib/sanitize_filename.js
#
# Replaces characters in strings that are illegal/unsafe for filenames.
# Unsafe characters are either removed or replaced by a substitute set in the optional `options` object.
#
# Illegal Characters on Various Operating Systems
# / ? < > \ : * | "
# https://kb.acronis.com/content/39790
#
# Unicode Control codes
# C0 0x00-0x1f & C1 (0x80-0x9f)
# http://en.wikipedia.org/wiki/C0_and_C1_control_codes
#
# Reserved filenames on Unix-based systems (".", "..")
# Reserved filenames in Windows
# (
#   "CON", "PRN", "AUX", "NUL", "COM1",
#   "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
#   "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
# ) case-insensitively and with or without filename extensions.
#
# Capped at 255 characters in length.
# http://unix.stackexchange.com/questions/32795/what-is-the-maximum-allowed-filename-and-folder-size-with-ecryptfs

module StashEngine
  class FilenameSanitizer
    ILLEGAL_RE          = %r{[/?<>\\:*|\"]}
    CONTROL_RE          = /[\x00-\x1f]/
    RESERVED_RE         = /^\.+$/
    WINDOWS_RESERVED_RE = /^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$/i
    WINDOWS_TRAILING_RE = /[. ]+$/
    S3_BADIES           = /[&$@=;+,{\}^%`\[\]~#']/
    DRYAD_UNLIKED       = /[ ]/

    attr_reader :filename, :replacement

    def initialize(filename, replacement: '_')
      @filename    = filename.to_s
      @replacement = replacement.to_s
    end

    def process
      output = filename.gsub(ILLEGAL_RE, replacement)
        .gsub(CONTROL_RE, replacement)
        .gsub(RESERVED_RE, replacement)
        .gsub(WINDOWS_RESERVED_RE, replacement)
        .gsub(WINDOWS_TRAILING_RE, replacement)
        .gsub(S3_BADIES, replacement)
        .gsub(DRYAD_UNLIKED, replacement)

      truncate_utf8(output, 220)
    end

    private

    def truncate_utf8(string, max_bytes)
      bytes = string.bytes.take(max_bytes)
      bytes.pack('C*').force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    end
  end
end
