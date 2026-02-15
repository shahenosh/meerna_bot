# استخدام نسخة Dart الرسمية (خفيفة وبدون فلاتر)
FROM dart:stable

# تحديد مكان العمل داخل السيرفر
WORKDIR /app

# نسخ كل ملفات المشروع للسيرفر
COPY . .

# تحميل المكتبات (http, html, xmpp_stone)
RUN dart pub get

# تشغيل البوت مباشرة من ملف ميرنا
CMD ["dart", "run", "bin/merna.dart"]
