# الهروب من القلعة — Castle Escape

لعبة ألغاز ومغامرات ثنائية الأبعاد لأجهزة iPhone، مبنية بـ Swift + SpriteKit + SwiftUI.
البطل مسجون في أعلى برج قلعة جبلية، وعليه النزول عشرة طوابق حتى البوابة الرئيسية — بذكائه فقط.

A 2D puzzle-adventure for iPhone (Swift, SpriteKit, SwiftUI). The hero is locked at the top of a
mountain castle and must solve his way down ten floors to the main gate.

---

## 1. المتطلبات / Requirements

| | |
|---|---|
| Xcode | 15.0 أو أحدث (String Catalogs تتطلب Xcode 15) |
| iOS | 17.0+ (iPhone فقط، الوضع العمودي) |
| حساب Apple Developer | مجاني يكفي للتشغيل على جهازك الشخصي |
| الإنترنت | غير مطلوب — اللعبة تعمل بالكامل دون اتصال |

لا توجد أي تبعيات خارجية (لا CocoaPods ولا SPM ولا SDK إعلانات).

## 2. التثبيت والتشغيل / Install & run

```bash
unzip CastleEscape.zip
cd CastleEscape
open CastleEscape.xcodeproj
```

1. في Xcode اختر الهدف **CastleEscape** ثم من *Signing & Capabilities* اختر فريقك (Team).
   غيّر `PRODUCT_BUNDLE_IDENTIFIER` (الحالي `agency.go360.castleescape`) إلى معرّف خاص بك.
2. اختر جهاز iPhone (أو محاكي iOS 17+) ثم **Run (⌘R)**.
3. لتشغيل الاختبارات: **Product → Test (⌘U)**.

### التشغيل على iPhone حقيقي / Running on a physical iPhone
1. وصّل الهاتف بالكابل، ووافق على *Trust This Computer*.
2. على الهاتف: *Settings → Privacy & Security → Developer Mode* → فعّله وأعد التشغيل (iOS 16+).
3. في Xcode اختر الهاتف من قائمة الأجهزة واضغط Run.
4. أول مرة فقط: على الهاتف *Settings → General → VPN & Device Management* → اضغط على اسم المطوّر → **Trust**.
5. مع حساب مجاني تنتهي صلاحية التوقيع بعد 7 أيام؛ أعد التشغيل من Xcode عند الحاجة.

### إعادة توليد ملف المشروع / Regenerating the project
ملف `CastleEscape.xcodeproj` مولَّد من `tools/generate_xcodeproj.py` (لا يحتاج أي مكتبة):

```bash
python3 tools/generate_xcodeproj.py      # بعد إضافة ملفات Swift جديدة
python3 tools/strings.py                 # بعد تعديل النصوص (يولّد .xcstrings + L10nKey.swift)
python3 tools/generate_assets.py         # يعيد توليد القوام والأيقونة (يحتاج Pillow)
```
يوجد أيضًا `project.yml` لمن يفضّل XcodeGen (`xcodegen generate`).

## 3. بنية المشروع / Project structure

```
CastleEscape/
├── App/            CastleEscapeApp (نقطة الدخول SwiftUI)
├── Game/           GameSession (آلة الحالات)، GameCoordinator، النماذج
├── Scenes/         CastleScene + الكاميرا السينمائية، الخارج (CastleNode…)، الداخل (FloorInteriorNode…)
├── Camera/         CameraDirector (تأطير القلعة/النافذة/الممر لكل مقاس شاشة)
├── Characters/     HeroNode، GuardNode (رسم إجرائي بالكامل + حركات)
├── PuzzleEngine/   المصنع، المدقّق، المولّدات (حساب، أنماط، ذاكرة، انتباه، منطق، سرعة، وقت)
├── PuzzleModels/   Puzzle، PuzzleChoice، PuzzleSymbol، LocalizedText
├── LevelSystem/    FloorCatalog (10 طوابق)، قواعد التقدّم، الإنجازات
├── Scoring/        ScoreKeeper + ScoreConfig (قابل للضبط من GameConfig.json)
├── Storage/        GameProgress/GameSettings + ProgressStore (JSON + UserDefaults)
├── Audio/          SoundSynthesizer (كل الأصوات مولَّدة رياضيًا) + AudioManager
├── Monetization/   AdManaging (بروتوكول) + MockAdManager
├── Localization/   Localizable.xcstrings، InfoPlist.xcstrings، LocalizationManager
├── UI/             القائمة، HUD، لوحة الألغاز، الإيقاف، الخسارة، الفوز، الإعدادات، الطوابق، الإنجازات
└── Resources/      Assets.xcassets (أيقونة + قوام مولَّد)، GameConfig.json
CastleEscapeTests/  اختبارات XCTest (توليد الألغاز، التحقق، التقدّم، النقاط، الحفظ)
tools/              سكربتات التوليد
```

