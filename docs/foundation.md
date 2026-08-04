# Foundation — Architecture Decision Record

Status: accepted
Scope: `prisma/schema.prisma` (`User`, `AuthIdentity`), Prisma/NestJS project setup
Last updated: 2026-07-16

This document records the reasoning behind the Foundation layer, before Auth
module implementation begins. Each section is a lightweight ADR: context,
decision, consequences. If a decision needs to change later, update it here
in the same commit as the schema change — don't let this drift from reality.

---

## 1. `User` and `AuthIdentity` are separate models

**Context.** Mikka must support multiple authentication methods per account:
Email/Password today, Google OAuth next, GitHub/Apple later. A user should
be able to hold more than one login method at once (e.g. sign up with
Google, later add a password).

**Decision.** Profile data (`User`) and login credentials (`AuthIdentity`)
are modeled as separate tables, linked one-to-many. `AuthIdentity` holds one
row per `(user, provider)` pair: `provider`, `providerUserId` (the OAuth
provider's stable subject id, null for `LOCAL`), and `passwordHash`.

**Alternative rejected.** Putting provider id columns directly on `User`
(`googleId`, `githubId`, `appleId`, ...). Rejected because it requires a
`User` migration for every new provider, can't represent a user with more
than one login method, and mixes two concerns (who someone is vs. how they
prove it) into one table.

**Consequences.** Adding a provider (GitHub, Apple) means adding an enum
value and a callback handler — never a `User` migration. Every other module
in the system references people by `User.id` only and never needs to know
which provider(s) back that user. JWTs encode `User.id` only, never provider
information.

---

## 2. `passwordHash` lives on `AuthIdentity`, not `User`

**Context.** Following from (1): if login methods are pluggable, credential
storage has to be symmetric across all of them, not special-cased for
Email/Password.

**Decision.** `passwordHash` is a column on `AuthIdentity`, populated only
on the row where `provider = LOCAL`. OAuth rows leave it `null`.

**Alternative rejected.** A nullable `password` column on `User`. Rejected —
it's exactly the kind of auth-mechanism-specific field `User` is meant to
never carry (see decision 1), and it can't express "this user added a
password after originally signing up with Google."

**Consequences.** "Does this user have a password?" is answered by querying
for a `LOCAL` `AuthIdentity` row, not by a null-check on `User`. The
forgot-password flow must account for users who have no `LOCAL` identity at
all (Google-only accounts) — there's nothing to reset.

---

## 3. `profileCompleted` on `User`

**Context.** OAuth providers don't reliably supply every field Mikka
requires. `username` is never supplied by any provider. `gender` and
`birthDate` are frequently withheld by Google depending on granted scopes.

**Decision.** A single `profileCompleted: Boolean` flag on `User`, driven by
one centralized function (`computeProfileCompleted()`, to be implemented in
the Auth/User module) that checks the required-field set. This function is
called after every profile-relevant write — the initial OAuth callback,
local registration, and any later profile update — and applies identically
regardless of signup method.

**Alternative rejected.** Treating this as an OAuth-only concern (e.g. only
gating Google signups). Rejected because `username` is missing for every
fresh OAuth signup regardless of provider, and a local signup form could
just as legitimately defer non-essential fields to a post-signup step. One
mechanism, not two.

**Consequences.** The frontend redirects to "Complete Profile" whenever
`profileCompleted = false`, regardless of how the account was created. The
required-field set lives in exactly one place, so it can grow later (e.g. a
future mandatory field) without hunting down duplicated checks.

---

## 4. `email` stays `NOT NULL UNIQUE` for now

**Context.** Some OAuth providers can withhold email entirely (Apple can
return a private relay address or, in edge cases, none; hypothetical future
providers might omit it too). Making `email` nullable would be the more
"future-proof" choice.

**Decision.** For V1, `email` stays required and unique. Google's default
OAuth scope essentially always includes it, and Apple's relay address is
still a deliverable inbox — so the providers actually planned for V1/V2
(Google, then Apple/GitHub) don't force the nullable case in practice.
Simplicity now was chosen over speculative flexibility for a provider not
yet on the roadmap.

**Consequences / accepted tradeoff.** If a Google account genuinely
withholds the email scope (rare, but possible under some org policies), the
callback must reject the login with a clear, explicit error — not let it
fail as a raw `NOT NULL` constraint violation. This is an implementation
detail for the Auth module, noted here so it isn't missed.

**Revisit when:** a provider is added that cannot supply email at all. At
that point `email` becomes nullable and joins `username`/`gender`/
`birthDate` as a field that can gate `profileCompleted`.

**Related decision:** OAuth-to-existing-account linking only happens
automatically when the provider asserts `email_verified: true` **and** the
email matches an existing `User`. An unverified email claim never triggers
auto-linking — that would be an account-takeover vector.

---

## 5. Prisma 7 — non-obvious project-specific settings

Prisma 7 changed enough that a couple of settings here are load-bearing and
easy to accidentally revert. Both were found by actually booting the app
against a real database, not by reading changelogs.

**`generator client { moduleFormat = "cjs" }`** in `prisma/schema.prisma`.
Prisma 7's newer `"prisma-client"` generator (as opposed to the older
`"prisma-client-js"`) emits TypeScript source that, left to its own
defaults, targets ESM (`import.meta.url` appears in the compiled output).
This project's NestJS build compiles everything to CommonJS, and
`import.meta` has no CommonJS equivalent — the app crashed at boot with
`ReferenceError: exports is not defined in ES module scope` until this
option was set explicitly. Do not remove it without also moving the whole
project to ESM.

