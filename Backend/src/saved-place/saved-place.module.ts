import { Module } from '@nestjs/common';
import { SavedPlaceController } from './saved-place.controller';
import { SavedPlaceService } from './saved-place.service';
import { SavedPlaceRepository } from './repositories/saved-place.repository';

@Module({
  controllers: [SavedPlaceController],
  providers: [SavedPlaceService, SavedPlaceRepository],
})
export class SavedPlaceModule {}