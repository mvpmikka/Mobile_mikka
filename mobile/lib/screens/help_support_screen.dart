import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
      question: 'Qanday qilib do\'st qo\'sha olaman?',
      answer:
          'Qidiruv orqali foydalanuvchini toping va profilidan do\'stlik so\'rovi yuboring.',
    ),
    (
      question: 'Profil rasmim nega ko\'rinmayapti?',
      answer:
          'Google orqali kirgan bo\'lsangiz, hisobingizga qayta kirganda avtomatik o\'rnatiladi. '
          'Aks holda hozircha rasm qo\'lda yuklab bo\'lmaydi.',
    ),
    (
      question: 'Joyni qanday saqlab qo\'yaman?',
      answer:
          'Joy sahifasidagi yurak belgisini bosing — u "Saqlangan joylar" bo\'limida ko\'rinadi.',
    ),
    (
      question: 'Hisobimni qanday o\'chiraman?',
      answer: 'Profil > Hisobni o\'chirish orqali butunlay o\'chirishingiz mumkin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        title: Text(
          'Yordam va qo\'llab-quvvatlash',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.fieldBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faq.question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  faq.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
