# API Encryption Middleware — Guia de Implementacion

Este documento explica cómo implementar en tu API backend el cifrado AES-256-CTR+HMAC-SHA256 que corresponde al interceptor Flutter `PayloadEncryptionInterceptor`.

---

## Cómo funciona el protocolo

```
Flutter ──► [AES-256-CTR encrypt body] ──► HTTPS/TLS+CertPinning ──► API
              { "enc": "<base64>" }                                  [decrypt]
                                                                         │
Flutter ◄── [AES-256-CTR decrypt] ◄── HTTPS/TLS+CertPinning ◄── { "enc": "<base64>" }
```

### Formato del blob cifrado
```
[ IV (16 bytes) | ciphertext (N bytes) | HMAC-SHA256 (32 bytes) ]
```
Todo encodado en Base64 estándar y envuelto en `{ "enc": "..." }`.

### Header indicador
Cuando el body va cifrado, la petición lleva el header:
```
X-Payload-Encrypted: 1
```
La API debe poner el mismo header en las respuestas cifradas.

---

## Variables de entorno

| Variable | Descripción |
|---|---|
| `PAYLOAD_ENCRYPTION_KEY` | 64 chars hexadecimales = 32 bytes AES-256 |

### Generar una clave segura

```bash
# Linux / macOS
openssl rand -hex 32
# Ejemplo output: a3f1c8e2b9d047...  (64 chars)
```

Agrega la misma clave en:
- **Flutter**: `.env.prod.json` → `"PAYLOAD_ENCRYPTION_KEY": "a3f1c8e2..."`
- **API**: variable de entorno `PAYLOAD_ENCRYPTION_KEY`

---

## Implementación Node.js / Express

```javascript
// middleware/payloadEncryption.js
const crypto = require('crypto');

const KEY_HEX = process.env.PAYLOAD_ENCRYPTION_KEY; // 64 chars hex
const IV_LEN  = 16;
const MAC_LEN = 32;

function getKey() {
  if (!KEY_HEX || KEY_HEX.length !== 64) throw new Error('PAYLOAD_ENCRYPTION_KEY inválida');
  return Buffer.from(KEY_HEX, 'hex');
}

function deriveAesKey(masterKey) {
  return crypto.createHmac('sha256', masterKey).update('aes-ctr-key').digest();
}

function hmacSha256(key, data) {
  return crypto.createHmac('sha256', key).update(data).digest();
}

// Descifrar un blob Base64 → objeto JS
function decryptPayload(base64Blob) {
  const masterKey = getKey();
  const aesKey    = deriveAesKey(masterKey);
  const blob      = Buffer.from(base64Blob, 'base64');

  if (blob.length < IV_LEN + MAC_LEN) throw new Error('Payload demasiado corto');

  const iv         = blob.slice(0, IV_LEN);
  const ciphertext = blob.slice(IV_LEN, blob.length - MAC_LEN);
  const mac        = blob.slice(blob.length - MAC_LEN);

  // Verificar HMAC (Encrypt-then-MAC)
  const expected = hmacSha256(masterKey, Buffer.concat([iv, ciphertext]));
  if (!crypto.timingSafeEqual(mac, expected)) {
    throw new Error('MAC inválido — posible manipulación del payload');
  }

  // Descifrar AES-256-CTR con keystream derivado (mismo algoritmo que Dart)
  const plaintext = decryptCtr(aesKey, iv, ciphertext);
  return JSON.parse(plaintext.toString('utf8'));
}

// Cifrar un objeto JS → Base64 blob
function encryptPayload(data) {
  const masterKey = getKey();
  const aesKey    = deriveAesKey(masterKey);
  const iv        = crypto.randomBytes(IV_LEN);
  const plaintext = Buffer.from(JSON.stringify(data), 'utf8');
  const ciphertext = encryptCtr(aesKey, iv, plaintext);
  const mac        = hmacSha256(masterKey, Buffer.concat([iv, ciphertext]));
  return Buffer.concat([iv, ciphertext, mac]).toString('base64');
}

// AES-256-CTR con keystream via HMAC-SHA256 (igual que el Dart)
function decryptCtr(aesKey, iv, data) {
  const out     = Buffer.alloc(data.length);
  const counter = Buffer.from(iv);
  let   offset  = 0;

  while (offset < data.length) {
    const keystream = crypto.createHmac('sha256', aesKey).update(counter).digest();
    const blockLen  = Math.min(16, data.length - offset);
    for (let i = 0; i < blockLen; i++) {
      out[offset + i] = data[offset + i] ^ keystream[i];
    }
    incrementCounter(counter);
    offset += 16;
  }
  return out;
}

const encryptCtr = decryptCtr; // CTR mode es simétrico (encrypt == decrypt)

function incrementCounter(buf) {
  for (let i = buf.length - 1; i >= 0; i--) {
    if (buf[i] === 255) { buf[i] = 0; }
    else                { buf[i]++; break; }
  }
}

// ─── Middleware Express ───────────────────────────────────────────────────────

// Descifra el request si viene con X-Payload-Encrypted: 1
function decryptRequest(req, res, next) {
  if (req.headers['x-payload-encrypted'] !== '1') return next();
  if (!req.body || !req.body.enc) return next();

  try {
    req.body = decryptPayload(req.body.enc);
    next();
  } catch (err) {
    res.status(400).json({ success: false, message: 'Payload inválido' });
  }
}

// Intercepta res.json() para cifrar la respuesta
function encryptResponse(req, res, next) {
  if (req.headers['x-payload-encrypted'] !== '1') return next();

  const originalJson = res.json.bind(res);
  res.json = (body) => {
    try {
      res.setHeader('X-Payload-Encrypted', '1');
      return originalJson({ enc: encryptPayload(body) });
    } catch {
      return originalJson(body); // fallback sin cifrar
    }
  };
  next();
}

module.exports = { decryptRequest, encryptResponse };
```

