import { cookies } from 'next/headers';
import { buildReplayHeaders, decryptObject, encryptObject, isCryptoEnabled } from './crypto';

const API_BASE_URL = process.env.API_BASE_URL || process.env.NEXT_PUBLIC_API_BASE_URL || '';
const API_KEY = process.env.API_KEY || process.env.NEXT_PUBLIC_API_KEY || '';
const PAYLOAD_KEY = process.env.PAYLOAD_ENCRYPTION_KEY || '';

if (!API_BASE_URL) {
  console.warn('API_BASE_URL is not set');
}

export type ApiResult = {
  status: number;
  data: any;
  headers: Headers;
};

export async function apiFetch(
  path: string,
  opts: {
    method?: string;
    body?: any;
    query?: Record<string, string | number | boolean | null | undefined>;
    accessToken?: string;
    skipEncryption?: boolean;
    contentType?: string;
  } = {}
): Promise<ApiResult> {
  const method = (opts.method || 'GET').toUpperCase();
  const url = new URL(path, API_BASE_URL);

  const headers: Record<string, string> = {
    apikey: API_KEY,
    ...(opts.contentType ? { 'Content-Type': opts.contentType } : { 'Content-Type': 'application/json' }),
  };

  const token = opts.accessToken || cookies().get('access_token')?.value;
  if (token) headers.Authorization = `Bearer ${token}`;

  const cryptoEnabled = isCryptoEnabled(PAYLOAD_KEY);
  const encryptRequest = cryptoEnabled && !opts.skipEncryption;
  if (cryptoEnabled) {
    headers['X-Payload-Encrypted'] = '1';
  }

  const replayHeaders = buildReplayHeaders(method);
  Object.assign(headers, replayHeaders);

  if (opts.query && Object.keys(opts.query).length > 0) {
    const cleaned: Record<string, string> = {};
    for (const [k, v] of Object.entries(opts.query)) {
      if (v === null || v === undefined) continue;
      cleaned[k] = String(v);
    }

    if (encryptRequest) {
      headers['X-Encrypted-Params'] = encryptObject(cleaned, PAYLOAD_KEY);
    } else {
      for (const [k, v] of Object.entries(cleaned)) {
        url.searchParams.set(k, v);
      }
    }
  }

  let body: BodyInit | undefined;
  if (opts.body !== undefined) {
    if (encryptRequest) {
      body = JSON.stringify({ enc: encryptObject(opts.body, PAYLOAD_KEY) });
    } else if (opts.contentType && opts.contentType.startsWith('multipart/form-data')) {
      body = opts.body as BodyInit;
      delete headers['Content-Type'];
    } else {
      body = JSON.stringify(opts.body);
    }
  }

  const res = await fetch(url.toString(), {
    method,
    headers,
    body,
  });

  const contentType = res.headers.get('content-type') || '';
  let data: any = null;
  if (contentType.includes('application/json')) {
    data = await res.json();
    const encHeader = res.headers.get('x-payload-encrypted');
    if (cryptoEnabled && encHeader === '1' && data?.enc) {
      data = decryptObject(data.enc, PAYLOAD_KEY);
    }
  } else {
    data = await res.text();
  }

  return { status: res.status, data, headers: res.headers };
}
