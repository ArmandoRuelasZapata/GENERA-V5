---
description: Pre-push checklist — run all CI checks locally before pushing to GitHub
---

# Pre-Push Checklist

The CI pipeline (`.github/workflows/flutter_ci.yml`) runs **3 checks** on every push to `main` or `develop`. All 3 must pass or the push will be rejected. Run them locally **in this exact order** before pushing.

---

## Step 1: Format Code
// turbo
```bash
dart format .
```
- Formats **all** `.dart` files using the official Dart formatter.
- CI runs `dart format --output=none --set-exit-if-changed .` — if even one file has wrong formatting, it **fails**.
- **Common pitfall**: New or edited files that weren't saved with auto-format on.

---

## Step 2: Analyze Code (Zero Warnings)
// turbo
```bash
flutter analyze --no-fatal-infos --fatal-warnings
```
- `info`-level issues are **allowed** (deprecation notices, prefer_const, etc.).
- `warning`-level issues **fail the build** (unused imports, unused variables, unused parameters).
- **Common pitfalls**:
  - Unused imports left behind after refactoring.
  - Unused variables or parameters (e.g., `_` not used for ignored params).
  - Missing `const` on constructors (only flagged as `info`, but good to fix).

---

## Step 3: Run All Tests
// turbo
```bash
flutter test
```
- Runs **every** test in `test/` recursively.
- **All tests must pass** — even 1 failure blocks the push.
- **Common pitfalls**:
  - Changing a widget's constructor or type breaks tests that use `find.byType()`.
  - Adding Firebase/platform calls in `initState` makes widgets untestable in unit tests.
  - Infinite/repeating animations cause `pumpAndSettle` to timeout — use `pump(duration)` instead.
  - `Future.delayed` in widgets leaves "Timer is still pending" errors in tests.

---

## Quick One-Liner (Run All 3)
// turbo
```bash
dart format . && flutter analyze --no-fatal-infos --fatal-warnings && flutter test
```

If this command completes with exit code 0, you're safe to push.

---

## Push to GitHub
```bash
git add -A && git commit -m "feat: description" && git push origin main
```

---

## Why Each Check Matters

| Check | What it catches | Severity |
|-------|----------------|----------|
| `dart format` | Inconsistent formatting, wrong indentation | **Fatal** |
| `flutter analyze --fatal-warnings` | Unused imports, unused variables, type errors | **Fatal** (warnings only) |
| `flutter test` | Broken functionality, widget tree changes, regressions | **Fatal** |

## Test-Writing Rules (To Avoid Failures)

1. **Never instantiate widgets that call Firebase in `initState`** in unit tests — Firebase requires a real platform. Use integration tests for those.
2. **Don't use `pumpAndSettle`** if the widget tree contains infinitely repeating animations (e.g., `AppAnimatedBackground`). Use `pump(Duration)` instead.
3. **After changing a widget's structure**, check if any test uses `find.byType(WidgetName)` for that widget.
4. **After removing or renaming imports**, run `flutter analyze` to catch orphaned references.
