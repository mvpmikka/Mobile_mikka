// Same minimal shape as PlaceListItem (list/map view only) — search
// results are a list, not a detail view. Full detail lives behind
// GET /places/:id. See docs/foundation.md.
export interface SearchResult {
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
}

export interface PaginatedSearchResult {
  items: SearchResult[];
  total: number;
  page: number;
  limit: number;
}
