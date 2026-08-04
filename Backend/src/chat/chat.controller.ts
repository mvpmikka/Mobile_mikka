import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { Role } from '../../generated/prisma/client';
import { ConversationService } from './services/conversation.service';
import { MessageService } from './services/message.service';
import { ReactionService } from './services/reaction.service';
import { createConversationSchema } from './dto/create-conversation.dto';
import type { CreateConversationDto } from './dto/create-conversation.dto';
import { updateConversationSchema } from './dto/update-conversation.dto';
import type { UpdateConversationDto } from './dto/update-conversation.dto';
import { addParticipantSchema } from './dto/add-participant.dto';
import type { AddParticipantDto } from './dto/add-participant.dto';
import { createMessageSchema } from './dto/create-message.dto';
import type { CreateMessageDto } from './dto/create-message.dto';
import { reactToMessageSchema } from './dto/react-to-message.dto';
import type { ReactToMessageDto } from './dto/react-to-message.dto';
import { listQuerySchema } from './dto/list-query.dto';
import type { ListQueryDto } from './dto/list-query.dto';

// Every route requires auth — unlike CheckIn/Story, chat has no
// public/anonymous-visibility concept at all (see Friendship-gated
// conversation creation), so the guard is applied once at class level.
@Controller()
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private readonly conversationService: ConversationService,
    private readonly messageService: MessageService,
    private readonly reactionService: ReactionService,
  ) {}

  @Post('conversations')
  createConversation(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createConversationSchema))
    dto: CreateConversationDto,
  ) {
    return this.conversationService.create(currentUser.id, dto);
  }

  @Get('conversations')
  listConversations(
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.conversationService.list(
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Get('conversations/:id')
  getConversation(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.conversationService.getById(id, currentUser.id);
  }

  @Patch('conversations/:id')
  renameConversation(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(updateConversationSchema))
    dto: UpdateConversationDto,
  ) {
    return this.conversationService.rename(id, currentUser.id, dto.name);
  }

  @Post('conversations/:id/participants')
  addParticipant(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(addParticipantSchema)) dto: AddParticipantDto,
  ) {
    return this.conversationService.addParticipant(
      id,
      currentUser.id,
      dto.userId,
    );
  }

  @Delete('conversations/:id/participants/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeParticipant(
    @Param('id') id: string,
    @Param('userId') userId: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.conversationService.removeParticipant(
      id,
      currentUser.id,
      userId,
    );
  }

  @Patch('conversations/:id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  markRead(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.conversationService.markRead(id, currentUser.id);
  }

  @Get('conversations/:id/messages')
  listMessages(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Query(new ZodValidationPipe(listQuerySchema)) query: ListQueryDto,
  ) {
    return this.messageService.list(
      id,
      currentUser.id,
      query.page,
      query.limit,
    );
  }

  @Post('conversations/:id/messages')
  sendMessage(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(createMessageSchema)) dto: CreateMessageDto,
  ) {
    return this.messageService.send(id, currentUser.id, dto);
  }

  // Sender can always delete their own; an ADMIN can delete anyone's
  // (moderation) — same pattern as Review/Story.
  @Delete('messages/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeMessage(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.messageService.remove(
      id,
      currentUser.id,
      currentUser.role === Role.ADMIN,
    );
  }

  @Post('messages/:id/reactions')
  @HttpCode(HttpStatus.NO_CONTENT)
  react(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
    @Body(new ZodValidationPipe(reactToMessageSchema)) dto: ReactToMessageDto,
  ) {
    return this.reactionService.react(id, currentUser.id, dto.emoji);
  }

  @Delete('messages/:id/reactions')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeReaction(
    @Param('id') id: string,
    @CurrentUser() currentUser: AuthenticatedUser,
  ) {
    return this.reactionService.removeReaction(id, currentUser.id);
  }
}