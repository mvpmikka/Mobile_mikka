import { Controller, Get, Query, Res } from '@nestjs/common';
import type { Response } from 'express';
import { PRIVATE_FILES_ROUTE, StorageService } from './services/storage.service';

// Serves private files (verification documents) behind the signed URLs
// StorageService.getSignedUrl issues. No JWT here on purpose: the link is
// opened directly by an <img>/browser, and the HMAC signature + short expiry
// is the access check. Public files are served statically (see main.ts).
@Controller(PRIVATE_FILES_ROUTE.slice(1))
export class FilesController {
  constructor(private readonly storageService: StorageService) {}

  @Get()
  async getPrivate(
    @Query('path') path: string | undefined,
    @Query('expires') expires: string | undefined,
    @Query('signature') signature: string | undefined,
    @Res() res: Response,
  ): Promise<void> {
    const file = await this.storageService.resolveSignedPrivateFile(
      path,
      expires,
      signature,
    );
    res.setHeader('Cache-Control', 'private, no-store');
    res.sendFile(file);
  }
}
