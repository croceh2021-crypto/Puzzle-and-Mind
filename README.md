# لغز وذكاء – PUZZLE & MIND

لعبة Android عربية تجمع بين الألغاز الذهنية واكتشاف الاختلافات بين صورتين. المشروع مبني باستخدام Godot 4.4.1 وCompatibility Renderer.

## الحالة الحالية
هذا المستودع يحتوي على نموذج أولي مبكر، وليس إصداراً نهائياً:
- واجهة رئيسية عربية عمودية.
- عالمان منفصلان: الألغاز الذهنية واكتشاف الاختلافات.
- ثلاثة ألغاز تجريبية محفوظة في JSON.
- عالم اختلافات يستخدم صورتين فعليتين من ملفات المستودع في أول مرحلتين، مع ثلاثة اختلافات مرسومة وقت التشغيل ومناطق لمس مطابقة.
- حفظ محلي أولي للعملات والنجوم وتقدم كل عالم.

## المتطلبات
- Godot 4.4.1.
- Android export templates وAndroid SDK/Java عند إعداد تصدير APK.

## فتح المشروع
افتح مجلد المستودع في Godot 4.4.1، ثم شغّل المشهد الرئيسي `Main.tscn`.

## الفحص الآلي
يوجد Workflow في `.github/workflows/godot-check.yml` لفحص استيراد المشروع وتشغيل المشهد دون واجهة رسومية عند كل push أو pull request إلى main.

## ما لم ينجز بعد
- لم يتم بعد اختبار تشغيل Godot فعلياً في بيئة التطوير التي أنشأت النموذج.
- تم بناء Android Debug APK بنجاح عبر GitHub Actions والتحقق من سلامة ملف APK؛ لم يُختبر التثبيت على هاتف فعلي بعد.
- تم إعداد `export_presets.cfg` وتفعيل استيراد ETC2/ASTC اللازم لتصدير Android.
- أول مرحلتين من عالم الاختلافات تستخدمان صوراً من المستودع؛ بقية المراحل ومحتوى 300 مرحلة لم تُنتج بعد.

راجع `DEVELOPMENT_LOG.md` و`TEST_REPORT_2026-11-25.md` و`DESIGN_DECISIONS.md` لمعرفة القرارات والاختبارات وحدود النموذج.

## Android debug build
The repository now includes an Android export preset and a GitHub Actions workflow at `.github/workflows/android-debug.yml`. It attempts to build a signed debug APK using a temporary CI-only debug key and uploads the APK as a 14-day workflow artifact. This is a test build, not a Play Store release. Check the workflow run and its artifact before installing.
