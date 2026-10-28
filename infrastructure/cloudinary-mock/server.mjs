import crypto from 'node:crypto';
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';

const PORT = Number(process.env.PORT || 8099);
const PUBLIC_BASE_URL = (process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`).replace(/\/+$/, '');
const STORAGE_DIR = process.env.STORAGE_DIR || '/tmp/cloudinary-storage';
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const FORMATS = new Map([
  ['image/png', 'png'],
  ['image/jpeg', 'jpg'],
  ['image/webp', 'webp'],
]);

fs.mkdirSync(STORAGE_DIR, { recursive: true });

function storedFileCount(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).reduce((count, entry) => {
    const entryPath = path.join(directory, entry.name);
    return count + (entry.isDirectory() ? storedFileCount(entryPath) : 1);
  }, 0);
}

function safePath(value) {
  const segments = value.split('/').filter(Boolean);
  if (segments.length === 0 || segments.some((segment) => segment === '.' || segment === '..'
      || !/^[\w.-]+$/.test(segment))) {
    return null;
  }
  return segments.join('/');
}

function contentType(buffer) {
  if (buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
    return 'image/png';
  }
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return 'image/jpeg';
  }
  if (buffer.length >= 12 && buffer.toString('ascii', 0, 4) === 'RIFF'
      && buffer.toString('ascii', 8, 12) === 'WEBP') {
    return 'image/webp';
  }
  return null;
}

function multipartParts(body, boundary) {
  const delimiter = Buffer.from(`--${boundary}`);
  const parts = [];
  let position = body.indexOf(delimiter);

  while (position !== -1) {
    position += delimiter.length;
    if (body.subarray(position, position + 2).equals(Buffer.from('--'))) break;
    if (body.subarray(position, position + 2).equals(Buffer.from('\r\n'))) position += 2;

    const next = body.indexOf(delimiter, position);
    if (next === -1) break;
    let part = body.subarray(position, next);
    if (part.subarray(part.length - 2).equals(Buffer.from('\r\n'))) {
      part = part.subarray(0, part.length - 2);
    }

    const separator = part.indexOf(Buffer.from('\r\n\r\n'));
    if (separator !== -1) {
      const headers = part.subarray(0, separator).toString('latin1');
      const disposition = headers.match(/;\s*name="([^"]+)"/i);
      if (disposition) {
        parts.push({
          name: disposition[1],
          headers,
          value: part.subarray(separator + 4),
        });
      }
    }
    position = next;
  }
  return parts;
}

function readUpload(body, contentTypeHeader) {
  const boundary = contentTypeHeader?.match(/boundary=(?:"([^"]+)"|([^;]+))/i);
  const parts = boundary ? multipartParts(body, (boundary[1] || boundary[2]).trim()) : [];
  const fields = new Map(parts.filter((part) => !/filename="/i.test(part.headers))
    .map((part) => [part.name, part.value.toString('utf8')]));
  const file = parts.find((part) => part.name === 'file');

  if (file) {
    const dataUri = file.value.toString('utf8').match(/^data:(image\/[^;,]+);base64,([\s\S]+)$/);
    return {
      folder: fields.get('folder'),
      bytes: dataUri ? Buffer.from(dataUri[2], 'base64') : file.value,
    };
  }

  const rawBody = body.toString('utf8').trim();
  const dataUri = rawBody.match(/^data:(image\/[^;,]+);base64,([\s\S]+)$/)
    || rawBody.match(/"file"\s*:\s*"data:(image\/[^;,]+);base64,([^"]+)"/);
  if (dataUri) {
    return { folder: fields.get('folder'), bytes: Buffer.from(dataUri[2], 'base64') };
  }
  return null;
}

function jsonResponse(res, status, data) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data));
}

async function readRequestBody(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_UPLOAD_BYTES) {
      const error = new Error('Upload exceeds the 10 MB mock limit');
      error.status = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(204).end();
    return;
  }

  const requestUrl = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  if (req.method === 'GET' && requestUrl.pathname === '/health') {
    jsonResponse(res, 200, {
      status: 'UP',
      service: 'cloudinary-mock',
      storedFiles: storedFileCount(STORAGE_DIR),
    });
    return;
  }

  const uploadMatch = requestUrl.pathname.match(/^\/v1_1\/([^/]+)\/image\/upload\/?$/);
  if (req.method === 'POST' && uploadMatch) {
    try {
      const body = await readRequestBody(req);
      const upload = readUpload(body, req.headers['content-type']);
      if (!upload?.bytes?.length) {
        jsonResponse(res, 400, { error: { message: 'A non-empty image file is required' } });
        return;
      }
      if (upload.bytes.length > MAX_UPLOAD_BYTES) {
        jsonResponse(res, 413, { error: { message: 'Upload exceeds the 10 MB mock limit' } });
        return;
      }

      const mimeType = contentType(upload.bytes);
      const format = mimeType && FORMATS.get(mimeType);
      if (!format) {
        jsonResponse(res, 415, { error: { message: 'Only PNG, JPEG, and WebP images are supported' } });
        return;
      }

      const cloudName = safePath(decodeURIComponent(uploadMatch[1]));
      const folder = safePath(upload.folder || 'pe-na-areia/uploads');
      if (!cloudName || !folder) {
        jsonResponse(res, 400, { error: { message: 'Invalid cloud name or folder' } });
        return;
      }

      const publicId = `${folder}/${crypto.randomBytes(12).toString('hex')}`;
      const filePath = path.join(STORAGE_DIR, `${publicId}.${format}`);
      fs.mkdirSync(path.dirname(filePath), { recursive: true });
      fs.writeFileSync(filePath, upload.bytes);

      const version = 1;
      const encodedPublicId = publicId.split('/').map(encodeURIComponent).join('/');
      const url = `${PUBLIC_BASE_URL}/${encodeURIComponent(cloudName)}/image/upload/v${version}/${encodedPublicId}.${format}`;
      jsonResponse(res, 200, {
        asset_id: crypto.createHash('sha1').update(publicId).digest('hex'),
        public_id: publicId,
        version,
        version_id: String(version),
        format,
        resource_type: 'image',
        bytes: upload.bytes.length,
        url,
        secure_url: url,
      });
    } catch (error) {
      jsonResponse(res, error.status || 500, {
        error: { message: error.status ? error.message : 'Unable to process upload' },
      });
    }
    return;
  }

  const imageMatch = requestUrl.pathname.match(/^\/([^/]+)\/image\/upload\/v\d+\/(.+)$/);
  if (req.method === 'GET' && imageMatch) {
    try {
      const resource = decodeURIComponent(imageMatch[2]);
      const match = resource.match(/^(.*)\.(png|jpe?g|webp)$/i);
      const publicId = match && safePath(match[1]);
      const extension = match?.[2].toLowerCase();
      const filePath = publicId && path.join(STORAGE_DIR, `${publicId}.${extension}`);
      if (filePath && fs.existsSync(filePath)) {
        res.writeHead(200, {
          'Content-Type': extension === 'jpg' || extension === 'jpeg' ? 'image/jpeg' : `image/${extension}`,
          'Cache-Control': 'public, max-age=31536000, immutable',
        });
        fs.createReadStream(filePath).pipe(res);
        return;
      }
    } catch {
      // Invalid URL encoding or path is handled as a missing image.
    }
    jsonResponse(res, 404, { error: { message: 'Image not found' } });
    return;
  }

  jsonResponse(res, 404, { error: { message: 'Route not found in cloudinary-mock' } });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[cloudinary-mock] listening on 0.0.0.0:${PORT} (public=${PUBLIC_BASE_URL})`);
});
