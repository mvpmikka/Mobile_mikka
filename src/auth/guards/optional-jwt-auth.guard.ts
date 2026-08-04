import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

// Same 'jwt' strategy as JwtAuthGuard, but never rejects the request —
// overriding handleRequest swallows the "no/invalid token" error instead of
// throwing UnauthorizedException. @CurrentUser() resolves to undefined for
// an anonymous caller instead of a valid AuthenticatedUser. For endpoints
// that behave differently for logged-in vs anonymous callers (e.g. a
// visibility check that only needs viewer identity when it's not PUBLIC).
@Injectable()
export class OptionalJwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser = unknown>(_err: unknown, user: unknown): TUser {
    return (user || undefined) as TUser;
  }
}