import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  const body = await request.json();
  const result = await apiFetch(`/cms/home/sections/${params.id}`, {
    method: 'PATCH',
    body,
  });
  return NextResponse.json(result.data, { status: result.status });
}