### Registro en Express

```javascript
// app.js
const express = require('express');
const { decryptRequest, encryptResponse } = require('./middleware/payloadEncryption');
const app = express();

app.use(express.json());
// Registrar ANTES de las rutas
app.use(decryptRequest);
app.use(encryptResponse);

// ... tus rutas aquí
```

---

## Implementación Dart Frog (si tu API es Dart)

```dart
// middleware/payload_encryption_middleware.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';

Handler payloadEncryptionMiddleware(Handler handler) {
  return (context) async {
    final request = context.request;
    final isEncrypted = request.headers['X-Payload-Encrypted'] == '1';

    if (!isEncrypted) return handler(context);

    // Descifrar request
    final body = await request.body();
    final bodyJson = jsonDecode(body) as Map<String, dynamic>;
    final decrypted = _decryptPayload(bodyJson['enc'] as String);

    // Inyectar el body descifrado
    final modifiedRequest = request.copyWith(body: jsonEncode(decrypted));
    final modifiedContext = context.provide<Request>(() => modifiedRequest);

    // Obtener respuesta y cifrarla
    final response = await handler(modifiedContext);
    final responseBody = await response.body();
    final encrypted = _encryptPayload(jsonDecode(responseBody));

    return response.copyWith(
      body: jsonEncode({'enc': encrypted}),
      headers: {...response.headers, 'X-Payload-Encrypted': '1'},
    );
  };
}
// (Usar mismos algoritmos _encryptPayload/_decryptPayload que el interceptor Flutter)
```

---

## Pasos para activar en producción

1. Generar clave: `openssl rand -hex 32`
2. Agregar `PAYLOAD_ENCRYPTION_KEY` a Easypanel / variables de entorno de tu servidor
3. Agregar `PAYLOAD_ENCRYPTION_KEY` a `.env.prod.json`
4. Agregar el middleware a tu API (código arriba)
5. Build con `./scripts/build_release.sh`
6. Probar con Burp Suite → el body debe verse como `{ "enc": "ABC123..." }` ilegible

> [!IMPORTANT]
> Mientras la API no tenga el middleware activado, **no actives** `PAYLOAD_ENCRYPTION_KEY` en el APK.
> El interceptor en Flutter está diseñado para ser un "feature flag": si la variable no está en el .env, no cifra ni descifra nada.
