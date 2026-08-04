export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

// Same minimal fields as Place module's own PlaceListItem — kept as a
// local, independent projection rather than importing PlaceModule's type,
// per CLAUDE.md's module-independence principle (same approach Review
// takes with its own reviewerSelect).
export interface SavedPlaceItem {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  status: string;
  category: {
    id: string;
    name: string;
  };
  savedAt: Date;
}