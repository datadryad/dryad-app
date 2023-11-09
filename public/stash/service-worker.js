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
    if (name === 'keep-alive') {
      event.respondWith(new Response('', {status: 200}));
    } else {
      event.respondWith(event.request.formData()
        .then((data) => {
          const metadata = data.getAll('size').map((s, i) => ({name: data.getAll('filename')[i], size: s}));
          const headers = {
            'Content-Type': 'application/zip',
            'Content-Disposition': `attachment;filename="${name}"`,
            'Content-Length': predictLength([{name, size: 0}].concat(metadata)),
          };
          const [checkStream, printStream] = makeZip(new DownloadStream(data.getAll('url')), {metadata}).tee();
          const reader = checkStream.getReader();
          reader.read().then(function processText({done}) {
            if (done && messagePorts[event.request.url]) {
              messagePorts[event.request.url].postMessage({type: 'DOWNLOAD_STATUS', msg: 'Stream complete'});
              return;
            }
            return reader.read().then(processText);
          });
          return new Response(printStream, {headers});
          // return downloadZip(new DownloadStream(data.getAll('url')), {metadata});
        })
        .catch((err) => new Response(err.message, {status: 500})));
    }
  }
});
