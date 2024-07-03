// modified from https://github.com/bevry/istextorbinary/tree/8f26be8823bd006fd44de5d7352f961b163b996f

// ====================================
// The functions below are created to handle multibyte utf8 characters.
// To understand how the encoding works, check this article: https://en.wikipedia.org/wiki/UTF-8#Encoding
// @todo add documentation for these

function isFirstByteOf4ByteChar(byte) {
  // eslint-disable-next-line no-bitwise
  return byte >> 3 === 30; // 11110xxx?
}

function isFirstByteOf3ByteChar(byte) {
  // eslint-disable-next-line no-bitwise
  return byte >> 4 === 14; // 1110xxxx?
}

function isFirstByteOf2ByteChar(byte) {
  // eslint-disable-next-line no-bitwise
  return byte >> 5 === 6; // 110xxxxx?
}

function isLaterByteOfUtf8(byte) {
  // eslint-disable-next-line no-bitwise
  return byte >> 6 === 2; // 10xxxxxx?
}

function getChunkBegin(buf, chunkBegin) {
  // If it's the beginning, just return.
  if (chunkBegin === 0) {
    return 0;
  }

  if (!isLaterByteOfUtf8(buf[chunkBegin])) {
    return chunkBegin;
  }

  let begin = chunkBegin - 3;

  if (begin >= 0) {
    if (isFirstByteOf4ByteChar(buf[begin])) {
      return begin;
    }
  }

  begin = chunkBegin - 2;

  if (begin >= 0) {
    if (
      isFirstByteOf4ByteChar(buf[begin])
      || isFirstByteOf3ByteChar(buf[begin])
    ) {
      return begin;
    }
  }

  begin = chunkBegin - 1;

  if (begin >= 0) {
    // Is it a 4-byte, 3-byte utf8 character?
    if (
      isFirstByteOf4ByteChar(buf[begin])
      || isFirstByteOf3ByteChar(buf[begin])
      || isFirstByteOf2ByteChar(buf[begin])
    ) {
      return begin;
    }
  }

  return -1;
}

function getChunkEnd(buf, chunkEnd) {
  // If it's the end, just return.
  if (chunkEnd === buf.length) {
    return chunkEnd;
  }

  let index = chunkEnd - 3;

  if (index >= 0) {
    if (isFirstByteOf4ByteChar(buf[index])) {
      return chunkEnd + 1;
    }
  }

  index = chunkEnd - 2;

  if (index >= 0) {
    if (isFirstByteOf4ByteChar(buf[index])) {
      return chunkEnd + 2;
    }

    if (isFirstByteOf3ByteChar(buf[index])) {
      return chunkEnd + 1;
    }
  }

  index = chunkEnd - 1;

  if (index >= 0) {
    if (isFirstByteOf4ByteChar(buf[index])) {
      return chunkEnd + 3;
    }

    if (isFirstByteOf3ByteChar(buf[index])) {
      return chunkEnd + 2;
    }

    if (isFirstByteOf2ByteChar(buf[index])) {
      return chunkEnd + 1;
    }
  }

  return chunkEnd;
}

export function getEncoding(buffer, opts) {
  // Check
  if (!buffer) return null;

  // Prepare
  const textEncoding = 'utf8';
  const binaryEncoding = 'binary';
  const chunkLength = opts?.chunkLength ?? 24;
  let chunkBegin = opts?.chunkBegin ?? 0;

  // Discover
  if (opts?.chunkBegin == null) {
    // Start
    let encoding = getEncoding(buffer, {chunkLength, chunkBegin});
    if (encoding === textEncoding) {
      // Middle
      chunkBegin = Math.max(0, Math.floor(buffer.length / 2) - chunkLength);
      encoding = getEncoding(buffer, {
        chunkLength,
        chunkBegin,
      });
      if (encoding === textEncoding) {
        // End
        chunkBegin = Math.max(0, buffer.length - chunkLength);
        encoding = getEncoding(buffer, {
          chunkLength,
          chunkBegin,
        });
      }
    }

    // Return
    return encoding;
  }
  // Extract
  chunkBegin = getChunkBegin(buffer, chunkBegin);
  if (chunkBegin === -1) {
    return binaryEncoding;
  }

  const chunkEnd = getChunkEnd(
    buffer,
    Math.min(buffer.length, chunkBegin + chunkLength),
  );

  if (chunkEnd > buffer.length) {
    return binaryEncoding;
  }

  const contentChunkUTF8 = buffer.toString(textEncoding, chunkBegin, chunkEnd);

  // Detect encoding
  /* eslint-disable-next-line no-plusplus */
  for (let i = 0; i < contentChunkUTF8.length; ++i) {
    const charCode = contentChunkUTF8.charCodeAt(i);
    if (charCode === 65533 || charCode <= 8) {
      // 8 and below are control characters (e.g. backspace, null, eof, etc.)
      // 65533 is the unknown character
      // console.log(charCode, contentChunkUTF8[i])
      return binaryEncoding;
    }
  }

  // Return
  return textEncoding;
}

export function isText(buffer) {
  // Test encoding
  if (buffer) {
    return getEncoding(buffer) === 'utf8';
  }
  // No buffer was provided
  return null;
}
