importScripts('./client-zip/lengthWorker.js', './client-zip/makeZipWorker.js', './dl-stream/worker.js');
// './client-zip/worker.js',

const messagePorts = {};

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'PORT_INITIALIZATION') {
    messagePorts[event.data.url] = event.ports[0];
  }
});

self.addEventListener('fetch', (event) => {
  // This will intercept all request with a URL containing /downloadZip/ ;
  const url = new URL(event.request.url);
  const [, name] = url.pathname.match(/\/downloadZip\/(.+)/i) || [,];
  if (url.origin === self.origin && name) {
    event.respondWith(event.request.formData()
      .then((data) => {
        const urls = data.getAll('url')
        if (urls.length === 0) throw new Error('No URLs to download');
        if (messagePorts[event.request.url]) {
          messagePorts[event.request.url].postMessage({type: 'DOWNLOAD_STATUS', msg: 'Download started'});
        }
        const metadata = data.getAll('size').map((s, i) => ({name: data.getAll('filename')[i], size: s}));
        const total = predictLength(metadata);
        const headers = {
          'Content-Type': 'application/zip',
          'Content-Disposition': `attachment;filename="${name}"`,
          'Content-Length': total,
        };
        if (messagePorts[event.request.url]) {
          messagePorts[event.request.url].postMessage({type: 'DOWNLOAD_STATUS', msg: 'Headers', size: total, filename: name});
        }
        const [checkStream, printStream] = makeZip(new DownloadStream(urls), {metadata}).tee();
        const reader = checkStream.getReader();
        let bytes = 0;
        reader.read().then(function processText({done, value}) {
          if (done) {
            if (messagePorts[event.request.url]) messagePorts[event.request.url].postMessage({type: 'DOWNLOAD_STATUS', msg: 'Stream complete'});
            return;
          }
          bytes += value.length;
          if (messagePorts[event.request.url]) messagePorts[event.request.url].postMessage({type: 'DOWNLOAD_STATUS', msg: 'Streaming', complete: bytes/Number(total)});
          return reader.read().then(processText);
        });
        return new Response(printStream, {headers});
        // return downloadZip(new DownloadStream(data.getAll('url')), {metadata});
      })
      .catch((err) => new Response(err.message, {status: 500})));
  }
});
