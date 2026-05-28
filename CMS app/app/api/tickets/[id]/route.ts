import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function GET(
  _request: Request,
  { params }: { params: { id: string } }
) {
  const result = await apiFetch(`/tickets/${params.id}`, { method: 'GET' });
  return NextResponse.json(result.data, { status: result.status });
}

export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const body = await request.json();
  const result = await apiFetch(`/tickets/${params.id}`, {
    method: 'PUT',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}
