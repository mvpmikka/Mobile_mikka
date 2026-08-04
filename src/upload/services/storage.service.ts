import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

// Left unconfigured (empty SUPABASE_* vars) until a real project exists —
// same graceful pattern as Mail/Google/Nominatim. Uploads fail with a
// clear error rather than the app failing to boot.
@Injectable()
export class StorageService {
  private readonly client: SupabaseClient | null;
  private readonly bucket: string;

  constructor(configService: ConfigService) {
    const url = configService.get<string>('SUPABASE_URL', '');
    const key = configService.get<string>('SUPABASE_SERVICE_ROLE_KEY', '');
    this.bucket = configService.get<string>('SUPABASE_STORAGE_BUCKET', '');
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
}
