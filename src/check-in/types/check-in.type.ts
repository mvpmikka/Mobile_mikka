export interface CheckInWithPlace {
  id: string;
  placeId: string;
  place: {
    id: string;
    name: string;
  };
  distanceMeters: number;
  createdAt: Date;
}

// Shown to viewers other than the owner (GET /users/:username/check-ins) —
// deliberately excludes latitude/longitude/distanceMeters/userId. Unlike
// CheckInWithPlace (self-view only), this is reachable by other users once
// checkInVisibility allows it, and exact GPS coordinates are more than
// "which place" — never over-expose. See docs/foundation.md.
export interface PublicCheckInItem {
  id: string;
  place: {
    id: string;
    name: string;
  };
  createdAt: Date;
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}