**`@prisma/adapter-pg` in `PrismaService`**. Prisma 7 requires a
`PrismaClientOptions` value with either `adapter` or `accelerateUrl` —
constructing `new PrismaClient()` with a bare connection string (the
pre-Prisma-7 way) no longer works at all. `PrismaService` builds a
`PrismaPg` adapter from `DATABASE_URL` (read via `ConfigService`) and passes
it as `adapter`. `pg` and `@prisma/adapter-pg` are runtime `dependencies`,
not dev-only.

**Two different places hold the database URL, on purpose.** `prisma.config.ts`
(loaded via `dotenv/config`) is read only by the Prisma **CLI** — `migrate`,
`generate`, `studio`. It has no effect on the running application. The
**application** gets `DATABASE_URL` exclusively through `ConfigService` →
`PrismaPg` adapter, validated by the Zod env schema. If a future contributor
only updates one of these, the other silently keeps using its own source —
worth remembering when debugging a "works via CLI but not in the app" (or
vice versa) issue.

**Client output path.** The generator writes to `generated/prisma/`
(project root, not `node_modules/@prisma/client`) — the modern recommended
Prisma 7 default. It's gitignored and regenerated by `prisma generate`,
which already runs as part of the Docker build stage. `prisma` (the CLI)
must stay in `dependencies`, not `devDependencies`, because
`prisma migrate deploy` runs inside the production container on boot (see
`Dockerfile`).

**Jest needs two extra settings, or any test that boots `PrismaModule`
fails.** Found by actually running `test:e2e`, not by reading docs:

1. The generated client's relative imports use `.js` extensions pointing at
   `.ts` files (standard TS `nodenext` convention) — `tsc`/`ts-node` resolve
   this automatically, but Jest's resolver doesn't. Both `package.json`'s
   `jest` block and `test/jest-e2e.json` need:
   ```json
   "moduleNameMapper": { "^(\\.{1,2}/.*)\\.js$": "$1" }
   ```
