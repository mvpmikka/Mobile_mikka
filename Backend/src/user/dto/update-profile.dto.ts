import { z } from 'zod';
import { Gender } from '../../../generated/prisma/client';
import { usernameSchema } from '../username.schema';

const MIN_AGE_YEARS = 13;

function isOldEnough(birthDate: Date): boolean {
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const hadBirthdayThisYear =
    today.getMonth() > birthDate.getMonth() ||
    (today.getMonth() === birthDate.getMonth() &&
      today.getDate() >= birthDate.getDate());
  if (!hadBirthdayThisYear) {
    age -= 1;
  }
  return age >= MIN_AGE_YEARS;
}

export const updateProfileSchema = z.object({
  username: usernameSchema.optional(),
  fullName: z.string().trim().min(1).max(100).optional(),
  gender: z.enum(Gender).optional(),
  birthDate: z.coerce
    .date()
    .max(new Date(), 'birthDate must be in the past')
    .refine(isOldEnough, `You must be at least ${MIN_AGE_YEARS} years old`)
    .optional(),
  avatarUrl: z.string().trim().url().max(500).optional(),
  bio: z.string().trim().max(280).optional(),
});

export type UpdateProfileDto = z.infer<typeof updateProfileSchema>;