### كيف تعمل الكاميرا السينمائية
القلعة الخارجية والطوابق الداخلية تعيش في **مشهد SpriteKit واحد وبنفس نظام الإحداثيات**
(`CastleLayout`). كل طابق يرتفع 520 وحدة، والنافذة الرئيسية لكل طابق تقع عند نفس الموضع
الذي تُرسم فيه نافذة الغرفة من الداخل. عند الضغط على "ابدأ" تطير `SKCameraNode` من
المنظر البعيد إلى النافذة، ويتلاشى الواجهة الخارجية ليظهر المقطع الجانبي للغرفة، ثم تتابع
الكاميرا الزوم حتى حجم اللعب — حركة واحدة متصلة دون تبديل مشاهد. عند إكمال الطابق يدخل
البطل الدرج، ثم تبتعد الكاميرا، تتحوّل نافذة الطابق إلى "مكتمل"، تتوهج نافذة الطابق التالي
وتغوص الكاميرا فيها.

## 4. الميزات المنفَّذة / Implemented features

- حلقة اللعب الكاملة: منظر القلعة → زوم سينمائي → برج السجن → حل الألغاز → الدرج → زوم للخارج → الطابق التالي → … → البوابة → مشهد الهروب مع شروق الشمس.
- 10 طوابق بثيمات مختلفة (الطابقان 10 و9 بتفاصيل كاملة، والبقية بديكورات مشتركة بألوان خاصة) وصعوبة متدرّجة.
- محرّك ألغاز معياري مع 7 مولّدات إجرائية (حساب، أنماط عددية، ذاكرة بصرية بتسلسل رموز، انتباه بصري "الرمز المختلف"، منطق — ترتيب/أيام/الباب الآمن/الفئات/العدّ، سرعة بديهة بمؤقّت، الوقت والترتيب)، كلها بإجابة واحدة صحيحة وبلا خيارات مكرّرة.
- إجابة صحيحة = صوت + تمييز الخيار + نقاط + البطل يتجاوز عقبة (قفزة فوق حفرة، فتح قفل، مسامير تنكمش، بندول، حاجز سحري، صناديق). إجابة خاطئة = صوت + اهتزاز اللوحة + اقتراب الحارس + محاولة أخرى.
- الخسارة عند وصول الحارس: "لقد أمسك بك الحارس!" مع حاول مجددًا / العودة للقلعة / فرصة إضافية (إعلان مُحاكى).
- نقاط: +100 (قابل للضبط)، مكافأة السرعة، كومبو ×2 عند 3 و×3 عند 5، درع حماية عند 10 متتالية.
- حفظ تلقائي (الطابق الحالي، الطوابق المكتملة بالنجوم، النقاط، العملات، الإنجازات، الإعدادات) يبقى بعد إغلاق التطبيق.
- واجهة عربية RTL افتراضيًا + إنجليزية، تبديل فوري من الإعدادات، والتعابير الرياضية تُعرض LTR دائمًا.
- صوت مولَّد بالكامل (موسيقى محيطية، خطوات، باب، صحيح/خطأ، حارس، فوز، خسارة، انتقال) مع تحكم منفصل بالموسيقى والمؤثرات.
- طبقة إعلانات مجرّدة (`AdManaging`) مع `MockAdManager` وواجهة إعلان مكافأة مُحاكاة، ووضع بلا إعلانات.
- شاشات: قائمة رئيسية متحركة، قصة افتتاحية، HUD، إيقاف مؤقت، الطوابق (إعادة لعب)، الإنجازات، الإعدادات، نهاية الطابق، الفوز.
- اختبارات وحدة لتوليد الألغاز والتحقق والنقاط والتقدّم والحفظ.

