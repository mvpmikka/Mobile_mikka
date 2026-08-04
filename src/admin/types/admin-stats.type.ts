// Only what nothing else already owns — Place/PlaceCategory admin CRUD
// already lives in PlaceController (ADMIN-gated), not duplicated here. See
// docs/foundation.md: this is the one thing that legitimately needed a
// dedicated Admin module — a count that spans multiple tables no single
// domain module owns.
export interface AdminStats {
  totalUsers: number;
  totalPlaces: number;
  totalReviews: number;
  totalCheckIns: number;
}