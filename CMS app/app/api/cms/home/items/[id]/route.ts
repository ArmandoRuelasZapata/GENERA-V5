import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const body = await request.json();
  const result = await apiFetch(`/cms/home/items/${params.id}`, {
    method: 'PUT',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}

export async function DELETE(
  _request: Request,
  { params }: { params: { id: string } }
) {
  const result = await apiFetch(`/cms/home/items/${params.id}`, {
    method: 'DELETE',
  });
  return NextResponse.json(result.data, { status: result.status });
}
