import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const query: Record<string, string> = {};
  for (const [key, value] of searchParams.entries()) {
    query[key] = value;
  }
  const result = await apiFetch('/cms/home/items', {
    method: 'GET',
    query,
  });
  return NextResponse.json(result.data, { status: result.status });
}

export async function POST(request: Request) {
  const body = await request.json();
  const result = await apiFetch('/cms/home/items', {
    method: 'POST',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}
