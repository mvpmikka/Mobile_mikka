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
// deliberately excludes the user's own distanceMeters/userId/raw GPS. Unlike
// CheckInWithPlace (self-view only), this is reachable by other users once
// checkInVisibility allows it, and the user's exact GPS coordinates are more
// than "which place" — never over-expose those. See docs/foundation.md.
// place.latitude/longitude ARE included: that's the place's own public
// business location (same data returned by GET /places), not the viewer's
// personal position.
export interface PublicCheckInItem {
  id: string;
  place: {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
  };
  createdAt: Date;
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}
