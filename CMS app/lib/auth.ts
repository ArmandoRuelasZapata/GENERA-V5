import { cookies } from 'next/headers';

const isProd = process.env.NODE_ENV === 'production';

export function setAuthCookies(accessToken: string, refreshToken: string) {
  const store = cookies();
  store.set('access_token', accessToken, {
    httpOnly: true,
    sameSite: 'lax',
    secure: isProd,
    path: '/',
  });
  store.set('refresh_token', refreshToken, {
    httpOnly: true,
    sameSite: 'lax',
    secure: isProd,
    path: '/',
  });
}

export function clearAuthCookies() {
  const store = cookies();
  store.set('access_token', '', {
    httpOnly: true,
    sameSite: 'lax',
    secure: isProd,
    path: '/',
    maxAge: 0,
  });
  store.set('refresh_token', '', {
    httpOnly: true,
    sameSite: 'lax',
    secure: isProd,
    path: '/',
    maxAge: 0,
  });
}
