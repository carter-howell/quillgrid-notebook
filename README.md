# QuillGrid Notebook

Status: Android game submitted to Google Play production review

I built QuillGrid Notebook as a small Android word-search game around story-generated letter-grid levels. Players write or paste a story, turn sentences into playable puzzle chapters, and unlock the notebook one completed level at a time.

The project combined game design, Godot UI work, Android export setup, Play Store release preparation, local data handling, and visual asset creation into one finished mobile-app workflow.

## What I Built

- I built a Godot 4 Android game with a custom 2D puzzle interface.
- I implemented story-to-level generation for letter-grid gameplay.
- I prepared an Android App Bundle for Google Play.
- I created store listing copy, screenshots, app icon, feature graphic, and privacy policy.
- I completed Play Console app-content declarations and submitted the first production release for review.

## Gameplay

Players find selected words from each sentence on a letter grid. Solving a level reveals the sentence, gradually building a readable notebook from the player's own writing.

Core features:

- Story editor for pasted or original text.
- Story manager for local story collections.
- Generated puzzle chapters from sentence text.
- Drag-based word selection.
- Completion screen that reveals the solved sentence.
- Local-only progress and settings.
- No account, ads, analytics, cloud sync, or server upload.

## Release Status

- App name: `QuillGrid Notebook`
- Package name: `com.carterhowell.quillgridnotebook`
- Platform: Android
- Engine: Godot 4
- Price: Free
- First production release: `1 (1.0.0)`
- Google Play status: production release submitted; changes are in review

The public Play Store listing may not be visible until Google review and publishing propagation finish.

## Public Pages

- Project page: https://carter-howell.github.io/quillgrid-notebook/
- Privacy policy: https://carter-howell.github.io/quillgrid-notebook/privacy-policy.html

I keep the privacy policy in `docs/privacy-policy.html` because that URL is used for the Google Play listing.

## Media

I keep store-ready visual assets under `media/`.

### App Icon

![QuillGrid Notebook app icon](media/app-icon-512.png)

### Feature Graphic

![QuillGrid Notebook feature graphic](media/feature-graphic.png)

### Screenshots

![QuillGrid Notebook puzzle board screenshot](media/phone-01-board.png)

![QuillGrid Notebook story editor screenshot](media/phone-02-editor.png)

![QuillGrid Notebook story manager screenshot](media/phone-03-manager.png)

![QuillGrid Notebook completed level screenshot](media/phone-04-complete.png)

## Build Notes

I built the game in Godot 4 and structured it around a notebook-style progression loop: edit a story, generate playable word-search chapters, solve each grid, and reveal the original sentence after completion. I also kept the app local-first, so stories and progress stay on the device without requiring accounts, ads, analytics, or a backend service.

The release work included Android package configuration, app signing/export steps, store screenshots, icon and feature graphics, Play Console declarations, and a privacy-policy page for the listing.
