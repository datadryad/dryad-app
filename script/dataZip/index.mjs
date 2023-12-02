import stream, {PassThrough} from 'stream';
import fetch from 'node-fetch';
import util from 'util';
import archiver from 'archiver';

const pipeline = util.promisify(stream.pipeline);

export const handler = awslambda.streamifyResponse(async (event, responseStream) => {
  const {filename, download_url} = event.queryStringParameters;
  const headers = {
    'Content-Type': 'application/zip',
    'Content-Disposition': `attachment;filename="${filename}"`
  };
  const requestStream = new PassThrough();
  const streamResponse = awslambda.HttpResponseStream.from(responseStream, {
    statusCode: 200,
    headers,
  });
  const archive = archiver('zip', {forceZip64: true, zlib: {level: 0}});
  streamResponse.on('close', () => {
    console.log('The archive is complete and the stream is closed');
  });
  streamResponse.on('finish', () => {
    console.log('Stream is finished');
  });
  streamResponse.on('end', () => {
    console.log('Data has been drained');
  });
  streamResponse.on('error', (err) => {
    throw err;
  })
  archive.on('error', (err) => {
    throw err;
  });
  archive.pipe(streamResponse);
  const response = await fetch(download_url, {
    method: 'GET', 
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }
  })
  if (!response.ok) throw new Error('Unable to retrieve dataset file URLs');
  const files = await response.json();
  for (const f of files) {
    const content = await fetch(f.url);
    archive.append(content.body, {name: f.filename});
    requestStream.pipe(content.body);
  }
  archive.finalize();
  await pipeline(requestStream, streamResponse);
});
