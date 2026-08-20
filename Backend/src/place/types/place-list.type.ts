export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

// Deliberately minimal — only what a list/map view actually displays
// (name, pin location, category, distance). Full detail (description,
// address, phone, website, audit fields) lives behind GET /places/:id.
// Never fetch what isn't rendered — see docs/foundation.md.
export interface PlaceListItem {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  category: {
    id: string;
    name: string;
  };
  distanceMeters: number | null;
  rating: {
    averageRating: number;
    reviewCount: number;
  };
}

// 'none' — plain list, no lat/lng given.
// 'radius' — lat/lng given; results (if any) came from the requested radius.
// 'region_fallback' — the radius search came up empty, so results (if any)
// came from the wider administrative region containing lat/lng instead.
export type PlaceSearchMode = 'none' | 'radius' | 'region_fallback';

export interface PlaceListResult extends PaginatedResult<PlaceListItem> {
  searchMode: PlaceSearchMode;
  requestedRadiusMeters: number | null;
  region: { id: string; name: string } | null;
}
