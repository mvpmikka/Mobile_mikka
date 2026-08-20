import { Controller, Get, Param } from '@nestjs/common';
import { BadgeService } from './services/badge.service';

@Controller()
export class BadgeController {
  constructor(private readonly badgeService: BadgeService) {}

  // Public, no guard — same as places/:placeId/reviews and
  // places/:placeId/rating: badges are a public achievement showcase (the
  // Figma mockup's "Titles" tab on another user's profile), not
  // privacy-gated content.
  @Get('users/:username/badges')
  listForUser(@Param('username') username: string) {
    return this.badgeService.listForUser(username);
  }
}
