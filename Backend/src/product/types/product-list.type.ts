import type { Product } from '../../../generated/prisma/client';

export interface ProductListResult {
  items: Product[];
  total: number;
  page: number;
  limit: number;
}

export interface ProductStats {
  totalProducts: number;
  lowStock: number;
  outOfStock: number;
}
