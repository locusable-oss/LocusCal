# LocusCal — unsigned local build & acceptance

**Product name:** LocusCal  
**License:** GPL-3.0 (Locusable Studio)  
**Host:** macOS + Xcode 15+ (this Linux agent cannot run `xcodebuild`).

## Build (unsigned)

```bash
cd /path/to/LocusCal
brew install xcodegen   # once
make generate
make build
# or: make open → Run in Xcode (Debug)
```

`LSUIElement=YES` — menu bar only, no Dock icon. First EventKit use may prompt Calendar/Reminders permission.

## Feature checklist (work items 2–13)

2. Scaffold / run target — `project.yml` + `LocusCal` app sources + Core  
3. Menu bar popover shows Gregorian month  
4. Today highlight + prev/next month + 今天  
5–7. Holiday JSON 2025–2027; 休/班 marks; missing year degrades  
8. Lunar labels toggle  
9. Settings: lunar, week start, login item  
10. Menu bar title date + 休/班  
11. Minimal visual polish (material, spacing, today ring)  
12. MVP unsigned path documented here  
13. Optional EventKit read-only section (toggle + permission degrade)

## Yearly holiday updates

Add `LocusCal/Resources/holidays-YYYY.json` with `{ "year", "source?", "days": { "YYYY-MM-DD": "rest"|"work" } }`. Rebuild. Missing files → caption warning, no crash.

## Out of scope

Notarization, signed releases, multi-platform, GitHub Actions (added only at final publish).
