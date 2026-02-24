import type { NextRequest } from 'next/server'
import { getCurrentUser } from './libs/firebase/firebase-admin';
import { NextResponse } from 'next/server'

const AUTH_REQUIRED_PATHS = ['/protected'];

export async function middleware(request: NextRequest) {

    const user = await getCurrentUser()

    if (AUTH_REQUIRED_PATHS.includes(request.nextUrl.pathname) && !user) {
        return NextResponse.redirect(new URL('/', request.url))
    }

}

export const config = {
    matcher: [
        /*
         * Match all request paths except for the ones starting with:
         * - api (API routes)
         * - _next/static (static files)
         * - _next/image (image optimization files)
         * - favicon.ico, sitemap.xml, robots.txt (metadata files)
         */
        '/((?!api|_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt).*)',
    ],
    runtime: 'nodejs',
};
