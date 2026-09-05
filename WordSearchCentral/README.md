# QuillGrid Notebook

Open this folder in Godot 4 and run `scenes/main.tscn`.

QuillGrid Notebook is a cozy letter-grid puzzle maker. Players paste or write their own story, generate puzzle chapters from those sentences, and unlock their notebook one level at a time.

The project keeps a native 800x480 logical layout while drawing through Godot's 2D renderer so resized windows stay crisp. UI icons are drawn procedurally in code, and feedback sounds are generated at runtime instead of relying on bundled third-party audio.

Controls:
- Drag from the first letter of a word to the last letter to submit it.
- Double-click a word start to preview/snap to the word end.
- `F11` toggles fullscreen.
- `C` opens the story editor.
- `M` opens the story manager.
- `S` opens the story-so-far reader.
- `Ctrl+V` pastes into the active editor field.
