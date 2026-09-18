import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // Compresses every JSON response — a mobile client on a slow connection
  // benefits directly, at effectively zero cost on modern server CPUs.
  app.use(compression());

  // Request/response bodies are validated with Zod (ZodValidationPipe), not
  // class-validator DTOs, so Swagger can't introspect field-level schemas
  // automatically — this still gives every route, method, and auth
  // requirement, which is the useful part for a developer browsing the API.
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Mikka API')
    .setDescription('Mikka backend — Place Discovery & Social Platform API')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api-docs', app, swaggerDocument);

  const configService = app.get(ConfigService);
  await app.listen(configService.get<number>('PORT', 3000));
}

void bootstrap();
