import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';
import type { AuthenticatedUser } from '../strategies/jwt.strategy';

// Pairs with OptionalJwtAuthGuard — unlike @CurrentUser(), the return type
// is honestly `| undefined` since there's no guard guaranteeing a caller is
// authenticated at all.
export const OptionalCurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthenticatedUser | undefined => {
    return ctx
      .switchToHttp()
      .getRequest<Request & { user?: AuthenticatedUser }>().user;
  },
);