2. Prisma 7's WASM query compiler is loaded via a runtime `import()` —
   Jest's default CommonJS environment throws `A dynamic import callback was
   invoked without --experimental-vm-modules` the first time `PrismaService`
   connects. `test:e2e` runs as
   `node --experimental-vm-modules node_modules/.bin/jest ...` to work around
   it. If a unit test ever exercises real `PrismaService` connection (not
   just a mocked repository), it will need the same flag.

**Hand-written indexes on `Unsupported` columns get flagged as drift on the
*next* migration, not the one that adds them.** `location` (PostGIS
geography) and the trigram-search columns are `Unsupported` in
schema.prisma, so their indexes (the GiST index, the two GIN trigram
indexes) have no declarative representation Prisma can track. The
migration that first creates such an index is fine — but the *next* time
`prisma migrate dev` generates a migration, it replays migration history
against a shadow DB, compares that to what schema.prisma alone would
produce, sees the hand-added index as "shouldn't exist," and silently
includes a `DROP INDEX` for it in the new migration. Caught this exact
thing while adding the trigram indexes for Search — always read a
freshly generated `migration.sql` by hand before applying it if the
schema has any `Unsupported` columns; don't assume the diff is only
additive.

This isn't a one-time gotcha — it recurs on **every** subsequent
migration once any hand-written index exists anywhere in the schema.
Confirmed again adding the Review module's migration: Prisma tried to drop
all three prior hand-added indexes (the GiST index and both trigram
indexes) at once. Same fix each time — strip the erroneous `DROP INDEX`
lines before applying. The same reasoning applies to the `Review` model's
partial unique index (`WHERE "deletedAt" IS NULL`) — deliberately *not*
declared as `@@unique` in schema.prisma, specifically to avoid this
conflict; see the comment on `Review` in schema.prisma.

---

## 6. Backend obligations toward mobile client performance

The mobile client has its own constitution (widget-tree cost, FPS, battery,
render performance — not this repo's concern). But several of its
requirements are only satisfiable if the **backend** holds up its end. This
section is the backend's side of that contract — apply it to every module
from here on, not just retroactively to Place/Search.

**List/search responses are minimal by construction, not by afterthought.**
`PlaceListItem` / `SearchResult` (Place and Search modules) return only
`id, name, latitude, longitude, status, category { id, name }`, plus
`distanceMeters` when a geo query was given. Full detail — `description`,
`address`, `phone`, `website`, audit timestamps — lives behind
`GET /places/:id` only. A list endpoint returning full rows is "fetching
1000 records when 20 are visible" in miniature: the same over-fetch
repeated once per item on every page. New list-shaped endpoints (Chat
message lists, Story feeds, Friend lists, Saved Places) should default to
a minimal projection the same way, not the full Prisma model.

**Global response compression is on** (`compression` middleware in
`main.ts`) — applies to every response automatically, nothing per-endpoint
to remember.

**`Cache-Control` on read-only endpoints that don't change every request**
(`GET /place-categories`, `GET /places/:id`, `GET /places/:placeId/rating`)
— short `max-age`s (60s–300s) chosen per how often the underlying data
actually changes. Not applied to paginated list/search endpoints (results
shift too often to make a fixed TTL meaningful) or to anything
authenticated/per-user. Full ETag/conditional-GET (304) support is a
reasonable future upgrade, not built now — would need a content hash or
`updatedAt`-based check per endpoint, more machinery than V1 needs.

**Image handling, once the Upload/Photo module exists:** convert to WebP
(or AVIF) on upload, generate at least one thumbnail size server-side —
never make the mobile client download a full-resolution image to render a
list thumbnail. This is a requirement to design in from that module's
first schema draft, not a retrofit.

**Already-established patterns that also serve this goal, not repeated
here in detail:** pagination is mandatory on every list endpoint (done
since Place); repositories `select`/project only needed columns instead of
full rows (User's public-profile projection, Review's reviewer
projection); the DB-trigger pattern for derived data (`location`,
`place_rating_summaries`) avoids the client ever needing to compute or
re-fetch aggregates itself.

---

## 7. `GET /places` radius search falls back to a Region, not to Nominatim

When a radius search (`lat`/`lng`/`radiusMeters`, now fixed presets 1/3/15
km — see `RADIUS_METERS_OPTIONS`) comes back empty, the naive fix is to
just tell the client "nothing here." Instead `PlaceService.list` widens the
search to the administrative region containing the user's point (new
`Region` model: `id`, `name`, `boundary geometry(MultiPolygon, 4326)`).

**Why not reverse-geocode via Nominatim at search time instead** (no new
table, no boundary data needed)? Because it puts an external HTTP call —
rate-limited to 1 req/sec on the public instance — on a hot, unauthenticated
read path. That fails the "tens of thousands, eventually millions of
places" bar outright, regardless of how good Nominatim's answer would be.
The `Region` approach costs one indexed `ST_Contains` against a handful of
rows and zero network calls.

**`Place.regionId` is resolved the same way `location` is** — a
`BEFORE INSERT OR UPDATE OF latitude, longitude` trigger
(`sync_place_region`) does the point-in-polygon lookup and sets it; app
code never writes it directly. It's nullable: a place (or a search point)
outside every seeded region's boundary simply gets `null`/no fallback —
expected today, see next point.

**`Region` rows are real administrative boundaries, not placeholders.**
The `add_region_fallback` migration originally seeded two rough
`ST_MakeEnvelope` rectangles ("Tashkent City", "Samarkand Region") just to
prove the mechanism end to end. The follow-up `seed_real_uz_regions`
migration replaces them with all 14 real Uzbekistan ADM1 boundaries
(12 viloyat + Tashkent City + Republic of Karakalpakstan), sourced from
[geoBoundaries.org](https://www.geoboundaries.org) (OSM-derived, ODbL
license, simplified geometry — precise enough for this fallback, not
survey-grade) and loaded via `ST_GeomFromGeoJSON`. A place — or a search
point — outside all 14 boundaries (e.g. international waters, a
data-entry error) still legitimately gets `null`/no fallback. Re-seeding
again later (a boundary revision, a higher-resolution source) only means
replacing rows in `regions`; trigger, repository, and service code are
unaffected.

**Same `DROP INDEX` migration-drift gotcha as section 5** hit again here —
`prisma migrate dev` tried to drop the two pg_trgm indexes and the
`places_location_gist_idx` GiST index alongside generating this migration,
for the same reason (no declarative equivalent for GiST/GIN in
schema.prisma). Stripped by hand before applying, as always; the new
`regions_boundary_gist_idx` has the same problem going forward.

**Scope note:** this fallback lives entirely in the Place module
(`PlaceRepository.findRegionContaining` / `findByRegion`,
`PlaceService.list`) and only backs `GET /places`. The Search module's own
`lat`/`lng` filter (`GET /search/places`) is untouched — it doesn't own
ranking or geo-fallback logic for Place data, Place does; see section on
Search in CLAUDE.md. If Search needs the same fallback later, the query
methods are already factored to be called from there too — no duplication
required, just a decision to wire it in.

---

## 8. Friendship module: two tables, no status column, hard delete

`FriendRequest` has no `status` field. Existence of a row **is** "pending" —
accepting deletes the row and creates two `Friendship` rows in the same
transaction (`FriendRequestRepository.acceptAndCreateFriendship`);
declining/canceling just deletes it. No history of past requests is kept.
This was a deliberate simplicity call per CLAUDE.md ("keep V1 simple"), not
an oversight — a "who declined whom, when" audit trail isn't a stated V1
need, and re-requesting after a decline is allowed immediately (no
cooldown), confirmed with the product owner rather than assumed.

**`Friendship` is denormalized on purpose** — becoming friends writes two
rows (`(A,B)` and `(B,A)`), not one row queried with `userAId OR
userBId`. Doubles storage, but "list my friends" — the hot path, and one
Chat/Story/Privacy will all read later — becomes a single indexed equality
lookup on `userId` instead of an OR across two columns. Unfriending
deletes both rows in one `deleteMany` (one round trip, not two).

**None of `FriendRequest`/`Friendship`/`Block` use soft delete
(`deletedAt`).** Unlike `Place`/`Review`/`User`, there's no product need to
recover a canceled request, an ended friendship, or a lifted block — soft
delete elsewhere in this schema exists for moderation/audit reasons that
don't apply here. Hard delete keeps the "is X true right now" queries
(friends list, block check) simple existence checks with no `WHERE
deletedAt IS NULL` to remember.

**`Block` is intentionally out of CLAUDE.md's stated V1 feature list** —
added anyway on explicit request, scoped narrowly: it only (a) prevents
new `FriendRequest`s between the two users (checked both directions,
generic error either way — the blocked party is never told which side
blocked, or that a block is the reason) and (b) tears down any existing
`Friendship`/`FriendRequest` between them at block time
(`BlockRepository.blockAndCleanup`, one transaction). It does **not** hide
the blocker's profile, reviews, check-ins, or chat messages from the
blocked user — those are Privacy/Chat module concerns for whenever those
modules exist, not retrofitted here.

**Route layout mirrors CheckIn's precedent**, not User's: `FriendshipController`
and `BlockController` both declare full paths (`users/me/friends`,
`users/:userId/block`) under `@Controller()` with no prefix, coexisting
with `UserController`'s own `@Controller('users')` routes — same pattern
already established for `users/me/check-ins`.

---

## 9. Privacy module: one module owns visibility, content modules stay ignorant of Friendship

**The concrete V1 scope is narrow on purpose:** `PrivacySettings` has one
field, `checkInVisibility` (`PUBLIC`/`FRIENDS`/`PRIVATE`, default
`FRIENDS`). A `locationSharingEnabled`-style toggle was deliberately left
out — nothing reads it yet (Chat doesn't exist), and a setting with zero
consumers is exactly the "half-finished implementation" CLAUDE.md rules
out. Add it when Chat exists and actually needs it, not before.

**The load-bearing architecture decision: `PrivacyModule` imports
`FriendshipModule` directly** (`FriendshipRepository` exported for this
purpose) and exposes exactly two methods —
`getSettings(userId)` and `canView(viewerId, ownerId, visibility)`. This is
the first place in the codebase where one module depends on another's
*service*, not just a locally-duplicated existence check (contrast
Review's `placeExists` or CheckIn's `findUserIdByUsername` — deliberately
local per module-independence). The difference: "does place X exist" is a
trivial, freely-duplicable check; "is this visibility rule satisfied" is
real business logic that would otherwise have to be duplicated in every
content module that needs it. `CheckInModule` imports `PrivacyModule` but
has no idea `Friendship` exists — same pattern `Story`'s eventual privacy
gating (or any future content type) should follow: import `PrivacyModule`
only, never `FriendshipModule` directly.

**`GET /users/:username/check-ins` needed a guard that doesn't reject
anonymous callers** — `PUBLIC` visibility must work logged-out, same as
`GET /places` or `GET /users/:username`. `JwtAuthGuard` throws
`UnauthorizedException` on a missing/invalid token, so a new
`OptionalJwtAuthGuard` (overrides `handleRequest` to swallow the
error/absent-user case instead of throwing) plus a matching
`@OptionalCurrentUser()` decorator (honestly typed `AuthenticatedUser |
undefined`, unlike `@CurrentUser()`) were added to the Auth module. This
is a reusable pair for any future endpoint that behaves differently for
logged-in vs. anonymous callers, not a CheckIn-specific hack.

**Caught during manual testing, not in the original design: exact
coordinate leakage.** The first implementation had `listForUser` reuse
`listMine`'s repository query, which selects full `CheckIn` rows
(`latitude`, `longitude`, `userId`, `deletedAt`) — fine for the owner
viewing their own data via `/users/me/check-ins`, but this endpoint is
reachable by *other* people once visibility allows it. "Which place, when"
is what a viewer needs; exact GPS coordinates of where someone was
standing is meaningfully more than that. Fixed with a separate
`findManyByUserPublic` repository method using an explicit Prisma
`select` (not just a narrower TS return type — a wider runtime object
still serializes in full regardless of what the type annotation claims)
and a distinct `PublicCheckInItem` type. `listMine`/`CheckInWithPlace`
(self-view only) are unchanged.

**Self always passes `canView`,** checked before the `PUBLIC`/`FRIENDS`/`PRIVATE`
branches — so an owner with `PRIVATE` set can still hit their own
`/users/:username/check-ins`, getting the same minimal `PublicCheckInItem`
shape as any other viewer would (not the fuller `listMine` shape) —
consistency of one endpoint's response shape won out over "give the owner
everything everywhere."

---

## 10. Saved Places: idempotent by design, unlike FriendRequest

`SavedPlace` is a flat bookmark list — no folders/collections, matching
CLAUDE.md's "keep V1 simple" (the feature list says "Saved Places," not
"Saved Place Collections"). Hard delete, same reasoning as
Friendship/Block: unsaving has no audit/undo need.

**Save and unsave are both idempotent** — `save()` upserts
(`update: {}` on conflict) instead of erroring on a repeat save, and
`unsave()` uses `deleteMany` instead of erroring when nothing was saved.
This is a deliberate departure from `FriendRequest`'s `ConflictException`
on a duplicate, or `Friendship.remove`'s `NotFoundException` on
unfriending a non-friend: bookmarking is a low-stakes toggle a client
might retry or double-fire (e.g. a double-tap), not a one-time social
action where "this already happened" is meaningful information worth
surfacing as an error.

**`GET /places/:placeId/saved-places/count` is public**, same reasoning as
`CheckIn`'s count endpoint: aggregate-only, no who/when, so it needs no
Privacy-module gating.

---

## 11. Admin module: only the stats aggregation actually lives here

`AdminModule` is deliberately thin. Place/PlaceCategory admin CRUD already
exists, gated with `@Roles(Role.ADMIN)` directly on `PlaceController` —
nothing new needed there, and no reason to wrap or duplicate it behind an
`/admin/*` path. The only thing that genuinely had no owner was **stats
that span multiple tables** (`totalUsers`, `totalPlaces`, `totalReviews`,
`totalCheckIns`) — that's the one piece that actually lives in
`AdminRepository`/`AdminService`.

**User management (`GET /admin/users`, `GET /admin/users/:id`, ban/unban)
is exposed through `AdminController`, but the actual logic
(`listForAdmin`, `getForAdmin`, `ban`, `unban`) lives in `UserService`** —
`AdminService` just delegates. This was forced by a routing collision, not
just architectural taste: `UserController` already has `GET
/users/:username` (public profile lookup) — a second `GET /users/:id` (by
id, admin-only) on the same controller would collide on the same path
shape (single dynamic segment, both GET). Nesting the admin user routes
under `/admin/*` instead sidesteps the collision entirely and happens to
match the standard "one API namespace an admin panel client hits"
convention anyway.

**`isBanned` is a separate boolean from `deletedAt`, not a repurposing of
it.** `deletedAt` means gone, permanently, with no undelete flow anywhere
in this codebase. A ban is a reversible moderation action — administrator
error, appeal, temporary suspension — so it needed its own field. See the
`User.isBanned` comment in schema.prisma.

**Banning revokes every refresh token immediately** (`AdminService.banUser`
calls `TokenService.revokeAllForUser` right after `UserService.ban`), so
the ban takes effect now rather than whenever a 30-day-lived refresh token
would have naturally expired. This is why `AdminModule` imports
`AuthModule` (newly exporting `TokenService`) in addition to `UserModule`
— `UserService.ban` only flips the flag; the cross-module reach into Auth
belongs at the orchestration layer (`AdminService`), not inside
`UserService`, which has no business knowing refresh tokens exist. One
caveat kept deliberately, not fixed: the still-short-lived (15 min)
*access* token keeps working until it naturally expires — matches the
same acceptable limitation already noted for password-reset-triggered
revocation.

**Login checks `isBanned` in both `login()` and `loginWithGoogle()`** —
initially only added to `login()`, then found missing from
`loginWithGoogle`'s two return paths (existing-identity fast path, and the
find-or-create-by-email path) during review of the change, not caught by
a test. Both now check before issuing tokens.

**Self-ban is blocked** (`UserService.ban` throws if `id ===
requestedByUserId`) — a solo admin banning their own only account would
be a real lockout with no other admin to undo it.

**Review moderation reuses the existing `DELETE /reviews/:id` endpoint**
rather than adding an `/admin/reviews/:id` route — `ReviewService.remove`
gained an `isAdmin` parameter (`review.userId !== userId && !isAdmin`).
Same reasoning as Place: admin capability lives inside the domain module
that already owns the resource, not funneled through Admin.

---

## 12. Story: `CheckInVisibility` became `ContentVisibility`, and why the feed needed more than `canView`

**`CheckInVisibility` was renamed to `ContentVisibility`** the moment a
second content type (Story) needed the identical PUBLIC/FRIENDS/PRIVATE
set — `PrivacySettings` now has both `checkInVisibility` and
`storyVisibility`, sharing one enum. `PrivacyService.canView` was already
generic over the visibility value (see section 9's closing note — this is
that "future content type" arriving). The migration renames the Postgres
type in place (`ALTER TYPE check_in_visibility RENAME TO
content_visibility`) rather than the drop-and-recreate Prisma generated by
default, which would have discarded every existing `checkInVisibility`
value on `privacy_settings` — caught by reading the generated migration's
own `Warnings:` comment before applying it, not by inspection alone.

**`PATCH /users/me/privacy-settings` became a true partial update** (both
fields now optional, `.refine` requires at least one) — needed the moment
there were two independent settings; requiring the client to resend the
one it isn't changing would have been a real usability regression.

**`GET /stories/feed` needed more than `canView`, which is why
`PrivacyService.filterOutPrivate` exists.** `canView(viewer, owner,
visibility)` answers "can this one viewer see this one owner's content" —
correct for `GET /users/:username/stories` (a single owner), but a feed
aggregates *many* owners at once, and the naive "they're my friend, so
FRIENDS visibility passes" check is wrong for a friend who set
`storyVisibility` to `PRIVATE`: that must exclude them from the feed
entirely, friendship notwithstanding. `filterOutPrivate` takes the
candidate friend-id list and returns which ones explicitly opted out — the
one query shape `canView` doesn't cover. Verified manually: a friend's
story disappeared from the viewer's feed the moment `PRIVATE` was set,
even though `Friendship` between them was untouched.

**`FriendshipRepository.findAllFriendIds` is new and deliberately
unpaginated** — the feed's `WHERE userId IN (...)` needs the *complete*
friend-id list, not one page of it. Never exposed as its own controller
route; a friend count (hundreds at most) is a different scale problem than
listing all users, which is why this doesn't set a precedent for
unpaginated user-facing endpoints elsewhere.

**`GET /stories/:id/viewers` is owner-only regardless of the story's own
visibility** — `storyVisibility` controls who can see the *content*; the
audience list is separate information that only ever belongs to the
poster, the same distinction Instagram/Snapchat make. Marking a story
viewed (`POST /stories/:id/view`) still runs the same `canView` check
first, so it can't be used to confirm the existence of a story you
otherwise couldn't see, and is a no-op for the story's own owner (you
don't "view" your own story) — idempotent otherwise, same reasoning as
`SavedPlace`.

**No expiry cleanup job** — `expiresAt` is checked in every active-story
query (`WHERE expiresAt > now()`), the same filtering-not-deleting pattern
as `deletedAt` throughout this schema. Expired rows stay in Postgres
indefinitely; an actual cleanup job would need `@nestjs/schedule` (not a
dependency yet) and wasn't worth adding for V1 — correctness doesn't
depend on it, only eventual disk usage does.

---

## 13. Chat: REST is the source of truth, WebSocket is push-only

**First WebSocket infrastructure in this codebase** (`@nestjs/websockets`
+ `socket.io`, new dependencies). Deliberately scoped narrow: every
mutation (send/delete a message, react, create/rename a conversation)
happens over the same REST endpoints as everything else in this app, with
full Zod validation, guards, and the usual Controller → Service →
Repository layering. `ChatGateway` never accepts writes — its only job is
telling already-connected clients "this changed" after a REST call
already persisted it. This keeps chat testable and reasoned-about the
same way as every other module (verified in this session with plain
`curl`), with the gateway as a thin, separately-verified push layer on
top (verified with a small `socket.io-client` script — see below).

**Per-user rooms, not per-conversation rooms.** On connect, a socket joins
exactly one room, `user:{id}` — never a conversation-specific room, and
there's no client-driven `join_conversation`/`leave_conversation`
protocol. Broadcasting an event means looking up a conversation's active
participant ids (`ConversationRepository.findActiveParticipantIds`) and
emitting to each one's user-room. Simpler to reason about and implement
than conversation-room membership tracking, at the cost of one small
participant-id query per broadcast — a fine trade at V1 scale, and
avoids an entire class of "did the client actually join the room before
the message arrived" race conditions.

**WebSocket auth bypasses `JwtAuthGuard` entirely** — Passport's
`AuthGuard('jwt')` is wired for Express's request/response cycle
(`ExtractJwt.fromAuthHeaderAsBearerToken()` reads an HTTP header), which
doesn't exist on a socket.io handshake. `ChatGateway.handleConnection`
extracts the token from `handshake.auth.token` (falling back to an
`Authorization` header for flexibility) and verifies it directly via
`JwtService.verifyAsync`, then re-checks `!user || user.deletedAt ||
user.isBanned` — the same guarantee `JwtStrategy.validate` gives HTTP
requests, reimplemented because there's no Passport strategy hook to
reuse here. This is why `AuthModule` now exports the whole `JwtModule` it
already imports (previously exported nothing but `TokenService`) —
`ChatModule` needs `JwtService` injectable directly, not just an HTTP
guard.

**A client connecting with an invalid token still briefly "connects."**
socket.io's transport-level handshake completes before NestJS's
`handleConnection` hook runs any application logic, so the client always
sees a `connect` event first — `handleConnection` then immediately calls
`client.disconnect(true)` if the token fails. Confirmed with a test
script that initially asserted "connect firing = auth bypassed" and had
to be corrected to check for the disconnect that follows — the interesting
gotcha here isn't in the server code, it's in what a naive test of it
would get wrong.

**Reaction broadcasts intentionally drop `reactedByMe`.**
`MessageItem.reactions` (`{emoji, count, reactedByMe}[]`) is personalized
per viewer — correct for a REST response to one specific caller, wrong
for one WebSocket payload fanned out to every participant identically.
`ChatGateway.broadcastReactionUpdated` carries `{emoji, count}[]` only
(`ReactionRepository.getReactionSummary`, a plain `groupBy`, not the
per-viewer grouping `MessageRepository`'s `toMessageItem` does) — clients
already know locally whether they're the one who just reacted. The
equivalent question for `new_message` broadcasts turned out to be moot: a
freshly created message has zero reactions by construction, so reusing
the sender's own computed `MessageItem` as the broadcast payload is safe
without needing the same split.

**PRIVATE conversations are get-or-created**
(`ConversationRepository.findExistingPrivate`, matched by two ANDed
`participants.some` existence checks) — requesting a new one between the
same two people always returns the existing thread, matching how every
consumer chat app behaves; a client shouldn't need to remember a
conversation id to "message this friend" a second time. GROUP always
creates a new row; no dedup makes sense there.

**Every conversation-creation and add-participant path requires an
existing `Friendship`** (`ConversationService.requireFriend`, backed by
`FriendshipRepository.exists` — the same repository Privacy also
consumes, now a third module reaching into Friendship for its own
distinct reason). This is a spam/harassment guard, not enforced again on
every message send — once a conversation exists, it keeps working even if
the two later unfriend each other, matching how most chat apps treat an
existing thread as independent of current friend status.

**Leaving is `leftAt`, not a deleted row** — `ConversationParticipant`
persists after someone leaves a GROUP (`removeParticipant`/self-leave are
the same underlying operation) so their past messages stay attributed to
a real participant record instead of an orphaned sender reference. PRIVATE
conversations don't support leaving at all — schema and service both
enforce this, there's no product meaning to "leaving" a 1:1 thread.

**Unread count costs one extra query per conversation in a page of
results** (`MessageRepository.countUnread`, called once per row in
`ConversationService.list`) — each conversation-participant pair has its
own `lastReadAt` threshold, which doesn't fit inside
`ConversationRepository.findManyForUser`'s single query the way the
last-message preview does (that one's a plain `take: 1` nested relation,
no per-row-varying filter). Bounded by page size (≤100), not the total
conversation count, so this isn't the kind of N+1 that scales badly — just
documented as a known, deliberate shape rather than an oversight.

**`Conversation.createdById` is `ON DELETE RESTRICT`**, same choice as
`Place.createdById` — deleting a user whose conversation other people are
still active in shouldn't silently destroy their shared history. Matters
for test cleanup (conversations must be deleted before their creator's
user row) but is otherwise invisible in normal operation, since users are
soft-deleted everywhere else in this schema anyway.

---

## 14. Notification: the last module, and the only one that's event-driven

**Every other module in this codebase talks to another one (if at all) by
directly injecting its repository or service** — Privacy imports
Friendship, Chat imports Friendship, Story imports Friendship and Privacy.
Notification is the exception on purpose: `FriendRequestService.create`,
`MessageService.send`, and `StoryService.create` each emit a plain domain
event (`@nestjs/event-emitter`, newly added) —
`friend-request.created`/`message.created`/`story.created` — and have
**no import of NotificationModule, no awareness it exists.** The
difference from every prior direct-dependency case: those were each one
consumer needing one specific decision from one specific other module
(Privacy needs "are these two friends," Chat needs the same). Notification
is the reverse shape — one consumer, many unrelated producers — which is
exactly what an event bus is for and direct injection isn't: adding a
fourth notification trigger later means adding a listener, not modifying
Friendship/Chat/Story/Review's own code to know about Notification.

**Each event's producing module owns the event's contract** — the name
constant and payload interface live in the producer's own directory
(`src/friendship/events/`, `src/chat/events/`, `src/story/events/`), not
`src/notification/`. `NotificationModule`'s listeners import *from* those
files; the producers import nothing back.

**Two different payload shapes, deliberately, not by accident.**
`FriendRequestCreatedEvent`/`StoryCreatedEvent` carry ids only — the
listener resolves everything else itself (username via
`NotificationRepository.findUserProfile`, a local minimal lookup, same
pattern as every module's existing `placeExists`/`findUserIdByUsername`
checks; for Story, also "which friends, minus anyone excluded by
`PRIVATE`," via the same `FriendshipRepository`/`PrivacyService` reach
Chat and Privacy already have). `MessageCreatedEvent` instead carries the
resolved recipient list and rendered content facts (text/imageUrl/
placeName) — because `MessageService.send` had already computed exactly
that a moment earlier for its own WebSocket broadcast
(`ChatGateway.broadcastNewMessage`), and re-deriving it via a fresh
`ConversationRepository` query from Notification would be a wasted round
trip for data that already exists in hand. Same "listener resolves
identity, event carries structural facts" split either way — just applied
differently because Chat had already done part of that work and
Friendship/Story hadn't.

**Story's own-owner visibility check is `PrivacyService.getSettings`, not
`filterOutPrivate`** — easy to reach for the wrong one, since both exist
for "story visibility + friends." `filterOutPrivate` answers "given a
*list* of potential story owners (a viewer's friends), which of them
opted out" — built for the feed, where there are many owners and one
viewer. Here there's exactly one owner (the story's author) and the
question is simpler: is *this* person's own setting `PRIVATE`? If so,
nobody gets notified, full stop — `getSettings` gives that answer
directly without forcing the single id through a list-shaped API built for
a different question.

**A second WebSocket gateway, not a shared one.** `NotificationGateway`
duplicates the shape of `ChatGateway` (own namespace `/notifications`,
same per-user-room design, same push-only contract) but is its own class
— the connection-authentication logic is what's actually shared
(`authenticateSocketUser`/`userRoom`, factored out to
`src/common/websocket/` the moment a second gateway needed the identical
handshake-JWT-verification code, with `ChatGateway` refactored to use it
too rather than leaving two copies). Two full gateway *classes* stayed
separate because Notification and Chat are independent modules with no
reason to depend on each other just because both happen to use sockets.

**Verified with the same two-part method as Chat**: REST/event flow via
`curl` (friend request → notification appears; message → notification
appears, with "shared a place" wording when `placeId` is set; `PRIVATE`
story → friend's unread count provably unchanged), then real-time push
via a `socket.io-client` script connecting to `/notifications` — confirmed
Bob received a `notification` event within the same second Alice's
message created it.