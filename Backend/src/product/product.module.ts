import { Module } from '@nestjs/common';
import { PlaceModule } from '../place/place.module';
import { ProductController } from './product.controller';
import { ProductService } from './services/product.service';
import { ProductRepository } from './repositories/product.repository';

@Module({
  imports: [PlaceModule],
  controllers: [ProductController],
  providers: [ProductService, ProductRepository],
})
export class ProductModule {}
