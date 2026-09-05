# QuillGrid Notebook

Status: Active Android game / Google Play publishing project

QuillGrid Notebook is a small Godot word-search game built around story-based levels. Players can paste or write a story, turn the sentences into playable letter-grid levels, and reveal the story one level at a time.

## Overview

The project was built as a legally distinct letter-grid puzzle game with a cozy notebook-style interface. It keeps the gameplay focused on finding selected words from each sentence, then rewards the player by revealing the completed level text.

## Features

- Story manager for creating named stories.
- Level generation from pasted story text.
- Dynamic word selection that favors stronger words and avoids short filler words.
- Drag-based word search controls.
- Completion screen that reveals the level sentence.
- Local progress, story, font, color, and audio settings.
- Android App Bundle export for Google Play.
- Windows executable export for desktop testing.

## Implementation

The game is implemented in Godot 4 with GDScript. The current build uses procedural UI drawing, runtime-generated interface sounds, and a fixed 800x480 logical layout so the same scene can be exported to Windows and Android.

Main project folder:

- [WordSearchCentral](WordSearchCentral)

Important files:

- [WordSearchCentral/scripts/main.gd](WordSearchCentral/scripts/main.gd)
- [WordSearchCentral/scenes/main.tscn](WordSearchCentral/scenes/main.tscn)
- [WordSearchCentral/project.godot](WordSearchCentral/project.godot)

## Controls

- Drag from the first letter of a word to the last letter to submit it.
- Double-click a word start to preview or snap toward the word end.
- `F11` toggles fullscreen on desktop.
- `C` opens the story editor.
- `M` opens the story manager.
- `S` opens the story-so-far reader.
- `Ctrl+V` pastes into the active editor field.

## Privacy

QuillGrid Notebook does not collect, share, or transmit player data. Stories and progress are stored locally on the player's device.

Privacy policy: [QuillGrid Notebook Privacy Policy](https://carter-howell.github.io/quillgrid-notebook/privacy-policy.html)

## Status Notes

This project is kept as a small software/game archive and publishing exercise. It demonstrates Godot export work, Android package setup, Google Play release preparation, and a simple content-generation workflow, but it should sit below embedded, PCB, robotics, and power-electronics projects in an electrical-engineering-focused portfolio.
