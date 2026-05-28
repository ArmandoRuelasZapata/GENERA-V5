import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { apiFetch } from '@/lib/api';
import { setAuthCookies } from '@/lib/auth';

export async function POST() {
  const refresh = cookies().get('refresh_token')?.value;
  if (!refresh) {
    return NextResponse.json(
      { success: false, message: 'Missing refresh token' },
      { status: 401 }
    );
  }

  const result = await apiFetch('/api/auth/admin/refresh', {
    method: 'POST',
    body: { refresh_token: refresh },
  });

  if (result.status >= 400) {
    return NextResponse.json(result.data, { status: result.status });
  }

  const token = result.data?.data?.token;
  const newRefresh = result.data?.data?.refresh_token;
  if (token && newRefresh) {
    setAuthCookies(token, newRefresh);
  }

  return NextResponse.json(result.data, { status: result.status });
}
