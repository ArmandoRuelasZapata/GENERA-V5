import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function GET(
  _request: Request,
  { params }: { params: { id: string } }
) {
  const result = await apiFetch(`/tickets/${params.id}/messages`, {
    method: 'GET',
  });
  return NextResponse.json(result.data, { status: result.status });
}

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  const body = await request.json();
  const result = await apiFetch(`/tickets/${params.id}/messages`, {
    method: 'POST',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}
