const fs = require('node:fs');
const http = require('node:http');
const https = require('node:https');
const path = require('node:path');

const projectRoot = __dirname;
const webRoot = path.join(projectRoot, 'eduportal_app', 'build', 'web');
const certificateRoot = path.join(projectRoot, 'eduportal_app', 'lan-certs');
const certificatePath = path.join(certificateRoot, 'server-cert.pem');
const privateKeyPath = path.join(certificateRoot, 'server-key.pem');
const caCertificatePath = path.join(certificateRoot, 'lan-ca.cer');
const apiHost = process.env.API_HOST || '127.0.0.1';
const apiPort = Number(process.env.API_PORT || 8000);
const port = Number(process.env.PORT || 3000);
const certPort = Number(process.env.CERT_PORT || 0);
const host = process.env.HOST || '0.0.0.0';
const lanIp = process.env.LAN_IP || '192.168.0.133';

for (const requiredPath of [path.join(webRoot, 'index.html'), certificatePath, privateKeyPath, caCertificatePath]) {
  if (!fs.existsSync(requiredPath)) {
    console.error(`Required file not found: ${requiredPath}`);
    process.exit(1);
  }
}

const contentTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
};

function sendError(response, status, message) {
  response.writeHead(status, {
    'Content-Type': 'text/plain; charset=utf-8',
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(message);
}

const server = https.createServer(
  {
    cert: fs.readFileSync(certificatePath),
    key: fs.readFileSync(privateKeyPath),
  },
  (request, response) => {
    let pathname;
    try {
      pathname = decodeURIComponent(new URL(request.url, 'https://localhost').pathname);
    } catch {
      sendError(response, 400, 'Invalid request path');
      return;
    }

    if (pathname === '/api' || pathname.startsWith('/api/')) {
      const proxyRequest = http.request(
        {
          host: apiHost,
          port: apiPort,
          method: request.method,
          path: request.url,
          headers: {
            ...request.headers,
            host: `${apiHost}:${apiPort}`,
          },
        },
        (proxyResponse) => {
          response.writeHead(proxyResponse.statusCode || 502, proxyResponse.headers);
          proxyResponse.pipe(response);
        },
      );
      proxyRequest.on('error', (error) => {
        console.error(`API proxy error: ${error.message}`);
        if (!response.headersSent) {
          sendError(response, 502, 'The local EduPortal API is unavailable.');
        } else {
          response.destroy(error);
        }
      });
      request.pipe(proxyRequest);
      return;
    }

    const relativePath = pathname === '/' ? 'index.html' : pathname.slice(1);
    let filePath = path.resolve(webRoot, relativePath);
    const relativeToRoot = path.relative(webRoot, filePath);
    if (
      relativeToRoot === '..' ||
      relativeToRoot.startsWith(`..${path.sep}`) ||
      path.isAbsolute(relativeToRoot)
    ) {
      sendError(response, 404, 'Not found');
      return;
    }

    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      if (path.extname(filePath)) {
        sendError(response, 404, 'Not found');
        return;
      }
      filePath = path.join(webRoot, 'index.html');
    }

    response.writeHead(200, {
      'Cache-Control': path.basename(filePath) === 'index.html' ? 'no-cache' : 'public, max-age=3600',
      'Content-Type': contentTypes[path.extname(filePath).toLowerCase()] || 'application/octet-stream',
      'X-Content-Type-Options': 'nosniff',
    });
    fs.createReadStream(filePath).pipe(response);
  },
);

server.on('error', (error) => {
  console.error(`HTTPS server error: ${error.message}`);
  process.exitCode = 1;
});

server.listen(port, host, () => {
  console.log(`AcademyAlys HTTPS is available at https://${lanIp}:${port}`);
  console.log(`API requests are proxied to http://${apiHost}:${apiPort}`);
});

if (certPort > 0) {
  const certificateServer = http.createServer((request, response) => {
    if (request.method !== 'GET' || request.url !== '/lan-ca.cer') {
      sendError(response, 404, 'Not found');
      return;
    }

    response.writeHead(200, {
      'Cache-Control': 'no-store',
      'Content-Disposition': 'attachment; filename="academyalys-lan-ca.cer"',
      'Content-Type': 'application/pkix-cert',
      'X-Content-Type-Options': 'nosniff',
    });
    fs.createReadStream(caCertificatePath).pipe(response);
  });

  certificateServer.on('error', (error) => {
    console.error(`Certificate download server error: ${error.message}`);
    process.exitCode = 1;
  });

  certificateServer.listen(certPort, host, () => {
    console.log(`Local CA certificate download: http://${lanIp}:${certPort}/lan-ca.cer`);
  });
}
