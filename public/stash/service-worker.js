console.log('service-worker.js loaded');
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
      console.log('keep-alive');
      event.respondWith(new Response('', {status: 200}));
    } else {
      console.log('not keep-alive');
      event.respondWith(event.request.formData()
          .then((data) => {
            console.log('data', data);
            // const resource_id = data.get('resource_id');
            // console.log('resource_id', resource_id);

            fetch('/stash/downloads/zip_assembly_info/4210', {credentials: 'include'})
                .then(response => {
                  if (!response.ok) {
                    throw new Error('Network response was not ok');
                  }
                  return response.json(); // Parse the response as JSON
                })
                .then(data => {
                  // Now you can work with the JSON data
                  console.log('data', data);
                  const metadata = data.map((x) => ({name: x.filename, size: x.size}));
                  console.log('metadata', metadata);
                  const urls = data.map((x) => x.url);
                  console.log('urls', urls);
                  const headers = {
                    'Content-Type': 'application/zip',
                    'Content-Disposition': `attachment;filename="${name}"`,
                    'Content-Length': predictLength([{name, size: 0}].concat(metadata)),
                  };
                  console.log('headers', headers);
                  const [checkStream, printStream] = makeZip(new DownloadStream(urls), {metadata}).tee();
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
            // .catch(error => {
            //   console.error('Error:', error);
            // });
          })
          .catch((err) => new Response(err.message, {status: 500})));
    }
  }
});
