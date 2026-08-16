import { Controller, Get, Header } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  // Public URL submitted to Google Play / App Store listings — must stay
  // reachable at this exact path without auth.
  @Get('legal/privacy-policy')
  @Header('Content-Type', 'text/html')
  privacyPolicyPage(): string {
    return this.buildPrivacyPolicyPage();
  }

  private buildPrivacyPolicyPage(): string {
    return `<!doctype html>
<html lang="uz">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Mikka — Maxfiylik siyosati</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #FBEEE0; color: #2b2b2b; padding: 48px 24px; line-height: 1.6; max-width: 720px; margin: 0 auto; }
  h1 { color: #E97A3C; }
  h2 { margin-top: 32px; }
  a { color: #E97A3C; }
</style>
</head>
<body>
<h1>Mikka — Maxfiylik siyosati</h1>
<p>Amal qilish sanasi: 2026-08-17</p>

<p>Ushbu sahifa Mikka mobil ilovasi (Google Play va App Store'da) foydalanuvchilarining shaxsiy ma'lumotlari qanday yig'ilishi, ishlatilishi va saqlanishini tushuntiradi.</p>

<h2>Biz yig'adigan ma'lumotlar</h2>
<ul>
  <li><strong>Hisob ma'lumotlari:</strong> email, foydalanuvchi nomi va parol (shifrlangan holda saqlanadi), yoki Google orqali kirganda Google hisobingizdan email va ism.</li>
  <li><strong>Joylashuv:</strong> yaqin atrofdagi joylarni ko'rsatish va joylarga check-in qilish uchun GPS joylashuvingiz (faqat ilova ochiq bo'lganda, background emas).</li>
  <li><strong>Profil rasmi va joy rasmlari:</strong> agar siz yuklasangiz, xavfsiz bulutli saqlash xizmatida (Supabase Storage) saqlanadi.</li>
  <li><strong>Do'stlar va xabarlar:</strong> do'stlik so'rovlari, do'stlar ro'yxati va foydalanuvchilar orasidagi chat xabarlari.</li>
  <li><strong>Check-in tarixi:</strong> tashrif buyurgan joylar va vaqti.</li>
</ul>

<h2>Ma'lumotlardan qanday foydalanamiz</h2>
<p>Yig'ilgan ma'lumotlar faqat ilova funksiyalarini ta'minlash uchun ishlatiladi: hisobingizga kirish, yaqin joylarni topish, do'stlar bilan bog'lanish va xabar almashish. Ma'lumotlar uchinchi shaxslarga sotilmaydi.</p>

<h2>Uchinchi tomon xizmatlari</h2>
<ul>
  <li><strong>Google Sign-In</strong> — hisobga kirish uchun (ixtiyoriy).</li>
  <li><strong>Google Maps</strong> — xarita va joylarni ko'rsatish uchun.</li>
  <li><strong>Supabase Storage</strong> — yuklangan rasmlarni saqlash uchun.</li>
</ul>
<p>Bu xizmatlar o'zlarining maxfiylik siyosatiga ega bo'lishi mumkin.</p>

<h2>Ma'lumotlarni saqlash va o'chirish</h2>
<p>Ma'lumotlaringiz hisobingiz faol bo'lgan davomida saqlanadi. Hisobingizni va unga bog'liq barcha ma'lumotlarni o'chirishni so'rash uchun quyidagi email orqali murojaat qiling.</p>

<h2>Bolalar maxfiyligi</h2>
<p>Mikka 13 yoshdan kichik bolalar uchun mo'ljallanmagan va ulardan ongli ravishda ma'lumot yig'maydi.</p>

<h2>Aloqa</h2>
<p>Savollar yoki ma'lumotlarni o'chirish so'rovlari uchun: <a href="mailto:jbm050690@gmail.com">jbm050690@gmail.com</a></p>

<h2>O'zgarishlar</h2>
<p>Ushbu siyosat vaqti-vaqti bilan yangilanishi mumkin. Muhim o'zgarishlar haqida ilova orqali xabar beramiz.</p>
</body>
</html>`;
  }
}
