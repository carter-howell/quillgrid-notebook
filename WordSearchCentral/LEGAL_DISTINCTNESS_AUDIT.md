# Legal Distinctness Audit

This is a practical project checklist, not legal advice.

## Current Product Identity

- Title: QuillGrid Notebook
- Core hook: Players turn their own writing into letter-grid notebook levels.
- Default content: No bundled story is included in the base build.
- Story mode identity: Story Manager, Story Editor, and Notebook.

## Deliberate Differences

- Does not use the title, subtitle, character, story, publisher, developer, or franchise wording of the reference game.
- Does not include a fixed animal-character adventure as the shipped story.
- Does not load copied soundtrack files, sound-effect files, toolbar icons, or UI atlases.
- Uses procedural toolbar icons drawn in GDScript.
- Uses procedural runtime tones and short generated melodies instead of bundled extracted audio.
- Emphasizes custom story generation, adjustable word counts, dynamic word selection, and local story management.

## Avoid Reintroducing

- Do not use `WordSearch Story`, `Samuel's Adventure`, `Follow The Fun`, source-game character names, or source-game story text in app metadata, code, screenshots, descriptions, or marketing.
- Do not restore extracted `.ogg` files, source-game icons, source-game atlases, animation dumps, screenshots, or copied UI art into the active Godot project.
- Do not describe the app as revealing a hidden story from remaining letters.
- Do not market it as a clone, remake, port, sequel, compatible title, or spiritual successor.

## Before Public Release

- Run a text search for source-game names and phrases.
- Confirm `assets/` only contains original or licensed assets.
- Confirm the export preset does not include archived extracted files.
- Use original screenshots from the current build only.
- Run a trademark clearance search for `QuillGrid Notebook`.
- Have an attorney review the name and store listing if this becomes a commercial release.
