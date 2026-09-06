# QuillGrid Notebook

Status: Android game submitted to Google Play production review

I built QuillGrid Notebook as a small Android word-search game around story-generated letter-grid levels. Players write or paste a story, turn sentences into playable puzzle chapters, and unlock the notebook one completed level at a time.

I keep this repository as a public project exhibit rather than a full source-code release. It documents the app concept, release preparation, store materials, and privacy policy while keeping the active Godot project and signing/build workflow local.

## What It Demonstrates

- I built a Godot 4 Android game with a custom 2D puzzle interface.
- I implemented story-to-level generation for letter-grid gameplay.
- I prepared an Android App Bundle for Google Play.
- I created store listing copy, screenshots, app icon, feature graphic, and privacy policy.
- I completed Play Console app-content declarations and submitted the first production release for review.
- I kept the public repository legally distinct from any reference material or extracted assets.

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

## Source Availability

I intentionally do not publish the active Godot source in this repository. The public repo is an exhibit and release record, not an installable development checkout.

This keeps the GitHub page focused on the finished project, avoids exposing local publishing credentials or build artifacts, and lets the game code continue to evolve privately while the app is reviewed on Google Play.

## Portfolio Note

I treat this as a supporting software/game project. It demonstrates product completion, Android publishing, local-data privacy, and polished release preparation, but I keep it below embedded systems, PCB design, robotics, and power-electronics work in my electrical-engineering-focused portfolio.
