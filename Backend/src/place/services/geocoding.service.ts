import { BadRequestException, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface GeocodedLocation {
  latitude: number;
  longitude: number;
  formattedAddress: string;
}

interface NominatimSearchResult {
  lat: string;
  lon: string;
  display_name: string;
}

// Wraps Nominatim (OSM's free geocoding service) per CLAUDE.md's tech
// stack — never Google Geocoding. Left unconfigured (empty NOMINATIM_USER_AGENT)
// until a real value is set, same graceful pattern as Mail/Google.
@Injectable()
export class GeocodingService {
  constructor(private readonly configService: ConfigService) {}

  async geocode(address: string): Promise<GeocodedLocation> {
    const userAgent = this.configService.get<string>(
      'NOMINATIM_USER_AGENT',
      '',
    );
    if (!userAgent) {
      throw new BadRequestException('Geocoding is not configured yet');
    }

    const url = new URL(
      '/search',
      this.configService.getOrThrow<string>('NOMINATIM_BASE_URL'),
    );
    url.searchParams.set('q', address);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '1');

    const response = await fetch(url, { headers: { 'User-Agent': userAgent } });
    if (!response.ok) {
      throw new BadRequestException('Failed to reach the geocoding service');
    }

    const results = (await response.json()) as NominatimSearchResult[];
    const [result] = results;
    if (!result) {
      throw new BadRequestException('Address could not be geocoded');
    }

    return {
      latitude: Number(result.lat),
      longitude: Number(result.lon),
      formattedAddress: result.display_name,
    };
  }
}
