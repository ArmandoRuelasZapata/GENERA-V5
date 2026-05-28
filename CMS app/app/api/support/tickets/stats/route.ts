import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';

export async function GET() {
  const result = await apiFetch('/support/tickets/stats', { method: 'GET' });
  return NextResponse.json(result.data, { status: result.status });
}
