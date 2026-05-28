import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function POST(request: Request) {
  const formData = await request.formData();
  const result = await apiFetch('/upload', {
    method: 'POST',
    body: formData,
    skipEncryption: true,
    contentType: 'multipart/form-data',
  });
  return NextResponse.json(result.data, { status: result.status });
}
