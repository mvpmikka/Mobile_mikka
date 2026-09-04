import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Left unconfigured (empty SUPABASE_* vars) until a real project exists —
// same graceful pattern as Mail/Google/Nominatim. Uploads fail with a
// clear error rather than the app failing to boot.
//
// Two buckets, one client (both live in the same Supabase project, so one
// SupabaseClient is enough): `bucket` is public (post/place photos —
// getPublicUrl works, no auth needed to view), `privateBucket` is not
// (verification documents — only ever handed out as a short-lived signed
// URL, see getSignedUrl).
@Injectable()
export class StorageService {
  private readonly client: SupabaseClient | null;
  private readonly bucket: string;
  private readonly privateBucket: string;

  constructor(configService: ConfigService) {
    const url = configService.get<string>('SUPABASE_URL', '');
    const key = configService.get<string>('SUPABASE_SERVICE_ROLE_KEY', '');
    this.bucket = configService.get<string>('SUPABASE_STORAGE_BUCKET', '');
    this.privateBucket = configService.get<string>(
      'SUPABASE_PRIVATE_STORAGE_BUCKET',
      '',
    );
    this.client = url && key ? createClient(url, key) : null;
  }

  async upload(
    path: string,
    buffer: Buffer,
    contentType: string,
  ): Promise<string> {
    if (!this.client || !this.bucket) {
      throw new BadRequestException('Image upload is not configured yet');
    }

    const { error } = await this.client.storage
      .from(this.bucket)
      .upload(path, buffer, {
        contentType,
        upsert: false,
      });
    if (error) {
      throw new BadRequestException(`Failed to upload image: ${error.message}`);
    }

    const { data } = this.client.storage.from(this.bucket).getPublicUrl(path);
    return data.publicUrl;
  }

  // Stores into the private bucket and returns the storage path (not a
  // URL — the bucket has no public access, so a path alone is safe to keep
  // in the database). upsert:true because a rejected submission must be
  // re-uploadable at the same stable path (see VerificationService).
  async uploadPrivate(
    path: string,
    buffer: Buffer,
    contentType: string,
  ): Promise<string> {
    if (!this.client || !this.privateBucket) {
      throw new BadRequestException(
        'Private document storage is not configured yet',
      );
    }

    const { error } = await this.client.storage
      .from(this.privateBucket)
      .upload(path, buffer, {
        contentType,
        upsert: true,
      });
    if (error) {
      throw new BadRequestException(
        `Failed to upload document: ${error.message}`,
      );
    }

    return path;
  }

  // Only way to ever view a private-bucket object — expires quickly so a
  // leaked link (browser history, logs) stops working on its own.
  async getSignedUrl(path: string, expiresInSeconds = 300): Promise<string> {
    if (!this.client || !this.privateBucket) {
      throw new BadRequestException(
        'Private document storage is not configured yet',
      );
    }

    const { data, error } = await this.client.storage
      .from(this.privateBucket)
      .createSignedUrl(path, expiresInSeconds);
    if (error || !data) {
      throw new BadRequestException(
        `Failed to create signed URL: ${error?.message ?? 'unknown error'}`,
      );
    }

    return data.signedUrl;
  }
}
