import { z } from 'zod';

// SUPER_ADMIN's decision on a submitted document. rejectReason is required
// only when rejecting — an approval needs no explanation, a rejection does
// (the owner needs to know what to fix before resubmitting).
export const reviewVerificationSchema = z
  .object({
    status: z.enum(['APPROVED', 'REJECTED']),
    rejectReason: z.string().trim().min(1).max(500).optional(),
  })
  .refine((dto) => dto.status !== 'REJECTED' || !!dto.rejectReason, {
    message: 'rejectReason is required when rejecting',
    path: ['rejectReason'],
  });

export type ReviewVerificationDto = z.infer<typeof reviewVerificationSchema>;
