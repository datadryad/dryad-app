const MAX_LENGTH = 60;

const ellipsisize = (url) => {
    if (url.length <= MAX_LENGTH) return url;

    return url.substring(0, MAX_LENGTH / 2) + '...' + url.substring(url.length - MAX_LENGTH / 2);
}

module.exports = (url) => {
    return ellipsisize(url);
}