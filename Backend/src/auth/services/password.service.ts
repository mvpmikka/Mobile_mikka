import { Injectable } from '@nestjs/common';
import { hash, verify, argon2id } from 'argon2';

@Injectable()
export class PasswordService {
  hash(plain: string): Promise<string> {
    return hash(plain, { type: argon2id });
  }

  verify(passwordHash: string, plain: string): Promise<boolean> {
    return verify(passwordHash, plain);
  }
}