## 5. ما لم يُتحقَّق منه / What could not be verified

هذا المشروع كُتب في بيئة Linux **بدون Xcode أو محاكي iOS أو مترجم Swift**، لذلك:

- **لم يُنفَّذ البناء (build) ولا الاختبارات فعليًا.** تم التحقق من توازن الأقواس وبنية `project.pbxproj`
  (بمحلّل مستقل) ومن تطابق مفاتيح الترجمة، لكن من المتوقع ظهور بعض أخطاء الترجمة البسيطة عند أول
  بناء في Xcode (تسميات معاملات، تحويلات أنواع…). عادةً تُحلّ خلال دقائق.
- لم تُختبر الحركات والتوقيتات على شاشة حقيقية؛ قد تحتاج ثوابت `CastleLayout` و`CameraDirector`
  إلى ضبط بصري.
- لم يُقَس الأداء (الهدف 60 إطار/ث). الرسوم كلها `SKShapeNode`/sprites خفيفة، لكن إن ظهر بطء
  على أجهزة قديمة فقلّل عدد `TorchNode` مع `embers: true` أو عدد الغيوم.

## 6. التحسينات المتبقية / Remaining improvements

1. دمج Google AdMob: أنشئ `AdMobAdManager: AdManaging` واحقنه في `GameCoordinator` (معرّفات الوحدات الإعلانية غير موجودة عمدًا).
2. شراء داخلي حقيقي لوضع "بلا إعلانات" (حاليًا مفتاح محلي في الإعدادات).
3. ديكورات مخصّصة أغنى للطوابق 8→1 (حاليًا تشارك مجموعة الدعائم).
4. رسوم Sprite Sheet أصلية للشخصيات بدل الرسم الإجرائي إن رغبت بأسلوب مرسوم يدويًا.
5. تلميحات أكثر تنوّعًا (حاليًا 50/50 لألغاز الاختيار من متعدد فقط).
6. دعم iPad واتجاه أفقي، وGame Center للوحة المتصدرين.
7. موسيقى مؤلَّفة بدل الحلقة المولَّدة، وأصوات خطوات على أسطح مختلفة.
8. إضافة لغات أخرى: أضف حالة في `AppLanguage`، وعمودًا في `tools/strings.py`، ونسخة في كل `LocalizedText`.

## 7. GitHub Actions: البناء التلقائي و TestFlight

- **Build & Test** (`.github/workflows/ci.yml`): يعمل مع كل push على macOS، يبني للمحاكي ويشغّل الاختبارات. لا يحتاج أي أسرار.
- **TestFlight** (`.github/workflows/testflight.yml`): يُشغَّل يدويًا (Actions → TestFlight → Run workflow) أو عند دفع وسم `v*`.
  يؤرشف التطبيق بتوقيع تلقائي سحابي ويرفعه إلى App Store Connect. يحتاج الأسرار التالية في
  *Settings → Secrets and variables → Actions*:

  | السر | من أين |
  |---|---|
  | `APPLE_TEAM_ID` | developer.apple.com → Membership details → Team ID |
  | `ASC_KEY_ID` و `ASC_ISSUER_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Generate key (دور **Admin**) |
  | `ASC_PRIVATE_KEY` | محتوى ملف `AuthKey_XXXXXXXX.p8` الذي يُنزَّل مرة واحدة عند إنشاء المفتاح |

  الحالة الحالية: الأسرار مضبوطة، والمفتاح «CastleEscape GitHub» (Key ID `6728CM8CD7`) نشط، وسجل التطبيق موجود
  (App Store Connect app id 6826153004، مجموعة TestFlight الداخلية «Go360 Team» بتوزيع تلقائي).
  لرفع بناء جديد: Actions → TestFlight → Run workflow، أو `git tag v1.0.1 && git push --tags`.

  وقبل أول رفع: أنشئ سجل التطبيق في App Store Connect → My Apps → **+** بالـ Bundle ID `agency.go360.castleescape`
  (سجّل الـ App ID أولًا في developer.apple.com → Identifiers إن لم يظهر في القائمة).
