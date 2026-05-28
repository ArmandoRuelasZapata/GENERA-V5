import crypto from 'crypto';

const IV_LEN = 16;
const MAC_LEN = 32;

function hexToBytes(hex: string): Buffer {
  if (hex.length !== 64) {
    throw new Error('Invalid key length');
  }
  return Buffer.from(hex, 'hex');
}

function hmacSha256(key: Buffer, data: Buffer): Buffer {
  return crypto.createHmac('sha256', key).update(data).digest();
}

function deriveAesKey(masterKey: Buffer): Buffer {
  return hmacSha256(masterKey, Buffer.from('aes-ctr-key'));
}

function incrementCounter(counter: Buffer) {
  for (let i = counter.length - 1; i >= 0; i -= 1) {
    counter[i] = (counter[i] + 1) & 0xff;
    if (counter[i] !== 0) break;
  }
}

function aesCtrLike(masterKey: Buffer, iv: Buffer, data: Buffer): Buffer {
  const derivedKey = deriveAesKey(masterKey);
  const counter = Buffer.from(iv);
  const out = Buffer.alloc(data.length);

  for (let offset = 0; offset < data.length; offset += 16) {
    const keystream = hmacSha256(derivedKey, counter);
    const blockLen = Math.min(16, data.length - offset);
    for (let i = 0; i < blockLen; i += 1) {
      out[offset + i] = data[offset + i] ^ keystream[i];
    }
    incrementCounter(counter);
  }

  return out;
}

export function isCryptoEnabled(keyHex?: string | null): boolean {
  if (!keyHex) return false;
  return keyHex.length === 64;
}

export function encryptBytes(plaintext: Buffer, keyHex: string): Buffer {
  const key = hexToBytes(keyHex);
  const iv = crypto.randomBytes(IV_LEN);
  const ciphertext = aesCtrLike(key, iv, plaintext);
  const mac = hmacSha256(key, Buffer.concat([iv, ciphertext]));
  return Buffer.concat([iv, ciphertext, mac]);
}

export function decryptBytes(blob: Buffer, keyHex: string): Buffer {
  const key = hexToBytes(keyHex);
  if (blob.length < IV_LEN + MAC_LEN) {
    throw new Error('Encrypted blob too short');
  }
  const iv = blob.subarray(0, IV_LEN);
  const ciphertext = blob.subarray(IV_LEN, blob.length - MAC_LEN);
  const mac = blob.subarray(blob.length - MAC_LEN);
  const expected = hmacSha256(key, Buffer.concat([iv, ciphertext]));
  if (!crypto.timingSafeEqual(mac, expected)) {
    throw new Error('Invalid MAC');
  }
  return aesCtrLike(key, iv, ciphertext);
}

export function encryptObject(obj: unknown, keyHex: string): string {
  const plain = Buffer.from(JSON.stringify(obj), 'utf8');
  const blob = encryptBytes(plain, keyHex);
  return blob.toString('base64');
}

export function decryptObject(encBase64: string, keyHex: string): unknown {
  const blob = Buffer.from(encBase64, 'base64');
  const plain = decryptBytes(blob, keyHex);
  return JSON.parse(plain.toString('utf8'));
}

export function buildReplayHeaders(method: string): Record<string, string> {
  const m = method.toUpperCase();
  const isMutation = m === 'POST' || m === 'PUT' || m === 'PATCH' || m === 'DELETE';
  if (!isMutation) return {};
  const now = Math.floor(Date.now() / 1000);
  const nonce = crypto.randomBytes(16).toString('base64url');
  return {
    'X-Request-Timestamp': now.toString(),
    'X-Request-Nonce': nonce,
  };
}
