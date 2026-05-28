import { NextResponse } from 'next/server';

import { apiFetch } from '@/lib/api';
import { setAuthCookies } from '@/lib/auth';

export async function POST(request: Request) {
  const body = await request.json();
  const result = await apiFetch('/api/auth/admin/login', {
    method: 'POST',
    body,
  });

  if (result.status >= 400) {
    return NextResponse.json(result.data, { status: result.status });
  }

  const token = result.data?.data?.token;
  const refresh = result.data?.data?.refresh_token;
  if (token && refresh) {
    setAuthCookies(token, refresh);
  }

  return NextResponse.json(result.data, { status: result.status });
}
