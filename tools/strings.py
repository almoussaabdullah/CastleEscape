#!/usr/bin/env python3
"""Single source of truth for UI strings.

Generates:
  CastleEscape/Localization/Localizable.xcstrings   (Xcode String Catalog)
  CastleEscape/Localization/InfoPlist.xcstrings     (localized display name)
  CastleEscape/Localization/L10nKey.swift           (type-safe keys)

Run from the repository root:  python3 tools/strings.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOC = os.path.join(ROOT, "CastleEscape", "Localization")

# key: (arabic, english)
STRINGS = {
    # App / menu
    "app.title": ("الهروب من القلعة", "Castle Escape"),
    "app.subtitle": ("CASTLE ESCAPE", "الهروب من القلعة"),
    "menu.play": ("ابدأ المغامرة", "Play"),
    "menu.continue": ("متابعة", "Continue"),
    "menu.newGame": ("مغامرة جديدة", "New Adventure"),
    "menu.levels": ("الطوابق", "Levels"),
    "menu.settings": ("الإعدادات", "Settings"),
    "menu.achievements": ("الإنجازات", "Achievements"),
    "menu.tagline": ("ذكاؤك هو سلاحك الوحيد", "Your mind is your only weapon"),
    "menu.progress": ("الطابق %d من %d", "Floor %d of %d"),
    "menu.escaped": ("هربت من القلعة %d مرة", "Escaped the castle %d times"),
    "menu.newGameConfirmTitle": ("بدء مغامرة جديدة؟", "Start a new adventure?"),
    "menu.newGameConfirmMessage": ("سيعود البطل إلى برج السجن وتُمسح طوابقك المكتملة. تبقى نقاطك وإنجازاتك.", "The hero returns to the prison tower and completed floors are cleared. Your score and achievements stay."),

    # Story intro
    "story.line1": ("في ليلة عاصفة، اختطف حراس القلعة مغامرًا شابًا...", "On a stormy night, the castle guards kidnapped a young adventurer..."),
    "story.line2": ("وسجنوه في أعلى برج من القلعة الغامضة فوق الجبال.", "They locked him in the highest tower of a mysterious mountain castle."),
    "story.line3": ("لا سيف ولا درع... ذكاؤه فقط هو ما سيُنزله عشرة طوابق نحو الحرية.", "No sword, no shield... only his wits can carry him down ten floors to freedom."),
    "story.begin": ("لنبدأ الهروب", "Begin the escape"),
    "story.skip": ("تخطّ", "Skip"),

    # HUD
    "hud.floor": ("الطابق %d", "Floor %d"),
    "hud.score": ("النقاط", "Score"),
    "hud.combo": ("كومبو ×%d", "Combo ×%d"),
    "hud.shield": ("درع", "Shield"),
    "hud.encounter": ("%d / %d", "%d / %d"),

    # Puzzle panel
    "puzzle.hint": ("تلميح", "Hint"),
    "puzzle.hintCost": ("%d عملة", "%d coins"),
    "puzzle.hintAd": ("شاهد إعلانًا", "Watch an ad"),
    "puzzle.memorize": ("احفظ الترتيب!", "Memorize the order!"),
    "puzzle.yourTurn": ("دورك! أعد الترتيب", "Your turn! Repeat the order"),
    "puzzle.correct": ("أحسنت!", "Correct!"),
    "puzzle.wrong": ("ليس صحيحًا!", "Not quite!"),
    "puzzle.timeout": ("انتهى الوقت!", "Time's up!"),
    "puzzle.fastBonus": ("سريع! +%d", "Fast! +%d"),
    "puzzle.points": ("+%d", "+%d"),
    "puzzle.shieldSaved": ("الدرع حماك من الخطأ!", "Your shield absorbed the mistake!"),
    "puzzle.shieldEarned": ("حصلت على درع الحماية!", "You earned a protective shield!"),
    "puzzle.comboTier": ("كومبو ×%d!", "Combo ×%d!"),
    "puzzle.guardCloser": ("الحارس يقترب!", "The guard is getting closer!"),
    "puzzle.progress": ("اللغز %d من %d", "Puzzle %d of %d"),
    "puzzle.selected": ("%d من %d", "%d of %d"),

    # Transitions
    "transition.descending": ("نزول إلى الطابق %d", "Descending to floor %d"),
    "transition.floorCleared": ("تم اجتياز الطابق!", "Floor cleared!"),
    "transition.enteringFloor": ("الطابق %d", "Floor %d"),
    "transition.stars": ("%d نجوم", "%d stars"),
    "transition.coins": ("+%d عملة", "+%d coins"),
    "transition.doubleCoins": ("ضاعف العملات", "Double coins"),
    "transition.continue": ("تابع النزول", "Keep descending"),
    "transition.backToCastle": ("العودة للقلعة", "Back to the castle"),

    # Pause
    "pause.title": ("إيقاف مؤقت", "Paused"),
    "pause.resume": ("استئناف", "Resume"),
    "pause.restart": ("إعادة الطابق", "Restart floor"),
    "pause.quit": ("العودة للقلعة", "Back to the castle"),

    # Game over
    "gameover.title": ("لقد أمسك بك الحارس!", "The guard caught you!"),
    "gameover.subtitle": ("لا بأس… كل محاولة تجعل عقلك أقوى", "No worries… every attempt makes your mind sharper"),
    "gameover.retry": ("حاول مجددًا", "Try again"),
    "gameover.castle": ("العودة للقلعة", "Back to the castle"),
    "gameover.extra": ("فرصة إضافية", "Extra chance"),
    "gameover.extraHint": ("شاهد إعلانًا قصيرًا لتدفع الحارس بعيدًا وتكمل من حيث توقفت", "Watch a short ad to push the guard back and continue where you stopped"),

    # Victory
    "victory.title": ("لقد نجحت في الهروب!", "You escaped!"),
    "victory.subtitle": ("الشمس تشرق فوق الجبال… أنت حرّ", "The sun rises over the mountains… you are free"),
    "victory.score": ("مجموع النقاط", "Total score"),
    "victory.puzzles": ("الألغاز المحلولة", "Puzzles solved"),
    "victory.accuracy": ("الدقة", "Accuracy"),
    "victory.time": ("الوقت الكلي", "Total time"),
    "victory.stars": ("النجوم", "Stars"),
    "victory.replay": ("العب مجددًا", "Play again"),
    "victory.menu": ("القائمة الرئيسية", "Main menu"),

    # Settings
    "settings.title": ("الإعدادات", "Settings"),
    "settings.language": ("اللغة", "Language"),
    "settings.language.ar": ("العربية", "Arabic"),
    "settings.language.en": ("الإنجليزية", "English"),
    "settings.audio": ("الصوت", "Audio"),
    "settings.music": ("الموسيقى", "Music"),
    "settings.sfx": ("المؤثرات الصوتية", "Sound effects"),
    "settings.haptics": ("الاهتزاز", "Haptics"),
    "settings.reducedMotion": ("تقليل الحركة", "Reduce motion"),
    "settings.premium": ("وضع بلا إعلانات", "Ad-free mode"),
    "settings.premiumHint": ("نسخة تجريبية: يُفعَّل محليًا دون شراء", "Preview build: toggled locally without a purchase"),
    "settings.reset": ("إعادة ضبط التقدم", "Reset progress"),
    "settings.resetTitle": ("إعادة ضبط كل شيء؟", "Reset everything?"),
    "settings.resetMessage": ("سيتم حذف التقدم والنقاط والإنجازات نهائيًا.", "Progress, score and achievements will be permanently deleted."),
    "settings.version": ("الإصدار %@", "Version %@"),
    "settings.about": ("لعبة ألغاز مغامرات ثنائية الأبعاد — كل الرسومات والأصوات أصلية ومولّدة برمجيًا.", "A 2D puzzle adventure — all artwork and audio are original and procedurally generated."),

    # Levels
    "levels.title": ("طوابق القلعة", "Castle Floors"),
    "levels.locked": ("مقفل", "Locked"),
    "levels.current": ("الطابق الحالي", "Current floor"),
    "levels.completed": ("مكتمل", "Completed"),
    "levels.replay": ("إعادة اللعب", "Replay"),
    "levels.play": ("العب", "Play"),
    "levels.puzzles": ("%d ألغاز", "%d puzzles"),
    "levels.bestScore": ("أفضل نتيجة: %d", "Best score: %d"),

    # Achievements
    "achievements.title": ("الإنجازات", "Achievements"),
    "achievements.unlocked": ("%d من %d", "%d of %d"),
    "achievements.locked": ("مقفل", "Locked"),
    "achievements.toast": ("إنجاز جديد: %@", "Achievement unlocked: %@"),

    # Ads (simulated)
    "ad.title": ("إعلان تجريبي", "Simulated ad"),
    "ad.body": ("في النسخة النهائية سيظهر هنا إعلان مكافأة حقيقي.", "A real rewarded ad will appear here in the release build."),
    "ad.countdown": ("المكافأة خلال %d ثانية", "Reward in %d seconds"),
    "ad.claim": ("استلم المكافأة", "Claim reward"),
    "ad.close": ("إغلاق", "Close"),

    # Common
    "common.ok": ("حسنًا", "OK"),
    "common.cancel": ("إلغاء", "Cancel"),
    "common.confirm": ("تأكيد", "Confirm"),
    "common.back": ("رجوع", "Back"),
    "common.close": ("إغلاق", "Close"),
    "common.coins": ("العملات", "Coins"),
    "common.stars": ("النجوم", "Stars"),
}


def camel(key: str) -> str:
    parts = re.split(r"[.\-_]", key)
    head, *tail = parts
    return head + "".join(p[:1].upper() + p[1:] for p in tail)


def write_catalog(path, entries, source="en"):
    strings = {}
    for key, (ar, en) in entries.items():
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                "ar": {"stringUnit": {"state": "translated", "value": ar}},
                "en": {"stringUnit": {"state": "translated", "value": en}},
            },
        }
    catalog = {"sourceLanguage": source, "strings": strings, "version": "1.0"}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2, sort_keys=True)
    print("wrote", path)


def write_swift(path):
    lines = ["// Generated by tools/strings.py — do not edit by hand.", "import Foundation", "",
             "/// Type-safe keys for every string in Localizable.xcstrings.",
             "enum L10nKey: String, CaseIterable {"]
    for key in STRINGS:
        lines.append(f"    case {camel(key)} = \"{key}\"")
    lines.append("}")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote", path)


def main():
    os.makedirs(LOC, exist_ok=True)
    write_catalog(os.path.join(LOC, "Localizable.xcstrings"), STRINGS)
    write_catalog(os.path.join(LOC, "InfoPlist.xcstrings"), {
        "CFBundleDisplayName": ("الهروب من القلعة", "Castle Escape"),
        "CFBundleName": ("الهروب من القلعة", "Castle Escape"),
    })
    write_swift(os.path.join(LOC, "L10nKey.swift"))
    # sanity: keys must map to unique camelCase identifiers
    names = [camel(k) for k in STRINGS]
    assert len(names) == len(set(names)), "duplicate camelCase key"


if __name__ == "__main__":
    main()
