import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';

import { apiFetch } from '@/lib/api';
import { clearAuthCookies } from '@/lib/auth';

export async function POST() {
  const refresh = cookies().get('refresh_token')?.value;
  if (refresh) {
    await apiFetch('/api/auth/admin/logout', {
      method: 'POST',
      body: { refresh_token: refresh },
    });
  }

  clearAuthCookies();
  return NextResponse.json({ success: true });
}
