import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function POST(request: Request) {
  const body = await request.json();
  const result = await apiFetch('/cms/home/items/reorder', {
    method: 'POST',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}
