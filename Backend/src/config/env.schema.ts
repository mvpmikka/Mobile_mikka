import { z } from 'zod';

// .env intentionally ships MAIL_* keys present but empty until a real
// provider is configured; treat "" the same as unset rather than failing.
const emptyToUndefined = (value: unknown) => (value === '' ? undefined : value);

export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().int().positive().default(3000),

  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // Mail provider config — left empty until a real provider is configured.
  // MailModule falls back to a console provider when MAIL_HOST is unset.
  MAIL_HOST: z.string().default(''),
  MAIL_PORT: z.preprocess(
    emptyToUndefined,
    z.coerce.number().int().positive().optional(),
  ),
  MAIL_USER: z.string().default(''),
  MAIL_PASSWORD: z.string().default(''),
  MAIL_FROM: z.string().default(''),
  MAIL_SECURE: z.preprocess(
    emptyToUndefined,
    z
      .enum(['true', 'false'])
      .default('false')
      .transform((value) => value === 'true'),
  ),

  // Used to build links inside verification/reset emails.
  FRONTEND_URL: z.string().min(1, 'FRONTEND_URL is required'),

  JWT_ACCESS_SECRET: z
    .string()
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  REFRESH_TOKEN_EXPIRES_IN_DAYS: z.coerce.number().int().positive().default(30),

  EMAIL_VERIFICATION_EXPIRES_IN_HOURS: z.coerce
    .number()
    .int()
    .positive()
    .default(24),
  PASSWORD_RESET_EXPIRES_IN_MINUTES: z.coerce
    .number()
    .int()
    .positive()
    .default(30),

  // Left empty until a real Google OAuth client exists — same pattern as
  // MAIL_*. GoogleAuthService rejects with a clear error if called while unset,
  // rather than the app failing to boot.
  GOOGLE_CLIENT_ID: z.string().default(''),

  // Nominatim usage policy requires a descriptive User-Agent identifying
  // the app (with contact info) — not a secret, but required to be a real
  // value before geocoding calls are made.
  NOMINATIM_USER_AGENT: z.string().default(''),
  NOMINATIM_BASE_URL: z.string().default('https://nominatim.openstreetmap.org'),

  // Left empty until a real Supabase project exists — same graceful
  // pattern as Mail/Google/Nominatim. StorageService rejects uploads with
  // a clear error while unset, rather than the app failing to boot.
  SUPABASE_URL: z.string().default(''),
  SUPABASE_SERVICE_ROLE_KEY: z.string().default(''),
  SUPABASE_STORAGE_BUCKET: z.string().default(''),

  CHECK_IN_MAX_DISTANCE_METERS: z.coerce.number().positive().default(200),
  CHECK_IN_COOLDOWN_MINUTES: z.coerce.number().positive().default(15),
});

export type EnvConfig = z.infer<typeof envSchema>;
