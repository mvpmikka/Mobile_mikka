import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { mkdir, writeFile, access } from 'node:fs/promises';
import { dirname, resolve, sep } from 'node:path';

// Files live on the server's own disk (STORAGE_DIR, a Docker volume in
// production) — no external storage provider. Two areas, mirroring the old
// public/private bucket split:
//   public/   post/place photos, avatars, shorts — served as static files
//             under /files/ (see main.ts), anyone with the URL can view.
//   private/  verification documents — never served statically; only via a
//             short-lived HMAC-signed URL handled by FilesController.
export const PUBLIC_FILES_ROUTE = '/files';
export const PRIVATE_FILES_ROUTE = '/files-private';

@Injectable()
export class StorageService {
  readonly publicDir: string;
  private readonly privateDir: string;
  private readonly publicBaseUrl: string;
  private readonly signingSecret: string;

  constructor(configService: ConfigService) {
    const root = resolve(configService.get<string>('STORAGE_DIR', './storage'));
    this.publicDir = resolve(root, 'public');
    this.privateDir = resolve(root, 'private');
    // Absolute URLs are handed to the mobile client, so they must carry the
    // public domain, not the container's internal address.
    this.publicBaseUrl = configService
      .get<string>('PUBLIC_BASE_URL', 'http://localhost:3000')
      .replace(/\/+$/, '');
    this.signingSecret =
      configService.get<string>('STORAGE_SIGNING_SECRET', '') ||
      configService.get<string>('JWT_ACCESS_SECRET', '');
  }

  async upload(
    path: string,
    buffer: Buffer,
    // Kept for interface compatibility — the content type is derived from
    // the file extension when the file is served.
    _contentType: string,
  ): Promise<string> {
    const target = this.resolveInside(this.publicDir, path);
    // flag 'wx' = fail if the file exists, same as the old upsert:false.
    await this.write(target, buffer, 'wx', 'Failed to upload image');
    return `${this.publicBaseUrl}${PUBLIC_FILES_ROUTE}/${path}`;
  }

  // Stores into the private area and returns the storage path (not a URL —
  // a path alone is safe to keep in the database). Overwrites because a
  // rejected submission must be re-uploadable at the same stable path (see
  // VerificationService).
  async uploadPrivate(
    path: string,
    buffer: Buffer,
    _contentType: string,
  ): Promise<string> {
    const target = this.resolveInside(this.privateDir, path);
    await this.write(target, buffer, 'w', 'Failed to upload document');
    return path;
  }

  // Only way to ever view a private file — expires quickly so a leaked link
  // (browser history, logs) stops working on its own.
  getSignedUrl(path: string, expiresInSeconds = 300): Promise<string> {
    this.resolveInside(this.privateDir, path);
    const expires = Math.floor(Date.now() / 1000) + expiresInSeconds;
    const params = new URLSearchParams({
      path,
      expires: String(expires),
      signature: this.sign(path, expires),
    });
    return Promise.resolve(
      `${this.publicBaseUrl}${PRIVATE_FILES_ROUTE}?${params.toString()}`,
    );
  }

  // Verifies a signed URL's parameters and returns the absolute file path
  // to stream. Throws NotFound for every failure so a probe can't tell a
  // bad signature from a missing file.
  async resolveSignedPrivateFile(
    path: string | undefined,
    expires: string | undefined,
    signature: string | undefined,
  ): Promise<string> {
    const expiresAt = Number(expires);
    if (!path || !signature || !Number.isInteger(expiresAt)) {
      throw new NotFoundException();
    }
    if (expiresAt < Math.floor(Date.now() / 1000)) {
      throw new NotFoundException();
    }

    const expected = Buffer.from(this.sign(path, expiresAt));
    const given = Buffer.from(signature);
    if (expected.length !== given.length || !timingSafeEqual(expected, given)) {
      throw new NotFoundException();
    }

    let target: string;
    try {
      target = this.resolveInside(this.privateDir, path);
      await access(target);
    } catch {
      throw new NotFoundException();
    }
    return target;
  }

  private sign(path: string, expires: number): string {
    if (!this.signingSecret) {
      throw new BadRequestException(
        'Private document storage is not configured yet',
      );
    }
    return createHmac('sha256', this.signingSecret)
      .update(`${path}:${expires}`)
      .digest('base64url');
  }

  // Paths are built server-side today, but a stray "../" must never let a
  // write or read escape the storage area.
  private resolveInside(base: string, path: string): string {
    const target = resolve(base, path);
    if (!target.startsWith(base + sep)) {
      throw new BadRequestException('Invalid storage path');
    }
    return target;
  }

  private async write(
    target: string,
    buffer: Buffer,
    flag: 'w' | 'wx',
    errorMessage: string,
  ): Promise<void> {
    try {
      await mkdir(dirname(target), { recursive: true });
      await writeFile(target, buffer, { flag });
    } catch (error) {
      throw new BadRequestException(
        `${errorMessage}: ${(error as Error).message}`,
      );
    }
  }
}
