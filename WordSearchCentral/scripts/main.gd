extends Control

const LOGICAL_SIZE := Vector2(800, 480)
const SAVE_PATH := "user://save.json"
const SAVE_BACKUP_PATH := "user://save.backup.json"
const SAVE_TMP_PATH := "user://save.tmp.json"
const DEFAULT_LEVELS_PATH := "res://data/default_levels.json"
const TOOLBAR_Y := 39.0
const MAX_PICKED_WORD_LENGTH := 8
const MIN_WORDS_PER_LEVEL := 4
const MAX_WORDS_PER_LEVEL := 10
const DEFAULT_WORDS_PER_LEVEL := 8
const WORD_COOLDOWN_LEVELS := 3
const STORY_SETTINGS_VERSION := 2
const FONT_CHOICES := [
	{"name": "Rounded", "names": ["Arial Rounded MT Bold", "Arial"], "bold": true},
	{"name": "Storybook", "names": ["Georgia", "Cambria"], "bold": true},
	{"name": "Friendly", "names": ["Trebuchet MS", "Verdana"], "bold": true},
	{"name": "Modern", "names": ["Century Gothic", "Segoe UI"], "bold": true},
	{"name": "Soft", "names": ["Candara", "Calibri"], "bold": false},
	{"name": "Handmade", "names": ["Comic Sans MS", "Segoe Print"], "bold": true},
	{"name": "Novel", "names": ["Times New Roman", "Georgia"], "bold": false},
	{"name": "Poster", "names": ["Impact", "Arial Black"], "bold": false},
	{"name": "Clean", "names": ["Segoe UI", "Arial"], "bold": true},
	{"name": "Classic", "names": ["Verdana", "Tahoma"], "bold": true},
]

const PALETTES := [
	{
		"name": "Dawn Brown",
		"bg": Color8(64, 43, 40),
		"letter": Color8(255, 166, 97),
		"word": Color8(180, 84, 72),
		"found": Color8(75, 47, 43),
		"highlight": Color8(188, 95, 83, 185),
		"hint": Color8(255, 212, 114, 160),
	},
	{
		"name": "Forest Mist",
		"bg": Color8(35, 58, 52),
		"letter": Color8(246, 187, 105),
		"word": Color8(142, 198, 150),
		"found": Color8(48, 86, 75),
		"highlight": Color8(106, 174, 128, 185),
		"hint": Color8(255, 222, 132, 165),
	},
	{
		"name": "Inkberry",
		"bg": Color8(40, 36, 58),
		"letter": Color8(248, 167, 111),
		"word": Color8(183, 127, 181),
		"found": Color8(60, 51, 76),
		"highlight": Color8(164, 103, 160, 185),
		"hint": Color8(255, 215, 125, 165),
	},
]

const STOP_WORDS := {
	"the": true, "and": true, "was": true, "were": true, "with": true,
	"that": true, "this": true, "from": true, "into": true, "onto": true,
	"there": true, "their": true, "then": true, "than": true, "they": true,
	"his": true, "her": true, "she": true, "him": true, "for": true,
	"but": true, "not": true, "you": true, "your": true, "had": true,
	"has": true, "have": true, "are": true, "our": true, "out": true,
	"about": true, "after": true, "again": true, "against": true, "all": true,
	"also": true, "any": true, "because": true, "been": true, "before": true,
	"being": true, "between": true, "both": true, "can": true, "could": true,
	"did": true, "does": true, "down": true, "each": true, "few": true,
	"first": true, "get": true, "got": true, "how": true, "its": true,
	"just": true, "like": true, "made": true, "make": true, "many": true,
	"more": true, "most": true, "much": true, "now": true, "off": true,
	"only": true, "over": true, "said": true, "same": true, "see": true,
	"some": true, "such": true, "too": true, "under": true, "very": true,
	"what": true, "when": true, "where": true, "which": true, "while": true,
	"who": true, "will": true, "would": true,
}

const BAD_WORDS := {"ass": true, "damn": true, "hell": true, "sex": true}

var default_levels: Array = []
var levels: Array = []
var state := {}
var active_story_index := -1
var current_level_index := 0
var mode := "preload"
var found_effects: Array = []
var sparkles: Array = []
var selection_start = null
var selection_current = null
var selection_started_at := 0.0
var last_drag_cell = null
var last_click_time := 0.0
var last_click_cell = null
var hint_word := ""
var hint_until := 0.0
var level_elapsed_seconds := 0.0
var reveal_t := 0.0
var complete_t := 0.0
var toolbar_rects := {}
var font: Font
var audio := {}
var music_player: AudioStreamPlayer
var music_tracks: Array = []
var music_track_index := 0
var sfx_players: Array[AudioStreamPlayer] = []
var story_manager_index := 0
var creator_name := ""
var creator_text := ""
var creator_focus := "name"
var creator_edit_index = null
var creator_message := "Paste a story, then click Save Story."
var creator_story_scroll := 0
var creator_name_caret := 0
var creator_text_caret := 0
var creator_select_all := ""
var creator_selection_anchor := -1
var creator_selection_focus := ""
var creator_mouse_selecting := false
var story_view_scroll := 0
var story_body_scroll := 0
var preload_until := 0.0
var mouse_logical_pos := Vector2(-10000, -10000)
var pressed_toolbar_key := ""
var pressed_toolbar_at := 0.0
var button_click_effects: Array = []


func _ready() -> void:
	set_process(true)
	set_process_input(true)
	get_window().title = "QuillGrid Notebook"
	get_window().min_size = Vector2i(800, 480)
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(800, 480)
	font = get_theme_default_font()
	load_audio()
	load_default_levels()
	state = load_save()
	migrate_stories()
	apply_font_choice()
	active_story_index = clampi(int(state.get("active_story", -1)), -1, state.get("stories", []).size() - 1)
	rebuild_levels()
	current_level_index = clampi(int(state.get("level", 0)), 0, maxi(0, levels.size() - 1))
	reset_level_timer()
	play_music()
	preload_until = Time.get_ticks_msec() / 1000.0 + 0.85
	queue_redraw()


func _process(delta: float) -> void:
	if mode == "preload" and Time.get_ticks_msec() / 1000.0 >= preload_until:
		mode = "play" if has_playable_level() else "manager"
	if mode == "play" and has_playable_level():
		level_elapsed_seconds += delta
	update_mouse_cursor()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), palette().bg)
	match mode:
		"preload":
			draw_preload()
		"complete":
			draw_complete_transition()
		"reveal":
			draw_reveal()
		"story":
			draw_story_view()
		"manager":
			draw_story_manager()
		"creator":
			draw_creator()
		_:
			draw_play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


func canvas_rect() -> Rect2:
	var scale: float = min(size.x / LOGICAL_SIZE.x, size.y / LOGICAL_SIZE.y)
	var out_size: Vector2 = LOGICAL_SIZE * scale
	return Rect2((size - out_size) * 0.5, out_size)


func to_logical(pos: Vector2) -> Vector2:
	var rect := canvas_rect()
	if not rect.has_point(pos):
		return Vector2(-10000, -10000)
	return (pos - rect.position) / (rect.size.x / LOGICAL_SIZE.x)


func render_scale() -> float:
	return canvas_rect().size.x / LOGICAL_SIZE.x


func logical_pos(pos: Vector2) -> Vector2:
	var rect := canvas_rect()
	return rect.position + pos * render_scale()


func logical_rect(rect: Rect2) -> Rect2:
	var scale := render_scale()
	return Rect2(logical_pos(rect.position), rect.size * scale)


func logical_size(value: float) -> float:
	return value * render_scale()


func draw_solid_rect(rect: Rect2, color: Color) -> void:
	draw_rect(logical_rect(rect), color)


func draw_outline_rect(rect: Rect2, color: Color, width: float = 1.0) -> void:
	draw_rect(logical_rect(rect), color, false, logical_size(width))


func touch_rect(r: Rect2, min_size := Vector2(44, 44)) -> Rect2:
	var extra := Vector2(maxf(0.0, min_size.x - r.size.x), maxf(0.0, min_size.y - r.size.y))
	return Rect2(r.position - extra * 0.5, r.size + extra)


func load_default_levels() -> void:
	var text := FileAccess.get_file_as_string(DEFAULT_LEVELS_PATH)
	var parsed = JSON.parse_string(text)
	default_levels = parsed if parsed is Array else []


func load_save() -> Dictionary:
	var loaded := load_save_file(SAVE_PATH)
	if not loaded.is_empty():
		return loaded
	loaded = load_save_file(SAVE_BACKUP_PATH)
	if not loaded.is_empty():
		return loaded
	return {
		"level": 0,
		"palette": 0,
		"volume": true,
		"progress": {},
		"stories": [],
		"custom_levels": [],
		"active_story": -1,
	}


func load_save_file(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	return {}


func save_state() -> void:
	var text := JSON.stringify(state, "\t")
	var file := FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(SAVE_BACKUP_PATH))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_TMP_PATH), ProjectSettings.globalize_path(SAVE_PATH))


func migrate_stories() -> void:
	var stories = state.get("stories", [])
	if not (stories is Array):
		stories = []
	var clean := []
	for story in stories:
		if story is Dictionary and story.get("levels", []).size() > 0:
			clean.append({
				"name": str(story.get("name", "Untitled Story")).substr(0, 60),
				"text": str(story.get("text", "")),
				"levels": story.get("levels", []),
				"words_per_level": clampi(int(story.get("words_per_level", DEFAULT_WORDS_PER_LEVEL)), MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL),
				"dynamic_words": bool(story.get("dynamic_words", true)),
				"levels_dirty": bool(story.get("levels_dirty", false)),
				"settings_version": int(story.get("settings_version", 1)),
			})
	var old_levels = state.get("custom_levels", [])
	if clean.is_empty() and old_levels is Array and not old_levels.is_empty():
		clean.append({"name": "My Story", "text": "", "levels": old_levels, "words_per_level": DEFAULT_WORDS_PER_LEVEL, "dynamic_words": true, "levels_dirty": false, "settings_version": STORY_SETTINGS_VERSION})
	state["stories"] = clean


func rebuild_levels() -> void:
	var stories: Array = state.get("stories", [])
	if active_story_index < 0 or active_story_index >= stories.size():
		active_story_index = -1
		levels = default_levels.duplicate(true)
	else:
		ensure_custom_story_levels(active_story_index)
		levels = stories[active_story_index].get("levels", []).duplicate(true)
		if levels.is_empty():
			active_story_index = -1
			levels = default_levels.duplicate(true)
	state["active_story"] = active_story_index
	current_level_index = clampi(int(state.get("level", 0)), 0, max(0, levels.size() - 1))
	state["level"] = current_level_index


func has_playable_level() -> bool:
	return not levels.is_empty() and current_level_index >= 0 and current_level_index < levels.size()


func reset_level_timer() -> void:
	level_elapsed_seconds = 0.0


func palette() -> Dictionary:
	return PALETTES[int(state.get("palette", 0)) % PALETTES.size()]


func level() -> Dictionary:
	if not has_playable_level():
		return {}
	return levels[current_level_index]


func progress_key() -> String:
	if not has_playable_level():
		return ""
	return str(level().name)


func found_words() -> Array:
	if not has_playable_level():
		return []
	var progress: Dictionary = state.get("progress", {})
	state["progress"] = progress
	if not progress.has(progress_key()):
		progress[progress_key()] = []
	return progress[progress_key()]


func mark_found(word: String) -> void:
	var found := found_words()
	if not found.has(word):
		found.append(word)
		state["progress"][progress_key()] = found
		save_state()


func board_geometry() -> Dictionary:
	var size_value := int(level().size)
	if size_value == 10:
		return {"left": 70.0, "top": 100.0, "cell": 30.0}
	return {"left": 70.0, "top": 96.0, "cell": 27.0}


func cell_center(x: int, y: int) -> Vector2:
	var g := board_geometry()
	var c := float(g.cell)
	return Vector2(float(g.left) + x * c + c * 0.5, float(g.top) + y * c + c * 0.5)


func cell_at(pos: Vector2):
	var g := board_geometry()
	var c := float(g.cell)
	var x := int(floor((pos.x - float(g.left)) / c))
	var y := int(floor((pos.y - float(g.top)) / c))
	if x >= 0 and y >= 0 and x < int(level().size) and y < int(level().size):
		return Vector2i(x, y)
	return null


func word_cells(word: Dictionary) -> Array:
	var text := str(word.text)
	var length := text.length()
	var step_x := 0
	var step_y := 0
	if length > 1:
		step_x = 0 if int(word.dx) == 0 else int(int(word.dx) / (length - 1))
		step_y = 0 if int(word.dy) == 0 else int(int(word.dy) / (length - 1))
	var cells := []
	for i in range(length):
		cells.append(Vector2i(int(word.x) + step_x * i, int(word.y) + step_y * i))
	return cells


func selection_cells() -> Array:
	if selection_start == null or selection_current == null:
		return []
	var sx: int = selection_start.x
	var sy: int = selection_start.y
	var ex: int = selection_current.x
	var ey: int = selection_current.y
	var dx: int = ex - sx
	var dy: int = ey - sy
	var steps: int = maxi(abs(dx), abs(dy))
	if steps == 0:
		return [selection_start]
	if dx != 0 and dy != 0 and abs(dx) != abs(dy):
		return []
	var step_x: int = 0 if dx == 0 else int(dx / abs(dx))
	var step_y: int = 0 if dy == 0 else int(dy / abs(dy))
	var cells := []
	for i in range(steps + 1):
		cells.append(Vector2i(sx + step_x * i, sy + step_y * i))
	return cells


func word_for_cells(cells: Array):
	for word in level().words:
		var wcells := word_cells(word)
		var rev := wcells.duplicate()
		rev.reverse()
		if cells == wcells or cells == rev:
			return word
	return null


func word_starting_at(cell: Vector2i):
	for word in level().words:
		if not found_words().has(str(word.text)) and word_cells(word)[0] == cell:
			return word
	return null


func all_found() -> bool:
	return found_words().size() >= level().words.size()


func draw_text_line(text: String, pos: Vector2, size_px: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var scaled_size := maxi(1, int(round(size_px * render_scale())))
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled_size).x
	var screen_pos := logical_pos(pos)
	var x := screen_pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= width
	draw_string(font, Vector2(x, screen_pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled_size, color)


func apply_font_choice() -> void:
	var choice: Dictionary = FONT_CHOICES[int(state.get("font", 0)) % FONT_CHOICES.size()]
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray(choice.names)
	sys_font.font_weight = 700 if bool(choice.bold) else 400
	font = sys_font


func draw_rotated_text(text: String, center: Vector2, size_px: int, color: Color, angle_deg: float) -> void:
	var scaled_size := maxi(1, int(round(size_px * render_scale())))
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled_size)
	draw_set_transform(logical_pos(center), deg_to_rad(angle_deg), Vector2.ONE)
	draw_string(font, Vector2(-text_size.x * 0.5, scaled_size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, scaled_size, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_play(trigger_complete := true) -> void:
	if not has_playable_level():
		draw_empty_play_state()
		return
	var pal := palette()
	toolbar_rects.clear()
	draw_toolbar()
	var found := found_words()
	var g := board_geometry()
	draw_play_status(g)
	draw_board_surface(g)
	draw_word_tray(found)
	draw_notebook_tabs(g)
	for i in range(level().words.size()):
		var word = level().words[i]
		var col: Color = pal.word.lerp(pal.bg, 0.55) if found.has(str(word.text)) else pal.word
		for item in found_effects:
			if str(item.word) == str(word.text):
				var age := Time.get_ticks_msec() / 1000.0 - float(item.t)
				if age < 0.65:
					col = pal.letter.lerp(col, ease_out_cubic(age / 0.65))
				break
		draw_word_tray_entry(str(word.text), i, col, found.has(str(word.text)))
	for word in level().words:
		if found.has(str(word.text)):
			var found_age := 999.0
			for item in found_effects:
				if str(item.word) == str(word.text):
					found_age = Time.get_ticks_msec() / 1000.0 - float(item.t)
					break
			draw_word_highlight(word_cells(word), pal.highlight, "found", found_age)
	if hint_word != "" and Time.get_ticks_msec() / 1000.0 < hint_until:
		for word in level().words:
			if str(word.text) == hint_word:
				draw_word_highlight(word_cells(word), pal.hint, "hint", 0.0)
	var active := selection_cells()
	draw_board_hover_feedback(active)
	if not active.is_empty():
		draw_active_selection(active)
	draw_found_effects()
	draw_drag_sparkles()
	draw_board_letters(active)
	if trigger_complete and all_found():
		mode = "complete"
		complete_t = 0.0
		play_sfx("win")


func draw_play_status(g: Dictionary) -> void:
	var pal := palette()
	var elapsed := level_elapsed_seconds
	var timer := "%02d:%05.2f" % [int(elapsed / 60.0), fmod(elapsed, 60.0)]
	var ink: Color = pal.word.lerp(pal.bg, 0.15)
	ink.a = 0.8
	draw_text_line("Level %d" % int(level().number), Vector2(float(g.left), 66), 19, pal.letter)
	draw_text_line(timer, Vector2(float(g.left) + 154, 66), 18, ink)
	var solved := found_words().size()
	draw_text_line("%d/%d words" % [solved, level().words.size()], Vector2(410, 66), 15, ink, HORIZONTAL_ALIGNMENT_RIGHT)


func draw_word_tray(found: Array) -> void:
	var pal := palette()
	var tray := Rect2(430, 94, 296, 315)
	var paper: Color = pal.bg.lerp(pal.letter, 0.1)
	paper.a = 0.34
	draw_solid_rect(tray, paper)
	var edge: Color = pal.word
	edge.a = 0.3
	draw_outline_rect(tray, edge, 2)
	draw_text_line("Word Tray", Vector2(tray.position.x + 22, tray.position.y + 35), 18, pal.letter)
	var note: Color = pal.word
	note.a = 0.72
	draw_text_line("Find these story words", Vector2(tray.position.x + 22, tray.position.y + 57), 11, note)


func draw_word_tray_entry(word: String, index: int, col: Color, is_found: bool) -> void:
	var row := index % 10
	var tray_x := 452.0
	var y := 171.0 + row * 22.5
	var bg: Color = palette().bg.lerp(palette().word, 0.18 if is_found else 0.1)
	bg.a = 0.42 if is_found else 0.18
	draw_solid_rect(Rect2(tray_x - 10, y - 17, 226, 20), bg)
	draw_text_line(word, Vector2(tray_x, y), 19, col)
	if is_found:
		var line_col: Color = col
		line_col.a = 0.5
		draw_line(logical_pos(Vector2(tray_x, y - 7)), logical_pos(Vector2(tray_x + minf(200.0, word.length() * 13.0), y - 7)), line_col, logical_size(2.0))


func draw_notebook_tabs(g: Dictionary) -> void:
	var pal := palette()
	var board_size := float(g.cell) * int(level().size)
	var tab_col: Color = pal.word
	tab_col.a = 0.22
	draw_solid_rect(Rect2(float(g.left) + 20, float(g.top) - 20, 84, 18), tab_col)
	draw_solid_rect(Rect2(float(g.left) + board_size - 112, float(g.top) - 20, 92, 18), tab_col)


func draw_empty_play_state() -> void:
	var pal := palette()
	toolbar_rects.clear()
	draw_text_line("QuillGrid Notebook", Vector2(400, 148), 32, pal.letter, HORIZONTAL_ALIGNMENT_CENTER)
	draw_text_line("Build letter-grid chapters from your own writing.", Vector2(400, 195), 15, pal.word, HORIZONTAL_ALIGNMENT_CENTER)
	button("Story Manager", Rect2(284, 236, 232, 44), "manager")
	button("New Story", Rect2(306, 296, 188, 42), "story_new")


func draw_preload() -> void:
	var pal := palette()
	var pulse := 0.78 + 0.22 * sin(Time.get_ticks_msec() / 180.0)
	var col: Color = pal.letter
	col.a = pulse
	var center := Vector2(400, 210)
	draw_storybook_mark(center, col, 1.0 + 0.035 * sin(Time.get_ticks_msec() / 210.0))
	draw_text_line("QuillGrid Notebook", Vector2(400, 292), 30, pal.letter, HORIZONTAL_ALIGNMENT_CENTER)
	var loading_col: Color = pal.word
	loading_col.a = 0.75
	draw_text_line("Preparing your puzzle desk...", Vector2(400, 326), 14, loading_col, HORIZONTAL_ALIGNMENT_CENTER)


func draw_toolbar() -> void:
	var pal := palette()
	var names := ["sound", "hint", "font", "palette", "story"]
	var xs := [486.0, 542.0, 598.0, 654.0, 710.0]
	for i in range(names.size()):
		var name: String = names[i]
		var center := Vector2(xs[i], TOOLBAR_Y)
		toolbar_rects[name] = Rect2(center - Vector2(22, 22), Vector2(44, 44))
		var hovered: bool = toolbar_rects[name].has_point(mouse_logical_pos)
		var col: Color = pal.letter.lerp(Color.WHITE, 0.18) if hovered else pal.letter
		if hovered:
			var ring_col: Color = pal.word
			ring_col.a = 0.28 + 0.08 * sin(Time.get_ticks_msec() / 120.0)
			draw_circle(logical_pos(center), logical_size(23), ring_col)
		draw_icon(name, center, col, 1.08 if hovered else 1.0)


func draw_icon(name: String, center: Vector2, color: Color, scale_amount := 1.0) -> void:
	var s := scale_amount
	if name == "font":
		draw_text_line("Aa", center + Vector2(0, 9 * s), int(24 * s), color, HORIZONTAL_ALIGNMENT_CENTER)
	elif name == "hint":
		draw_lightbulb_icon(center, color, s)
	elif name == "story":
		draw_storybook_mark(center, color, 0.38 * s)
	elif name == "palette":
		draw_palette_icon(center, color, s)
	elif name == "sound":
		draw_sound_icon(center, color, s, bool(state.get("volume", true)))
	else:
		draw_circle(logical_pos(center), logical_size(12 * s), color)


func draw_storybook_mark(center: Vector2, color: Color, scale_amount := 1.0) -> void:
	var w := 86.0 * scale_amount
	var h := 62.0 * scale_amount
	var spine := 5.0 * scale_amount
	var left := Rect2(center - Vector2(w * 0.5, h * 0.5), Vector2(w * 0.5 - spine, h))
	var right := Rect2(Vector2(center.x + spine, center.y - h * 0.5), Vector2(w * 0.5 - spine, h))
	var page_col := color
	page_col.a *= 0.82
	draw_solid_rect(left, page_col)
	draw_solid_rect(right, page_col)
	var edge_col := color
	edge_col.a *= 0.42
	draw_outline_rect(left, edge_col, 2.0 * scale_amount)
	draw_outline_rect(right, edge_col, 2.0 * scale_amount)
	draw_line(logical_pos(Vector2(center.x, center.y - h * 0.47)), logical_pos(Vector2(center.x, center.y + h * 0.47)), edge_col, logical_size(2.0 * scale_amount))
	for i in range(3):
		var yy := center.y - h * 0.25 + i * h * 0.22
		draw_line(logical_pos(Vector2(left.position.x + w * 0.1, yy)), logical_pos(Vector2(left.end.x - w * 0.08, yy)), edge_col, logical_size(1.2 * scale_amount))
		draw_line(logical_pos(Vector2(right.position.x + w * 0.08, yy)), logical_pos(Vector2(right.end.x - w * 0.1, yy)), edge_col, logical_size(1.2 * scale_amount))


func draw_lightbulb_icon(center: Vector2, color: Color, scale_amount := 1.0) -> void:
	draw_circle(logical_pos(center + Vector2(0, -5) * scale_amount), logical_size(9 * scale_amount), color)
	draw_solid_rect(Rect2(center + Vector2(-6, 5) * scale_amount, Vector2(12, 8) * scale_amount), color)
	draw_line(logical_pos(center + Vector2(-7, 17) * scale_amount), logical_pos(center + Vector2(7, 17) * scale_amount), color, logical_size(2.0 * scale_amount))


func draw_palette_icon(center: Vector2, color: Color, scale_amount := 1.0) -> void:
	draw_circle(logical_pos(center), logical_size(15 * scale_amount), color)
	var cut_col: Color = palette().bg
	draw_circle(logical_pos(center + Vector2(6, 4) * scale_amount), logical_size(5 * scale_amount), cut_col)
	for p in [Vector2(-5, -5), Vector2(3, -8), Vector2(-8, 4)]:
		draw_circle(logical_pos(center + p * scale_amount), logical_size(2.2 * scale_amount), cut_col)


func draw_sound_icon(center: Vector2, color: Color, scale_amount: float, enabled: bool) -> void:
	var points := [
		logical_pos(center + Vector2(-14, -7) * scale_amount),
		logical_pos(center + Vector2(-7, -7) * scale_amount),
		logical_pos(center + Vector2(4, -16) * scale_amount),
		logical_pos(center + Vector2(4, 16) * scale_amount),
		logical_pos(center + Vector2(-7, 7) * scale_amount),
		logical_pos(center + Vector2(-14, 7) * scale_amount),
	]
	draw_polygon(points, [color])
	if enabled:
		draw_arc(logical_pos(center + Vector2(4, 0) * scale_amount), logical_size(10 * scale_amount), -0.7, 0.7, 14, color, logical_size(2.0 * scale_amount))
		draw_arc(logical_pos(center + Vector2(4, 0) * scale_amount), logical_size(17 * scale_amount), -0.62, 0.62, 14, color, logical_size(2.0 * scale_amount))
	else:
		draw_line(logical_pos(center + Vector2(12, -12) * scale_amount), logical_pos(center + Vector2(25, 12) * scale_amount), color, logical_size(3.0 * scale_amount))
		draw_line(logical_pos(center + Vector2(25, -12) * scale_amount), logical_pos(center + Vector2(12, 12) * scale_amount), color, logical_size(3.0 * scale_amount))


func draw_pill(cells: Array, color: Color, width_scale: float) -> void:
	draw_pill_progress(cells, color, width_scale, 1.0)


func draw_pill_progress(cells: Array, color: Color, width_scale: float, progress: float) -> void:
	if cells.is_empty():
		return
	progress = clampf(progress, 0.0, 1.0)
	var g := board_geometry()
	var c := float(g.cell)
	if cells.size() == 1:
		draw_circle(logical_pos(cell_center(cells[0].x, cells[0].y)), logical_size(c * 0.42 * progress), color)
		return
	var start := cell_center(cells[0].x, cells[0].y)
	var full_end := cell_center(cells[-1].x, cells[-1].y)
	var end := start.lerp(full_end, progress)
	draw_line(logical_pos(start), logical_pos(end), color, logical_size(c * width_scale))
	draw_circle(logical_pos(start), logical_size(c * width_scale * 0.5), color)
	draw_circle(logical_pos(end), logical_size(c * width_scale * 0.5), color)


func draw_board_surface(g: Dictionary) -> void:
	var pal := palette()
	var size_value := int(level().size)
	var c := float(g.cell)
	var board_rect := Rect2(float(g.left) - c * 0.18, float(g.top) - c * 0.18, c * size_value + c * 0.36, c * size_value + c * 0.36)
	var wash: Color = pal.bg.lerp(pal.letter, 0.045)
	wash.a = 0.32
	draw_solid_rect(board_rect, wash)
	var edge: Color = pal.word
	edge.a = 0.18
	draw_outline_rect(board_rect, edge, 2.0)
	var tick_col: Color = pal.word
	tick_col.a = 0.055
	for i in range(size_value + 1):
		var x := float(g.left) + float(i) * c
		var y := float(g.top) + float(i) * c
		draw_line(logical_pos(Vector2(x, float(g.top))), logical_pos(Vector2(x, float(g.top) + c * size_value)), tick_col, logical_size(1.0))
		draw_line(logical_pos(Vector2(float(g.left), y)), logical_pos(Vector2(float(g.left) + c * size_value, y)), tick_col, logical_size(1.0))


func draw_word_highlight(cells: Array, color: Color, style: String, age: float) -> void:
	if cells.is_empty():
		return
	var g := board_geometry()
	var c := float(g.cell)
	var intro := 1.0 if age > 1.0 else ease_out_back(clampf(age / 0.22, 0.0, 1.0))
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 135.0)
	var start := cell_center(cells[0].x, cells[0].y)
	var end := cell_center(cells[-1].x, cells[-1].y)
	var dir := (end - start).normalized()
	var normal := Vector2(-dir.y, dir.x)
	if cells.size() == 1:
		dir = Vector2.RIGHT
		normal = Vector2.UP
	end = start.lerp(end, intro)
	var shadow: Color = palette().bg
	shadow.a = 0.22 if style == "active" else 0.14
	draw_line(logical_pos(start + normal * 3.0), logical_pos(end + normal * 3.0), shadow, logical_size(c * (0.38 if style == "found" else 0.46)))
	var ribbon: Color = color
	ribbon.a = 0.54 if style == "found" else 0.46 if style == "hint" else 0.66
	draw_line(logical_pos(start), logical_pos(end), ribbon, logical_size(c * (0.34 if style == "found" else 0.42)))
	draw_circle(logical_pos(start), logical_size(c * (0.17 if style == "found" else 0.21)), ribbon)
	draw_circle(logical_pos(end), logical_size(c * (0.17 if style == "found" else 0.21)), ribbon)
	var glint: Color = palette().letter
	glint.a = (0.16 + 0.09 * pulse) if style != "found" else 0.10
	draw_line(logical_pos(start - normal * 4.0), logical_pos(end - normal * 4.0), glint, logical_size(c * 0.07))


func draw_board_hover_feedback(active_cells: Array) -> void:
	var hover = cell_at(mouse_logical_pos)
	var pal := palette()
	var now := Time.get_ticks_msec() / 1000.0
	if active_cells.is_empty():
		return
	var cell_size := float(board_geometry().cell)
	for i in range(active_cells.size()):
		var cell: Vector2i = active_cells[i]
		var p := float(i + 1) / float(active_cells.size())
		var col: Color = pal.letter
		col.a = 0.08 + p * 0.08 + 0.03 * sin(now * 10.0 + float(i))
		var center := cell_center(cell.x, cell.y)
		draw_line(logical_pos(center + Vector2(-cell_size * 0.22, cell_size * 0.34)), logical_pos(center + Vector2(cell_size * 0.22, cell_size * 0.34)), col, logical_size(2.0))


func draw_active_selection(cells: Array) -> void:
	var pal := palette()
	var age := Time.get_ticks_msec() / 1000.0 - selection_started_at
	var intro := ease_out_back(min(1.0, age / 0.22))
	var breathe := 0.5 + 0.5 * sin(age * 13.0)
	var shadow: Color = pal.bg
	shadow.a = 0.18
	draw_word_highlight(cells, shadow, "active", age)
	var base: Color = pal.hint.lerp(pal.letter, 0.16 * breathe)
	draw_word_highlight(cells, base, "active", age)
	var end_cell: Vector2i = cells[-1]
	var radius := float(board_geometry().cell) * (0.22 + 0.06 * breathe) * intro
	var pulse_col: Color = pal.letter
	pulse_col.a = 0.24
	draw_outline_rect(Rect2(cell_center(end_cell.x, end_cell.y) - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), pulse_col, 2.0)


func draw_board_letters(active_cells: Array) -> void:
	var pal := palette()
	var hover = cell_at(mouse_logical_pos)
	var found_cells := all_found_cells()
	var now := Time.get_ticks_msec() / 1000.0
	for y in range(level().letters.size()):
		var row: Array = level().letters[y]
		for x in range(row.size()):
			var cell := Vector2i(x, y)
			var pos := cell_center(x, y) + Vector2(0, 12)
			var col: Color = pal.letter
			var size_px := 31
			var lift := 0.0
			if hover != null and hover == cell and selection_start == null:
				lift = 5.0 + 1.0 * sin(now * 11.0)
				size_px = 34
				col = pal.letter.lerp(Color.WHITE, 0.28)
				var shadow_col: Color = pal.bg
				shadow_col.a = 0.28
				draw_text_line(str(row[x]).to_lower(), pos + Vector2(0, 4), 34, shadow_col, HORIZONTAL_ALIGNMENT_CENTER)
			if cell_in_array(active_cells, cell):
				lift = maxf(lift, 3.0)
				size_px = 33
				col = pal.letter.lerp(Color.WHITE, 0.18)
			elif cell_in_array(found_cells, cell):
				col = pal.letter.lerp(pal.bg, 0.14)
			draw_text_line(str(row[x]).to_lower(), pos + Vector2(0, -lift), size_px, col, HORIZONTAL_ALIGNMENT_CENTER)


func all_found_cells() -> Array:
	var out := []
	var found := found_words()
	for word in level().words:
		if found.has(str(word.text)):
			for cell in word_cells(word):
				if not cell_in_array(out, cell):
					out.append(cell)
	return out


func cell_in_array(cells: Array, target: Vector2i) -> bool:
	for cell in cells:
		if cell == target:
			return true
	return false


func draw_found_effects() -> void:
	var keep := []
	var now := Time.get_ticks_msec() / 1000.0
	for item in found_effects:
		var age := now - float(item.t)
		if age <= 1.15:
			keep.append(item)
			var grow := ease_out_cubic(min(1.0, age / 0.22))
			var col: Color = palette().letter
			col.a = 0.42 * (1.0 - age / 1.15)
			draw_word_highlight(item.cells, col, "active", age)
			for cell in item.cells:
				var c: Vector2i = cell
				var flash_col: Color = palette().letter
				flash_col.a = 0.18 * (1.0 - age / 1.15)
				draw_text_line(str(level().letters[c.y][c.x]).to_lower(), cell_center(c.x, c.y) + Vector2(0, 10 - 8 * grow), 35, flash_col, HORIZONTAL_ALIGNMENT_CENTER)
	found_effects = keep


func draw_drag_sparkles() -> void:
	var keep := []
	var now := Time.get_ticks_msec() / 1000.0
	for item in sparkles:
		var life := float(item.get("life", 0.38))
		var age := now - float(item.t)
		if age <= life:
			keep.append(item)
			var p := ease_out_cubic(age / life)
			var col: Color = item.get("color", palette().letter)
			col.a = float(item.get("alpha", 0.34)) * (1.0 - p)
			var pos: Vector2 = item.pos + item.get("velocity", Vector2.ZERO) * age
			var radius := float(item.get("radius", 8.0))
			draw_circle(logical_pos(pos), logical_size(radius * (1.0 - p)), col)
			draw_line(logical_pos(pos + Vector2(-radius, 0) * p), logical_pos(pos + Vector2(radius, 0) * p), col, logical_size(1.4))
			draw_line(logical_pos(pos + Vector2(0, -radius) * p), logical_pos(pos + Vector2(0, radius) * p), col, logical_size(1.4))
	sparkles = keep


func add_cell_burst(cell: Vector2i, strong := false) -> void:
	var center := cell_center(cell.x, cell.y)
	var pal := palette()
	var now := Time.get_ticks_msec() / 1000.0
	var count := 10 if strong else 5
	for i in range(count):
		var angle := TAU * float(i) / float(count) + (0.18 if strong else 0.0)
		var speed := 58.0 if strong else 28.0
		var col: Color = pal.letter if i % 2 == 0 else pal.hint
		sparkles.append({
			"pos": center,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"t": now,
			"life": 0.55 if strong else 0.34,
			"radius": 6.5 if strong else 4.8,
			"alpha": 0.5 if strong else 0.3,
			"color": col,
		})


func add_word_burst(cells: Array) -> void:
	for cell in cells:
		add_cell_burst(cell, true)


func update_mouse_cursor() -> void:
	var shape := Input.CURSOR_ARROW
	if mode == "creator" and (Rect2(50, 94, 700, 42).has_point(mouse_logical_pos) or Rect2(50, 153, 700, 220).has_point(mouse_logical_pos)):
		shape = Input.CURSOR_IBEAM
	elif toolbar_key_at(mouse_logical_pos) != "" or (mode == "play" and cell_at(mouse_logical_pos) != null):
		shape = Input.CURSOR_POINTING_HAND
	Input.set_default_cursor_shape(shape)


func ease_out_cubic(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


func ease_out_back(t: float) -> float:
	t = clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + t * t * (2.7 * t + 1.7)


func draw_complete_transition() -> void:
	complete_t += get_process_delta_time()
	draw_play(false)
	var pal := palette()
	var fade_col: Color = pal.bg
	fade_col.a = clampf(complete_t / 0.86, 0.0, 0.82)
	draw_solid_rect(Rect2(0, 0, LOGICAL_SIZE.x, LOGICAL_SIZE.y), fade_col)
	var stamp_t := ease_out_back(clampf((complete_t - 0.18) / 0.42, 0.0, 1.0))
	var stamp_col: Color = pal.letter
	stamp_col.a = clampf((complete_t - 0.08) / 0.35, 0.0, 0.82)
	var stamp_center := Vector2(400, 230)
	draw_circle(logical_pos(stamp_center), logical_size(54.0 * stamp_t), stamp_col)
	var inner: Color = pal.bg
	inner.a = stamp_col.a
	draw_circle(logical_pos(stamp_center), logical_size(42.0 * stamp_t), inner)
	draw_text_line("SAVED", stamp_center + Vector2(0, 7), int(19 * stamp_t), stamp_col, HORIZONTAL_ALIGNMENT_CENTER)
	if complete_t >= 0.94:
		mode = "reveal"
		reveal_t = 0.0


func draw_reveal() -> void:
	reveal_t += get_process_delta_time()
	var pal := palette()
	var reveal_text_t := maxf(0.0, reveal_t - 0.42)
	var shown := str(level().story)
	var lines := wrap_lines(shown, 520, 27)
	var text_alpha := clampf(reveal_text_t / 0.62, 0.0, 1.0)
	var page_ready := ease_out_back(clampf(reveal_t / 0.64, 0.0, 1.0))
	var extra_lines := maxi(0, lines.size() - 1)
	var page_extra := minf(96.0, float(extra_lines) * 42.0)
	var page_height := 244.0 + page_extra
	var page_top := 116.0 - page_extra * 0.42
	var page_rect := Rect2(128, page_top + (1.0 - page_ready) * 46.0, 544, page_height)
	var shadow_col: Color = pal.bg
	shadow_col.a = 0.28
	draw_solid_rect(Rect2(page_rect.position + Vector2(9, 10), page_rect.size), shadow_col)
	var paper_col: Color = pal.letter.lerp(Color.WHITE, 0.18)
	paper_col.a = 0.9
	draw_solid_rect(page_rect, paper_col)
	var margin_col: Color = pal.word
	margin_col.a = 0.34
	draw_line(logical_pos(Vector2(page_rect.position.x + 62, page_rect.position.y + 28)), logical_pos(Vector2(page_rect.position.x + 62, page_rect.end.y - 26)), margin_col, logical_size(2.0))
	for i in range(5):
		var yy := page_rect.position.y + 70 + i * 36
		if yy < page_rect.end.y - 34:
			var rule: Color = pal.bg
			rule.a = 0.12
			draw_line(logical_pos(Vector2(page_rect.position.x + 88, yy)), logical_pos(Vector2(page_rect.end.x - 34, yy)), rule, logical_size(1.0))
	var title_col: Color = pal.word
	title_col.a = 0.86 * text_alpha
	draw_text_line("Notebook Entry", Vector2(page_rect.position.x + 88, page_rect.position.y + 42), 18, title_col)
	draw_text_line("Level %d" % int(level().number), Vector2(page_rect.end.x - 40, page_rect.position.y + 42), 12, title_col, HORIZONTAL_ALIGNMENT_RIGHT)
	var col: Color = pal.bg
	col.a = text_alpha
	var lift := (1.0 - ease_out_cubic(text_alpha)) * 12.0
	var line_gap := 39.0
	var y := page_rect.position.y + 104.0
	for line in lines:
		draw_text_line(line, Vector2(page_rect.position.x + 94, y + lift), 27, col)
		y += line_gap
	var arrow_ready := clampf((reveal_t - 1.15) / 0.45, 0.0, 1.0)
	var arrow_col: Color = pal.word
	arrow_col.a = arrow_ready
	var bounce := sin(Time.get_ticks_msec() / 210.0) * 5.0
	var ax := page_rect.end.x - 108.0 + bounce
	var ay := minf(426.0, page_rect.end.y + 16.0)
	draw_solid_rect(Rect2(ax, ay, 50, 16), arrow_col)
	draw_polygon([logical_pos(Vector2(ax + 50, ay - 18)), logical_pos(Vector2(ax + 50, ay + 34)), logical_pos(Vector2(ax + 82, ay + 8))], [arrow_col])


func draw_story_view() -> void:
	var pal := palette()
	toolbar_rects.clear()
	draw_text_line("%s:" % current_story_name(), Vector2(70, 64), 18, pal.word)
	draw_text_line("Notebook:", Vector2(400, 64), 18, pal.letter, HORIZONTAL_ALIGNMENT_CENTER)
	var solved := []
	for lvl in levels:
		var progress: Array = state.get("progress", {}).get(str(lvl.name), [])
		if progress.size() >= lvl.words.size():
			solved.append(str(lvl.story))
	var max_level_rows := 12
	var max_level_scroll := maxi(0, levels.size() - max_level_rows)
	story_view_scroll = clampi(story_view_scroll, 0, max_level_scroll)
	for row in range(min(max_level_rows, levels.size())):
		var i := row + story_view_scroll
		var col: Color = pal.word if i < solved.size() else pal.word.lerp(pal.bg, 0.65)
		draw_text_line("Level %d:" % (i + 1), Vector2(78, 110 + row * 21), 12, col)
	if levels.size() > max_level_rows:
		var scroll_note := "%d-%d of %d" % [story_view_scroll + 1, min(story_view_scroll + max_level_rows, levels.size()), levels.size()]
		draw_text_line(scroll_note, Vector2(78, 376), 12, pal.word.lerp(pal.bg, 0.25))
	var body := ""
	if solved.is_empty():
		body = "Finish levels to add entries to this notebook."
	else:
		for part in solved:
			body += str(part) + " "
		body = body.strip_edges()
	var body_lines := wrap_lines(body, 390, 14)
	var max_body_lines := 9
	story_body_scroll = clampi(story_body_scroll, 0, maxi(0, body_lines.size() - max_body_lines))
	var y := 145.0
	for i in range(story_body_scroll, min(story_body_scroll + max_body_lines, body_lines.size())):
		var line: String = body_lines[i]
		draw_text_line(line, Vector2(430, y), 14, pal.letter, HORIZONTAL_ALIGNMENT_CENTER)
		y += 28
	button("Back", Rect2(70, 402, 110, 42), "back")
	button("Story Manager", Rect2(520, 402, 210, 42), "manager")


func draw_story_manager() -> void:
	var pal := palette()
	toolbar_rects.clear()
	draw_text_line("Story Manager", Vector2(48, 56), 29, pal.letter)
	draw_text_line("Make puzzle sets from your writing and choose what to play.", Vector2(51, 84), 12, pal.letter)
	var list_rect := Rect2(48, 102, 438, 282)
	var detail_rect := Rect2(508, 102, 244, 282)
	draw_solid_rect(list_rect, pal.bg.lerp(Color.WHITE, 0.05))
	draw_outline_rect(list_rect, pal.word.lerp(pal.bg, 0.2), 2)
	draw_solid_rect(detail_rect, pal.bg.lerp(Color.WHITE, 0.05))
	draw_outline_rect(detail_rect, pal.word.lerp(pal.bg, 0.2), 2)
	var rows := story_manager_rows()
	story_manager_index = clampi(story_manager_index, 0, maxi(0, rows.size() - 1))
	for i in range(min(8, rows.size())):
		var y := 126.0 + i * 31.0
		var r := Rect2(62, y - 19, 410, 28)
		toolbar_rects["story_select_%d" % i] = touch_rect(r)
		var selected := i == story_manager_index
		if selected:
			draw_solid_rect(r, palette().word.lerp(palette().bg, 0.22))
		var col: Color = pal.letter if selected else pal.word
		draw_text_line(str(rows[i].name).substr(0, 31), Vector2(74, y), 15, col)
		draw_text_line("%d levels" % int(rows[i].count), Vector2(454, y - 1), 12, col, HORIZONTAL_ALIGNMENT_RIGHT)
	if rows.is_empty():
		draw_text_line("No stories yet", Vector2(526, 132), 18, pal.letter)
		draw_text_line("Paste a story to build levels.", Vector2(526, 160), 12, pal.word)
		button("New", Rect2(526, 202, 206, 36), "story_new")
		button("Back", Rect2(56, 398, 110, 42), "back")
		return
	var selected_row = rows[story_manager_index]
	draw_text_line(str(selected_row.name).substr(0, 22), Vector2(526, 129), 17, pal.letter)
	draw_text_line("%d sentence levels" % int(selected_row.count), Vector2(526, 157), 13, pal.word)
	draw_text_line("Custom story", Vector2(526, 180), 12, pal.letter)
	button("Play", Rect2(526, 202, 95, 36), "story_play")
	button("New", Rect2(637, 202, 95, 36), "story_new")
	button("Edit", Rect2(526, 248, 95, 31), "story_edit")
	button("Delete", Rect2(637, 248, 95, 31), "story_delete")
	var words_per_level := custom_story_words_per_level(story_manager_index)
	draw_text_line("Words per level", Vector2(526, 306), 12, pal.letter)
	button("-", Rect2(526, 316, 42, 31), "story_words_less")
	draw_text_line(str(words_per_level), Vector2(596, 337), 18, pal.letter, HORIZONTAL_ALIGNMENT_CENTER)
	button("+", Rect2(624, 316, 42, 31), "story_words_more")
	button("Dynamic %s" % ("On" if custom_story_dynamic(story_manager_index) else "Off"), Rect2(526, 353, 140, 31), "story_dynamic")
	button("Reset Progress", Rect2(520, 398, 152, 34), "story_reset_progress")
	button("Back", Rect2(56, 398, 110, 42), "back")


func draw_creator() -> void:
	var pal := palette()
	toolbar_rects.clear()
	draw_text_line("Story Editor", Vector2(48, 56), 29, pal.letter)
	var message := creator_status_message()
	draw_text_line(message, Vector2(50, 83), 12, pal.letter)
	var name_box := Rect2(50, 94, 700, 42)
	var story_box := Rect2(50, 153, 700, 220)
	draw_editor_box(name_box, creator_focus == "name", creator_name, "Story name", 1, 0, creator_name_caret)
	draw_editor_box(story_box, creator_focus == "story", creator_text, "Paste your writing here. Each sentence becomes one level.", 8, creator_story_scroll, creator_text_caret)
	draw_scroll_hint(story_box, editor_line_count(creator_text if creator_text != "" else "Paste your writing here. Each sentence becomes one level.", int(story_box.size.x - 28), 14), 8, creator_story_scroll)
	toolbar_rects["focus_name"] = name_box
	toolbar_rects["focus_story"] = story_box
	draw_text_line("Ctrl+V paste works in the selected box.", Vector2(54, 394), 12, pal.letter)
	button("Back", Rect2(50, 414, 110, 42), "manager")
	button("Save Story", Rect2(570, 414, 180, 42), "save_story")


func creator_status_message() -> String:
	var text := creator_text.strip_edges()
	if text == "":
		return creator_message
	var count := generated_level_count(text)
	if count <= 0:
		return "Add a few longer sentences with clear words to create levels."
	return "%d levels will be created. Save when the story looks right." % count


func draw_editor_box(r: Rect2, focused: bool, text: String, placeholder: String, max_lines: int, scroll := 0, caret := 0) -> void:
	draw_solid_rect(r, Color.WHITE)
	draw_outline_rect(r, palette().word, 4 if focused else 2)
	var display_text := text if text != "" else placeholder
	var lines := wrap_segments(display_text, int(r.size.x - 28), 14)
	scroll = clampi(scroll, 0, maxi(0, lines.size() - max_lines))
	var y := r.position.y + 28
	draw_editor_selection(r, lines, scroll, max_lines)
	for i in range(scroll, min(scroll + max_lines, lines.size())):
		var line_text := str(lines[i].text)
		var col := Color8(45, 35, 35) if text != "" else Color8(95, 78, 75)
		draw_text_line(line_text, Vector2(r.position.x + 14, y), 14, col)
		y += 25
	if focused and text != "":
		draw_editor_caret(r, lines, caret, scroll, max_lines)


func draw_editor_selection(r: Rect2, lines: Array, scroll: int, max_lines: int) -> void:
	if creator_selection_focus == "":
		return
	var is_name := max_lines == 1
	if (is_name and creator_selection_focus != "name") or ((not is_name) and creator_selection_focus != "story"):
		return
	var bounds := creator_selection_bounds()
	if bounds.is_empty():
		return
	var from_idx := int(bounds[0])
	var to_idx := int(bounds[1])
	if from_idx == to_idx:
		return
	var sel_col: Color = palette().word
	sel_col.a = 0.22
	for i in range(scroll, min(scroll + max_lines, lines.size())):
		var seg: Dictionary = lines[i]
		var seg_start := int(seg.start)
		var seg_end := int(seg.end)
		var a := maxi(from_idx, seg_start)
		var b := mini(to_idx, seg_end)
		if a > b or (a == b and b != to_idx):
			continue
		var line_text := str(seg.text)
		var before := line_text.substr(0, maxi(0, a - seg_start))
		var selected := line_text.substr(maxi(0, a - seg_start), maxi(0, b - a))
		var x := r.position.x + 14.0 + font.get_string_size(before, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var w := maxf(3.0, font.get_string_size(selected, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
		var y := r.position.y + 11.0 + float(i - scroll) * 25.0
		draw_solid_rect(Rect2(x, y, w, 22), sel_col)


func draw_scroll_hint(r: Rect2, line_count: int, visible_lines: int, scroll: int) -> void:
	if line_count <= visible_lines:
		return
	var pal := palette()
	var bar_h := maxf(18.0, (r.size.y - 18.0) * float(visible_lines) / float(line_count))
	var range_h := r.size.y - 18.0 - bar_h
	var y := r.position.y + 9.0 + range_h * float(scroll) / float(maxi(1, line_count - visible_lines))
	var track_col: Color = pal.word.lerp(Color.WHITE, 0.55)
	track_col.a = 0.45
	draw_solid_rect(Rect2(r.end.x - 12, r.position.y + 9, 4, r.size.y - 18), track_col)
	draw_solid_rect(Rect2(r.end.x - 14, y, 8, bar_h), pal.word)


func editor_line_count(text: String, max_width: int, size_px: int) -> int:
	return wrap_lines(text, max_width, size_px).size()


func draw_editor_caret(r: Rect2, lines: Array, caret: int, scroll: int, max_lines: int) -> void:
	if int(Time.get_ticks_msec() / 500) % 2 == 1:
		return
	var caret_line := -1
	var caret_x := r.position.x + 14.0
	for i in range(lines.size()):
		var seg: Dictionary = lines[i]
		if caret >= int(seg.start) and caret <= int(seg.end):
			caret_line = i
			var before := str(seg.text).substr(0, caret - int(seg.start))
			caret_x += font.get_string_size(before, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			break
	if caret_line == -1 and lines.size() > 0:
		caret_line = lines.size() - 1
		var last: Dictionary = lines[-1]
		caret_x += font.get_string_size(str(last.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	if caret_line < scroll or caret_line >= scroll + max_lines:
		return
	var y := r.position.y + 13.0 + float(caret_line - scroll) * 25.0
	draw_line(logical_pos(Vector2(caret_x, y)), logical_pos(Vector2(caret_x, y + 20)), palette().word, logical_size(2.0))


func button(label: String, r: Rect2, key: String) -> void:
	var pal := palette()
	var now := Time.get_ticks_msec() / 1000.0
	var hit_rect := touch_rect(r)
	var hovered: bool = hit_rect.has_point(mouse_logical_pos)
	var pressed: bool = key == pressed_toolbar_key and now - pressed_toolbar_at < 0.16
	var grow: float = 2.0 if hovered else 0.0
	if pressed:
		grow = -1.0
	var rr := Rect2(r.position - Vector2(grow, grow), r.size + Vector2(grow * 2.0, grow * 2.0))
	var col: Color = pal.word
	if hovered:
		col = col.lerp(pal.letter, 0.18)
	if pressed:
		col = col.lerp(pal.bg, 0.12)
	draw_solid_rect(rr, col)
	draw_button_click_effects(key, rr)
	draw_text_line(label, rr.get_center() + Vector2(0, 6), 16, pal.bg, HORIZONTAL_ALIGNMENT_CENTER)
	toolbar_rects[key] = hit_rect


func draw_button_click_effects(key: String, r: Rect2) -> void:
	var keep := []
	var now := Time.get_ticks_msec() / 1000.0
	for item in button_click_effects:
		var age := now - float(item.t)
		if age <= 0.45:
			keep.append(item)
			if str(item.key) == key:
				var p := ease_out_cubic(age / 0.45)
				var col: Color = palette().letter
				col.a = 0.32 * (1.0 - p)
				draw_outline_rect(Rect2(r.position - Vector2(5, 5) * p, r.size + Vector2(10, 10) * p), col, 2.0)
	button_click_effects = keep


func wrap_lines(text: String, max_width: int, size_px: int) -> Array:
	var out := []
	for seg in wrap_segments(text, max_width, size_px):
		out.append(str(seg.text))
	return out


func wrap_segments(text: String, max_width: int, size_px: int) -> Array:
	var out := []
	var cursor := 0
	for paragraph in text.split("\n"):
		var current := ""
		var current_start := cursor
		var search_from := 0
		var words := paragraph.split(" ", false)
		for word in words:
			var word_start_in_paragraph := paragraph.find(word, search_from)
			if word_start_in_paragraph < 0:
				word_start_in_paragraph = search_from
			var word_start := cursor + word_start_in_paragraph
			search_from = word_start_in_paragraph + word.length() + 1
			var test := (current + " " + word).strip_edges()
			if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x <= max_width:
				if current == "":
					current_start = word_start
				current = test
			else:
				if current != "":
					out.append({"text": current, "start": current_start, "end": current_start + current.length()})
				current = word
				current_start = word_start
		if current != "":
			out.append({"text": current, "start": current_start, "end": current_start + current.length()})
		elif paragraph == "":
			out.append({"text": "", "start": cursor, "end": cursor})
		cursor += paragraph.length() + 1
	return out


func current_story_name() -> String:
	var stories: Array = state.get("stories", [])
	if active_story_index >= 0 and active_story_index < stories.size():
		return str(stories[active_story_index].get("name", "Untitled Story"))
	return "No Story"


func story_manager_rows() -> Array:
	var rows := []
	for story in state.get("stories", []):
		rows.append({"name": str(story.get("name", "Untitled Story")), "count": story.get("levels", []).size()})
	return rows


func custom_story_words_per_level(index: int) -> int:
	var stories: Array = state.get("stories", [])
	if index >= 0 and index < stories.size():
		return clampi(int(stories[index].get("words_per_level", DEFAULT_WORDS_PER_LEVEL)), MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL)
	return DEFAULT_WORDS_PER_LEVEL


func custom_story_dynamic(index: int) -> bool:
	var stories: Array = state.get("stories", [])
	if index >= 0 and index < stories.size():
		return bool(stories[index].get("dynamic_words", true))
	return true


func open_story_manager() -> void:
	story_manager_index = clampi(active_story_index, 0, maxi(0, state.get("stories", []).size() - 1))
	mode = "manager"
	play_sfx("reader_open")


func open_creator(edit_index = null) -> void:
	creator_edit_index = edit_index
	creator_focus = "name"
	creator_story_scroll = 0
	if edit_index == null:
		creator_name = ""
		creator_text = ""
		creator_message = "Paste a story, then click Save Story."
	else:
		var story = state["stories"][edit_index]
		creator_name = str(story.get("name", "Untitled Story"))
		creator_text = str(story.get("text", ""))
		creator_message = "Edit the name or story text, then save."
	creator_name_caret = creator_name.length()
	creator_text_caret = creator_text.length()
	mode = "creator"


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		handle_key(event)
	elif event is InputEventMouseButton:
		mouse_logical_pos = to_logical(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				handle_mouse_down(mouse_logical_pos)
			else:
				handle_mouse_up(mouse_logical_pos)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			handle_scroll(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
	elif event is InputEventMouseMotion:
		mouse_logical_pos = to_logical(event.position)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			handle_mouse_drag(mouse_logical_pos)


func handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_BACK:
		go_back()
		return
	if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
		get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
		return
	if mode == "creator":
		if event.ctrl_pressed and event.keycode == KEY_A:
			if creator_focus == "name":
				set_creator_selection("name", 0, creator_name.length())
				creator_name_caret = creator_name.length()
			else:
				set_creator_selection("story", 0, creator_text.length())
				creator_text_caret = creator_text.length()
				ensure_story_caret_visible()
			return
		if event.ctrl_pressed and event.keycode == KEY_C:
			DisplayServer.clipboard_set(selected_creator_text())
			return
		if event.ctrl_pressed and event.keycode == KEY_X:
			DisplayServer.clipboard_set(selected_creator_text())
			if not consume_creator_selection():
				if creator_focus == "name":
					creator_name = ""
					creator_name_caret = 0
				else:
					creator_text = ""
					creator_text_caret = 0
					creator_story_scroll = 0
			return
		if event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN] and creator_focus == "story":
			var step := -4 if event.keycode == KEY_PAGEUP else 4
			scroll_creator_story(step)
			return
		if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_HOME, KEY_END, KEY_UP, KEY_DOWN]:
			move_creator_caret(event.keycode, event.shift_pressed)
			return
		if event.keycode == KEY_TAB:
			creator_focus = "story" if creator_focus == "name" else "name"
			return
		if event.keycode == KEY_BACKSPACE:
			if consume_creator_selection():
				return
			if creator_focus == "name":
				if creator_name_caret > 0:
					creator_name = creator_name.substr(0, creator_name_caret - 1) + creator_name.substr(creator_name_caret)
					creator_name_caret -= 1
			else:
				if creator_text_caret > 0:
					creator_text = creator_text.substr(0, creator_text_caret - 1) + creator_text.substr(creator_text_caret)
					creator_text_caret -= 1
				clamp_creator_story_scroll()
			return
		if event.keycode == KEY_DELETE:
			if consume_creator_selection():
				return
			if creator_focus == "name":
				if creator_name_caret < creator_name.length():
					creator_name = creator_name.substr(0, creator_name_caret) + creator_name.substr(creator_name_caret + 1)
			else:
				if creator_text_caret < creator_text.length():
					creator_text = creator_text.substr(0, creator_text_caret) + creator_text.substr(creator_text_caret + 1)
				clamp_creator_story_scroll()
			return
		if event.keycode == KEY_ENTER:
			if creator_focus == "name":
				creator_focus = "story"
			else:
				insert_creator_text("\n")
			return
		if event.ctrl_pressed and event.keycode == KEY_V:
			var clip := DisplayServer.clipboard_get()
			if creator_focus == "name":
				insert_creator_name(clip.replace("\n", " ").replace("\r", " "))
			else:
				insert_creator_text(clip)
			return
		if event.unicode > 0:
			var ch := String.chr(event.unicode)
			if creator_focus == "name" and ch != "\n" and ch != "\r":
				insert_creator_name(ch)
			elif creator_focus == "story":
				insert_creator_text(ch)
			return
	if mode == "story" and event.keycode in [KEY_PAGEUP, KEY_PAGEDOWN, KEY_UP, KEY_DOWN]:
		var step := -4 if event.keycode == KEY_PAGEUP else 4 if event.keycode == KEY_PAGEDOWN else -1 if event.keycode == KEY_UP else 1
		scroll_story_view(step)
		return
	if event.keycode == KEY_C:
		open_creator()
	elif event.keycode == KEY_M:
		open_story_manager()
	elif event.keycode == KEY_S:
		mode = "story"
		story_view_scroll = 0
		story_body_scroll = 0
		play_sfx("reader_open")
	elif event.keycode == KEY_ESCAPE:
		go_back()


func go_back() -> void:
	match mode:
		"creator":
			mode = "manager"
			play_sfx("reader_close")
		"manager":
			mode = "play"
			play_sfx("reader_close")
		"story":
			mode = "play"
			play_sfx("reader_close")
		"reveal":
			next_level()
		"complete":
			mode = "reveal"
			reveal_t = 0.0
		"preload":
			mode = "play" if has_playable_level() else "manager"
		_:
			save_state()


func handle_mouse_down(pos: Vector2) -> void:
	pressed_toolbar_key = toolbar_key_at(pos)
	pressed_toolbar_at = Time.get_ticks_msec() / 1000.0
	if pressed_toolbar_key != "":
		button_click_effects.append({"key": pressed_toolbar_key, "t": pressed_toolbar_at})
	if mode in ["story", "manager", "creator"]:
		if mode == "creator":
			handle_creator_click(pos)
		handle_toolbar(pos)
		return
	if mode == "reveal":
		next_level()
		return
	if handle_toolbar(pos):
		return
	var cell = cell_at(pos)
	var now := Time.get_ticks_msec() / 1000.0
	if cell != null:
		selection_start = cell
		selection_current = cell
		last_drag_cell = cell
		selection_started_at = now
		add_cell_burst(cell)
		play_sfx("word_start")
		if last_click_cell == cell and now - last_click_time < 0.42:
			var word = word_starting_at(cell)
			if word != null:
				selection_current = word_cells(word)[-1]
				add_word_burst(word_cells(word))
		last_click_cell = cell
	else:
		last_click_cell = null
	last_click_time = now


func handle_mouse_drag(pos: Vector2) -> void:
	if mode == "creator" and creator_mouse_selecting:
		update_creator_drag_selection(pos)
		return
	if mode != "play":
		return
	var cell = cell_at(pos)
	if cell != null and selection_start != null:
		if selection_current == null or selection_current != cell:
			selection_current = cell
			last_drag_cell = cell
			add_cell_burst(cell)


func handle_mouse_up(pos: Vector2) -> void:
	creator_mouse_selecting = false
	pressed_toolbar_key = ""
	if mode != "play":
		return
	var cell = cell_at(pos)
	if cell != null and selection_start != null:
		selection_current = cell
		var cells := selection_cells()
		var match = word_for_cells(cells)
		if cells.size() > 1:
			play_sfx("letter_submit")
		if match != null and not found_words().has(str(match.text)):
			mark_found(str(match.text))
			found_effects.append({"cells": word_cells(match), "word": str(match.text), "t": Time.get_ticks_msec() / 1000.0})
			add_word_burst(word_cells(match))
			play_sfx("word_found")
		elif cells.size() > 1:
			play_sfx("word_missed")
	selection_start = null
	selection_current = null
	last_drag_cell = null


func handle_scroll(direction: int) -> void:
	if mode == "creator" and creator_focus == "story":
		scroll_creator_story(direction)
	elif mode == "story":
		scroll_story_view(direction)


func handle_creator_click(pos: Vector2) -> void:
	var name_box := Rect2(50, 94, 700, 42)
	var story_box := Rect2(50, 153, 700, 220)
	if name_box.has_point(pos):
		creator_focus = "name"
		creator_select_all = ""
		creator_name_caret = caret_from_point(name_box, creator_name, pos, 0)
		start_creator_mouse_selection("name", creator_name_caret)
	elif story_box.has_point(pos):
		creator_focus = "story"
		creator_select_all = ""
		creator_text_caret = caret_from_point(story_box, creator_text, pos, creator_story_scroll)
		start_creator_mouse_selection("story", creator_text_caret)


func insert_creator_name(text: String) -> void:
	if consume_creator_selection():
		pass
	var allowed := text.substr(0, maxi(0, 60 - creator_name.length()))
	creator_name = creator_name.substr(0, creator_name_caret) + allowed + creator_name.substr(creator_name_caret)
	creator_name_caret += allowed.length()


func insert_creator_text(text: String) -> void:
	if consume_creator_selection():
		pass
	var allowed := text.substr(0, maxi(0, 8000 - creator_text.length()))
	creator_text = creator_text.substr(0, creator_text_caret) + allowed + creator_text.substr(creator_text_caret)
	creator_text_caret += allowed.length()
	ensure_story_caret_visible()


func consume_creator_selection() -> bool:
	var bounds := creator_selection_bounds()
	if bounds.is_empty():
		if creator_select_all == "":
			return false
		if creator_select_all == "name":
			creator_name = ""
			creator_name_caret = 0
		else:
			creator_text = ""
			creator_text_caret = 0
			creator_story_scroll = 0
		creator_select_all = ""
		clear_creator_selection()
		return true
	var from_idx := int(bounds[0])
	var to_idx := int(bounds[1])
	if from_idx == to_idx:
		clear_creator_selection()
		return false
	if creator_selection_focus == "name":
		creator_name = creator_name.substr(0, from_idx) + creator_name.substr(to_idx)
		creator_name_caret = from_idx
	else:
		creator_text = creator_text.substr(0, from_idx) + creator_text.substr(to_idx)
		creator_text_caret = from_idx
		ensure_story_caret_visible()
	creator_select_all = ""
	clear_creator_selection()
	return true


func selected_creator_text() -> String:
	var bounds := creator_selection_bounds()
	if bounds.is_empty():
		return creator_name if creator_focus == "name" else creator_text
	var source := creator_name if creator_selection_focus == "name" else creator_text
	return source.substr(int(bounds[0]), int(bounds[1]) - int(bounds[0]))


func creator_selection_bounds() -> Array:
	if creator_selection_focus == "" or creator_selection_anchor < 0:
		return []
	var caret := creator_name_caret if creator_selection_focus == "name" else creator_text_caret
	var a := mini(creator_selection_anchor, caret)
	var b := maxi(creator_selection_anchor, caret)
	return [a, b]


func set_creator_selection(field: String, from_idx: int, to_idx: int) -> void:
	creator_select_all = ""
	creator_selection_focus = field
	creator_selection_anchor = clampi(from_idx, 0, creator_name.length() if field == "name" else creator_text.length())
	if field == "name":
		creator_name_caret = clampi(to_idx, 0, creator_name.length())
	else:
		creator_text_caret = clampi(to_idx, 0, creator_text.length())
		ensure_story_caret_visible()
	if creator_selection_anchor == (creator_name_caret if field == "name" else creator_text_caret):
		clear_creator_selection()


func clear_creator_selection() -> void:
	creator_select_all = ""
	creator_selection_anchor = -1
	creator_selection_focus = ""


func start_creator_mouse_selection(field: String, caret: int) -> void:
	clear_creator_selection()
	creator_mouse_selecting = true
	creator_selection_focus = field
	creator_selection_anchor = caret


func update_creator_drag_selection(pos: Vector2) -> void:
	var name_box := Rect2(50, 94, 700, 42)
	var story_box := Rect2(50, 153, 700, 220)
	if creator_selection_focus == "name":
		creator_name_caret = caret_from_point(name_box, creator_name, pos, 0)
		if creator_name_caret == creator_selection_anchor:
			clear_creator_selection()
			creator_selection_focus = "name"
			creator_selection_anchor = creator_name_caret
		return
	if creator_selection_focus == "story":
		creator_text_caret = caret_from_point(story_box, creator_text, pos, creator_story_scroll)
		ensure_story_caret_visible()
		if creator_text_caret == creator_selection_anchor:
			clear_creator_selection()
			creator_selection_focus = "story"
			creator_selection_anchor = creator_text_caret


func move_creator_caret(keycode: int, selecting := false) -> void:
	var old_caret := creator_name_caret if creator_focus == "name" else creator_text_caret
	if selecting and creator_selection_focus != creator_focus:
		creator_selection_anchor = old_caret
		creator_selection_focus = creator_focus
	elif not selecting:
		clear_creator_selection()
	if creator_focus == "name":
		if keycode == KEY_LEFT:
			creator_name_caret = maxi(0, creator_name_caret - 1)
		elif keycode == KEY_RIGHT:
			creator_name_caret = mini(creator_name.length(), creator_name_caret + 1)
		elif keycode == KEY_HOME:
			creator_name_caret = 0
		elif keycode == KEY_END:
			creator_name_caret = creator_name.length()
	else:
		if keycode == KEY_LEFT:
			creator_text_caret = maxi(0, creator_text_caret - 1)
		elif keycode == KEY_RIGHT:
			creator_text_caret = mini(creator_text.length(), creator_text_caret + 1)
		elif keycode == KEY_HOME:
			creator_text_caret = 0
		elif keycode == KEY_END:
			creator_text_caret = creator_text.length()
		elif keycode == KEY_UP:
			scroll_creator_story(-1)
		elif keycode == KEY_DOWN:
			scroll_creator_story(1)
		ensure_story_caret_visible()
	if selecting:
		var new_caret := creator_name_caret if creator_focus == "name" else creator_text_caret
		set_creator_selection(creator_focus, creator_selection_anchor, new_caret)


func ensure_story_caret_visible() -> void:
	var lines := wrap_segments(creator_text if creator_text != "" else "", 672, 14)
	for i in range(lines.size()):
		if creator_text_caret >= int(lines[i].start) and creator_text_caret <= int(lines[i].end):
			if i < creator_story_scroll:
				creator_story_scroll = i
			elif i >= creator_story_scroll + 8:
				creator_story_scroll = i - 7
			break
	clamp_creator_story_scroll()


func caret_from_point(r: Rect2, text: String, pos: Vector2, scroll: int) -> int:
	if text == "":
		return 0
	var lines := wrap_segments(text, int(r.size.x - 28), 14)
	var line_index := clampi(int(floor((pos.y - (r.position.y + 18.0)) / 25.0)) + scroll, 0, maxi(0, lines.size() - 1))
	var seg: Dictionary = lines[line_index]
	var rel_x := maxf(0.0, pos.x - (r.position.x + 14.0))
	var line_text := str(seg.text)
	var best := int(seg.start)
	for i in range(line_text.length() + 1):
		var width := font.get_string_size(line_text.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		if width <= rel_x:
			best = int(seg.start) + i
		else:
			break
	return clampi(best, 0, text.length())


func scroll_creator_story(delta: int) -> void:
	creator_story_scroll += delta
	clamp_creator_story_scroll()


func clamp_creator_story_scroll() -> void:
	var lines := editor_line_count(creator_text if creator_text != "" else "Paste the full story here. Each sentence becomes one letter-grid level.", 672, 14)
	creator_story_scroll = clampi(creator_story_scroll, 0, maxi(0, lines - 8))


func scroll_story_view(delta: int) -> void:
	story_view_scroll += delta
	story_body_scroll += delta
	story_view_scroll = clampi(story_view_scroll, 0, maxi(0, levels.size() - 12))
	var solved := []
	for lvl in levels:
		var progress: Array = state.get("progress", {}).get(str(lvl.name), [])
		if progress.size() >= lvl.words.size():
			solved.append(str(lvl.story))
	var body := "Finish levels to add entries to this notebook." if solved.is_empty() else " ".join(solved)
	var body_lines := wrap_lines(body.strip_edges(), 390, 14)
	story_body_scroll = clampi(story_body_scroll, 0, maxi(0, body_lines.size() - 9))


func handle_toolbar(pos: Vector2) -> bool:
	for key in toolbar_rects.keys():
		if toolbar_rects[key].has_point(pos):
			match str(key):
				"sound":
					set_audio_enabled(not bool(state.get("volume", true)))
				"hint":
					for word in level().words:
						if not found_words().has(str(word.text)):
							hint_word = str(word.text)
							hint_until = Time.get_ticks_msec() / 1000.0 + 2.6
							play_sfx("hint")
							break
				"font":
					state["font"] = (int(state.get("font", 0)) + 1) % FONT_CHOICES.size()
					apply_font_choice()
					play_sfx("font")
				"palette":
					state["palette"] = (int(state.get("palette", 0)) + 1) % PALETTES.size()
					play_sfx("palette")
				"story":
					mode = "story"
					story_view_scroll = 0
					story_body_scroll = 0
					play_sfx("reader_open")
				"manager":
					open_story_manager()
				"back":
					mode = "play"
					play_sfx("reader_close")
				"focus_name":
					creator_focus = "name"
					creator_select_all = ""
				"focus_story":
					creator_focus = "story"
					creator_select_all = ""
				"story_play":
					if state.get("stories", []).is_empty():
						open_creator()
						return true
					active_story_index = story_manager_index
					state["active_story"] = active_story_index
					state["level"] = 0
					ensure_active_story_levels()
					rebuild_levels()
					reset_level_timer()
					if has_playable_level():
						mode = "play"
					else:
						open_creator(active_story_index)
					play_sfx("ui_click")
				"story_new":
					open_creator()
				"story_edit":
					open_creator(story_manager_index)
				"story_delete":
					delete_story()
				"story_reset_progress":
					reset_selected_story_progress()
				"story_words_less":
					adjust_selected_story_words(-1)
				"story_words_more":
					adjust_selected_story_words(1)
				"story_dynamic":
					toggle_selected_story_dynamic()
				"save_story":
					save_story_from_editor()
				_:
					if str(key).begins_with("story_select_"):
						story_manager_index = int(str(key).get_slice("_", 2))
						play_sfx("ui_click")
			save_state()
			return true
	return false


func toolbar_key_at(pos: Vector2) -> String:
	for key in toolbar_rects.keys():
		if toolbar_rects[key].has_point(pos):
			return str(key)
	return ""


func delete_story() -> void:
	var idx := story_manager_index
	var stories: Array = state.get("stories", [])
	if idx >= 0 and idx < stories.size():
		stories.remove_at(idx)
		if active_story_index == idx:
			active_story_index = -1
			state["level"] = 0
			rebuild_levels()
		elif active_story_index > idx:
			active_story_index -= 1
			state["active_story"] = active_story_index
	story_manager_index = clampi(story_manager_index, 0, maxi(0, stories.size() - 1))
	play_sfx("ui_click")


func reset_selected_story_progress() -> void:
	var target_levels: Array = []
	var stories: Array = state.get("stories", [])
	var idx := story_manager_index
	if idx >= 0 and idx < stories.size():
		target_levels = stories[idx].get("levels", [])
	var progress: Dictionary = state.get("progress", {})
	for lvl in target_levels:
		progress.erase(str(lvl.name))
	state["progress"] = progress
	if story_manager_index == active_story_index:
		state["level"] = 0
		current_level_index = 0
		reset_level_timer()
	play_sfx("ui_click")
	save_state()


func adjust_selected_story_words(delta: int) -> void:
	var stories: Array = state.get("stories", [])
	var idx := story_manager_index
	if idx < 0 or idx >= stories.size():
		return
	var story: Dictionary = stories[idx]
	story["words_per_level"] = clampi(int(story.get("words_per_level", DEFAULT_WORDS_PER_LEVEL)) + delta, MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL)
	mark_custom_story_dirty(idx)
	play_sfx("ui_click")
	save_state()


func toggle_selected_story_dynamic() -> void:
	var stories: Array = state.get("stories", [])
	var idx := story_manager_index
	if idx < 0 or idx >= stories.size():
		return
	var story: Dictionary = stories[idx]
	story["dynamic_words"] = not bool(story.get("dynamic_words", true))
	mark_custom_story_dirty(idx)
	play_sfx("ui_click")
	save_state()


func mark_custom_story_dirty(index: int) -> void:
	var stories: Array = state.get("stories", [])
	if index < 0 or index >= stories.size():
		return
	var story: Dictionary = stories[index]
	story["levels_dirty"] = true
	story["settings_version"] = STORY_SETTINGS_VERSION


func ensure_active_story_levels() -> void:
	if active_story_index < 0:
		return
	ensure_custom_story_levels(active_story_index)


func ensure_custom_story_levels(index: int) -> void:
	var stories: Array = state.get("stories", [])
	if index < 0 or index >= stories.size():
		return
	var story: Dictionary = stories[index]
	if bool(story.get("levels_dirty", false)) or not story.has("levels") or int(story.get("settings_version", 0)) < STORY_SETTINGS_VERSION:
		regenerate_custom_story(index)


func regenerate_custom_story(index: int) -> void:
	var stories: Array = state.get("stories", [])
	if index < 0 or index >= stories.size():
		return
	var story: Dictionary = stories[index]
	story["words_per_level"] = clampi(int(story.get("words_per_level", DEFAULT_WORDS_PER_LEVEL)), MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL)
	story["dynamic_words"] = bool(story.get("dynamic_words", true))
	story["levels"] = generate_levels_from_story(str(story.get("text", "")), str(story.get("name", "Untitled Story")), int(story.get("words_per_level", DEFAULT_WORDS_PER_LEVEL)), bool(story.get("dynamic_words", true)))
	story["levels_dirty"] = false
	story["settings_version"] = STORY_SETTINGS_VERSION


func save_story_from_editor() -> void:
	var story_name := creator_name.strip_edges()
	if story_name == "":
		story_name = "Untitled Story"
	var words_per_level := DEFAULT_WORDS_PER_LEVEL
	var dynamic_words := true
	if creator_edit_index != null:
		words_per_level = custom_story_words_per_level(int(creator_edit_index))
		dynamic_words = custom_story_dynamic(int(creator_edit_index))
	var new_levels := generate_levels_from_story(creator_text, story_name, words_per_level, dynamic_words)
	if new_levels.is_empty():
		creator_message = "I need a little more story text to build levels."
		return
	var story := {"name": story_name.substr(0, 60), "text": creator_text, "levels": new_levels, "words_per_level": words_per_level, "dynamic_words": dynamic_words, "levels_dirty": false, "settings_version": STORY_SETTINGS_VERSION}
	var stories: Array = state.get("stories", [])
	state["stories"] = stories
	if creator_edit_index == null:
		stories.append(story)
		active_story_index = stories.size() - 1
	else:
		stories[creator_edit_index] = story
		active_story_index = int(creator_edit_index)
	state["active_story"] = active_story_index
	state["level"] = 0
	rebuild_levels()
	reset_level_timer()
	mode = "play"
	play_sfx("ui_click")
	save_state()


func next_level() -> void:
	if levels.is_empty():
		mode = "manager"
		return
	current_level_index = (current_level_index + 1) % levels.size()
	state["level"] = current_level_index
	reset_level_timer()
	mode = "play"
	play_sfx("level_next")
	save_state()


func generate_levels_from_story(story: String, story_name: String, words_per_level := DEFAULT_WORDS_PER_LEVEL, dynamic_words := true) -> Array:
	var sentences := story_sentences(story)
	var out := []
	var index := 1
	var cooldown := {}
	words_per_level = clampi(words_per_level, MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL)
	for sentence in sentences:
		var words := pick_words(sentence, words_per_level, dynamic_words, cooldown)
		if words.size() >= 4:
			out.append(generate_board(sentence, words, index, story_name))
			apply_word_cooldown(cooldown, words)
			index += 1
	return out


func generated_level_count(story: String) -> int:
	var count := 0
	var cooldown := {}
	for sentence in story_sentences(story):
		var words := pick_words(sentence, DEFAULT_WORDS_PER_LEVEL, true, cooldown)
		if words.size() >= 4:
			count += 1
			apply_word_cooldown(cooldown, words)
	return count


func story_sentences(story: String) -> Array:
	var source := repair_hyphenated_line_breaks(normalize_extra_sentence_punctuation(normalize_story_punctuation(normalize_web_copy_markup(story.strip_edges()))))
	if not has_sentence_punctuation(source) and source.contains("\n"):
		return split_line_fallback_sentences(source)
	var sentences := []
	var protected := protect_sentence_punctuation(source)
	for raw_sentence in scan_protected_sentences(protected):
		var sentence := clean_sentence_text(restore_sentence_punctuation(str(raw_sentence).strip_edges()))
		if sentence != "":
			append_story_sentence(sentences, sentence)
	sentences = merge_sentence_fragments(sentences)
	sentences = remove_story_artifacts(sentences)
	sentences = split_likely_abbreviation_boundaries(sentences)
	sentences = merge_title_fragments(sentences)
	sentences = split_after_title_intro_sentence(sentences)
	sentences = remove_story_artifacts(sentences)
	if sentences.is_empty() and source != "":
		sentences.append(source)
	return sentences


func has_sentence_punctuation(text: String) -> bool:
	return text.contains(".") or text.contains("!") or text.contains("?")


func split_line_fallback_sentences(source: String) -> Array:
	var out := []
	if has_blank_line(source):
		for block in split_blank_line_blocks(source):
			var parts := []
			for line in str(block).split("\n", false):
				var part := clean_sentence_text(restore_sentence_punctuation(str(line).strip_edges()))
				if part != "" and not is_story_artifact_sentence(part):
					parts.append(part)
			var sentence := clean_sentence_text(" ".join(parts))
			if sentence != "" and not is_story_artifact_sentence(sentence):
				out.append(sentence)
		if not out.is_empty():
			return out
	for line in source.split("\n", false):
		var sentence := clean_sentence_text(restore_sentence_punctuation(str(line).strip_edges()))
		if sentence != "" and not is_story_artifact_sentence(sentence):
			out.append(sentence)
	if out.is_empty() and source.strip_edges() != "":
		out.append(clean_sentence_text(source))
	return out


func has_blank_line(source: String) -> bool:
	var re := RegEx.new()
	re.compile("(?m)^\\s*$")
	return re.search(source) != null


func split_blank_line_blocks(source: String) -> Array:
	var normalized := source.replace("\r\n", "\n").replace("\r", "\n")
	var re := RegEx.new()
	re.compile("\\n\\s*\\n+")
	var blocks := []
	var start := 0
	for m in re.search_all(normalized):
		blocks.append(normalized.substr(start, m.get_start() - start))
		start = m.get_end()
	if start <= normalized.length():
		blocks.append(normalized.substr(start))
	return blocks


func scan_protected_sentences(text: String) -> Array:
	var out := []
	var start := 0
	var i := 0
	while i < text.length():
		var ch := text.substr(i, 1)
		if ".!?".contains(ch):
			while i + 1 < text.length() and ".!?".contains(text.substr(i + 1, 1)):
				i += 1
			while i + 1 < text.length() and sentence_closer_chars().contains(text.substr(i + 1, 1)) and should_consume_sentence_closer(text, i + 1):
				i += 1
			i = consume_trailing_citation(text, i)
			out.append(text.substr(start, i - start + 1))
			start = i + 1
		i += 1
	if start < text.length():
		out.append(text.substr(start))
	return out


func should_consume_sentence_closer(text: String, index: int) -> bool:
	var ch := text.substr(index, 1)
	if ch != "\"" and ch != "'":
		return true
	if index + 1 >= text.length():
		return true
	var next := text.substr(index + 1, 1)
	if not is_ascii_letter_or_digit(next):
		return true
	return has_unclosed_quote_before_closer(text, index, ch)


func has_unclosed_quote_before_closer(text: String, index: int, quote: String) -> bool:
	var start := 0
	for i in range(index - 2, -1, -1):
		if ".!?".contains(text.substr(i, 1)):
			start = i + 1
			break
	var count := 0
	for i in range(start, index):
		if text.substr(i, 1) == quote:
			count += 1
	return count % 2 == 1


func is_ascii_letter_or_digit(ch: String) -> bool:
	if ch == "":
		return false
	var code := ch.unicode_at(0)
	return (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)


func consume_trailing_citation(text: String, index: int) -> int:
	var cursor := index + 1
	while cursor < text.length() and text.substr(cursor, 1).strip_edges() == "":
		cursor += 1
	if cursor >= text.length():
		return index
	var open := text.substr(cursor, 1)
	if open != "[" and open != "(":
		return index
	var close := "]" if open == "[" else ")"
	var end := text.find(close, cursor + 1)
	if end < 0 or end - cursor > 24:
		return index
	var inside := text.substr(cursor + 1, end - cursor - 1).strip_edges()
	if not is_citation_text(inside):
		return index
	if end + 1 < text.length() and text.substr(end + 1, 1).strip_edges() != "":
		return index
	return end


func is_citation_text(inside: String) -> bool:
	if inside == "":
		return false
	var re := RegEx.new()
	re.compile("^\\d+[A-Za-z]?$|^p+\\.?\\s*\\d+$|^[A-Za-z][A-Za-z\\-]+,\\s*\\d{4}$")
	return re.search(inside) != null


func normalize_web_copy_markup(text: String) -> String:
	var out := decode_story_html_entities(text)
	var block_end_re := RegEx.new()
	block_end_re.compile("(?i)<\\s*(br|/p|/div|/li|/h[1-6])[^>]*>")
	out = block_end_re.sub(out, "\n", true)
	var block_start_re := RegEx.new()
	block_start_re.compile("(?i)<\\s*(p|div|li|h[1-6]|blockquote)[^>]*>")
	out = block_start_re.sub(out, "\n", true)
	var tag_re := RegEx.new()
	tag_re.compile("(?i)<[^>]+>")
	out = tag_re.sub(out, " ", true)
	var quote_re := RegEx.new()
	quote_re.compile("(?m)^\\s*>\\s*")
	return quote_re.sub(out, "", true)


func decode_story_html_entities(text: String) -> String:
	var out := text
	var entities := {
		"&quot;": "\"",
		"&#34;": "\"",
		"&apos;": "'",
		"&#39;": "'",
		"&rsquo;": "'",
		"&lsquo;": "'",
		"&rdquo;": "\"",
		"&ldquo;": "\"",
		"&hellip;": "...",
		"&mdash;": "-",
		"&ndash;": "-",
		"&nbsp;": " ",
		"&amp;": "&",
		"&lt;": "<",
		"&gt;": ">",
	}
	for key in entities.keys():
		out = out.replace(str(key), str(entities[key]))
	return decode_numeric_html_entities(out)


func decode_numeric_html_entities(text: String) -> String:
	var out := text
	var re := RegEx.new()
	re.compile("&#(x[0-9A-Fa-f]+|\\d+);")
	var matches := re.search_all(out)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var value := m.get_string(1)
		var code := -1
		if value.begins_with("x"):
			code = parse_hex_codepoint(value.substr(1))
		elif value.is_valid_int():
			code = int(value)
		if code >= 0 and code <= 0x10FFFF:
			out = out.substr(0, m.get_start()) + String.chr(code) + out.substr(m.get_end())
	return out


func parse_hex_codepoint(hex_text: String) -> int:
	var total := 0
	for i in range(hex_text.length()):
		var code := hex_text.substr(i, 1).unicode_at(0)
		var value := -1
		if code >= 48 and code <= 57:
			value = code - 48
		elif code >= 65 and code <= 70:
			value = code - 55
		elif code >= 97 and code <= 102:
			value = code - 87
		else:
			return -1
		total = total * 16 + value
	return total


func normalize_extra_sentence_punctuation(text: String) -> String:
	var out := text
	out = out.replace(String.chr(0x201C), "\"").replace(String.chr(0x201D), "\"").replace(String.chr(0x201E), "\"").replace(String.chr(0x201F), "\"")
	out = out.replace(String.chr(0x2018), "'").replace(String.chr(0x2019), "'").replace(String.chr(0x201A), "'").replace(String.chr(0x201B), "'")
	out = out.replace(String.chr(0x2026), "...")
	out = out.replace(String.chr(0x2014), "-").replace(String.chr(0x2013), "-")
	out = out.replace(String.chr(0x2022), "-").replace(String.chr(0x00A0), " ")
	out = out.replace(String.chr(0x3002), ".").replace(String.chr(0xFF0E), ".")
	out = out.replace(String.chr(0xFF01), "!").replace(String.chr(0xFF1F), "?").replace(String.chr(0x061F), "?")
	out = out.replace(String.chr(0x00A1), "").replace(String.chr(0x00BF), "")
	out = out.replace(String.chr(0x00AB), "\"").replace(String.chr(0x00BB), "\"").replace(String.chr(0x2039), "\"").replace(String.chr(0x203A), "\"")
	return out


func normalize_story_punctuation(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n").replace("“", "\"").replace("”", "\"").replace("„", "\"").replace("‟", "\"").replace("‘", "'").replace("’", "'").replace("‚", "'").replace("‛", "'").replace("…", "...").replace("—", "-").replace("–", "-").replace("•", "-")


func repair_hyphenated_line_breaks(text: String) -> String:
	var re := RegEx.new()
	re.compile("([A-Za-z])[-­]\\s*\\n\\s*([A-Za-z])")
	return re.sub(text, "$1$2", true).replace("­", "")


func protect_sentence_punctuation(text: String) -> String:
	var out := text.replace("...", "__ELLIPSIS__")
	out = protect_dotted_tokens(out)
	out = protect_regex_dots(out, "\\bv?\\d+(?:\\.\\d+){1,}\\b")
	out = protect_regex_dots(out, "\\d+\\.\\d+")
	out = protect_regex_dots(out, "(^|\\s)\\d+\\.")
	out = protect_regex_dots(out, "\\b(?:Ph|Ed|M|D|J|S)\\.D\\.")
	out = protect_regex_dots(out, "\\b(?:[A-Za-z]\\.){2,}")
	out = protect_regex_dots(out, "\\b[A-Z]\\.")
	out = protect_regex_dots(out, "[Cc]hapter\\s+\\d+\\.")
	out = protect_regex_dots(out, "[Pp]art\\s+\\d+\\.")
	out = protect_regex_dots(out, "[Ss]ection\\s+\\d+\\.")
	out = protect_regex_dots(out, "[Bb]ook\\s+\\d+\\.")
	out = protect_regex_dots(out, "[Ee]pisode\\s+\\d+\\.")
	var abbreviations := ["Mr.", "Mrs.", "Ms.", "Mx.", "Dr.", "Prof.", "Sr.", "Jr.", "St.", "Mt.", "Capt.", "Cmdr.", "Lt.", "Gen.", "Col.", "Maj.", "Sgt.", "Rev.", "Hon.", "Sen.", "Rep.", "Gov.", "Pres.", "Supt.", "Det.", "Insp.", "Adm.", "Dept.", "Univ.", "No.", "Nos.", "Vol.", "Fig.", "Figs.", "Eq.", "Eqs.", "Ref.", "Refs.", "Inc.", "Ltd.", "Co.", "Corp.", "Ave.", "Blvd.", "Rd.", "Ln.", "Ct.", "Pl.", "Hwy.", "Apt.", "Ste.", "vs.", "etc.", "misc.", "approx.", "est.", "min.", "max.", "ft.", "in.", "oz.", "lb.", "lbs.", "kg.", "cm.", "mm.", "Jan.", "Feb.", "Mar.", "Apr.", "Jun.", "Jul.", "Aug.", "Sept.", "Sep.", "Oct.", "Nov.", "Dec.", "Mon.", "Tue.", "Tues.", "Wed.", "Thu.", "Thur.", "Thurs.", "Fri.", "Sat.", "Sun.", "e.g.", "i.e.", "a.m.", "p.m.", "U.S.", "U.K.", "U.N.", "D.C."]
	for abbr in abbreviations:
		out = out.replace(abbr, abbr.replace(".", "__DOT__"))
		out = out.replace(abbr.to_upper(), abbr.to_upper().replace(".", "__DOT__"))
	return out


func protect_dotted_tokens(text: String) -> String:
	var pieces := text.split(" ", false)
	for i in range(pieces.size()):
		var token := str(pieces[i])
		var trailing := ""
		while token.length() > 0 and token_trailing_chars().contains(token.substr(token.length() - 1, 1)):
			trailing = token.substr(token.length() - 1, 1) + trailing
			token = token.substr(0, token.length() - 1)
		var lower := token.to_lower()
		var dotted := token.contains(".")
		var should_protect := dotted and (lower.begins_with("http://") or lower.begins_with("https://") or lower.begins_with("www.") or token.contains("@") or is_domain_like_token(lower) or is_file_like_token(lower))
		if should_protect:
			token = token.replace(".", "__DOT__")
			token = token.replace("?", "__QMARK__")
			token = token.replace("!", "__BANG__")
		pieces[i] = token + trailing
	return " ".join(pieces)


func is_domain_like_token(token: String) -> bool:
	var base := token.split("/", false)[0].split(":", false)[0]
	var endings := [".com", ".org", ".net", ".edu", ".gov", ".io", ".co", ".us", ".uk", ".ca", ".au", ".dev", ".app", ".me", ".info", ".biz", ".site", ".online", ".store", ".blog"]
	for ending in endings:
		if base.ends_with(ending):
			return true
	return false


func is_file_like_token(token: String) -> bool:
	var endings := [".txt", ".json", ".csv", ".pdf", ".docx", ".md", ".png", ".jpg", ".jpeg", ".gif", ".webp", ".mp3", ".wav", ".ogg", ".mp4", ".mov", ".exe", ".zip", ".html", ".gd"]
	for ending in endings:
		if token.ends_with(ending):
			return true
	return false


func sentence_closer_chars() -> String:
	return "\"')]}›»”’）］｝"


func token_trailing_chars() -> String:
	return ".!?,;:\"')]}›»”’）］｝"


func protect_regex_dots(text: String, pattern: String) -> String:
	var re := RegEx.new()
	re.compile(pattern)
	var matches := re.search_all(text)
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var start := m.get_start()
		var end := m.get_end()
		var segment := text.substr(start, end - start).replace(".", "__DOT__")
		text = text.substr(0, start) + segment + text.substr(end)
	return text


func restore_sentence_punctuation(text: String) -> String:
	return text.replace("__ELLIPSIS__", "...").replace("__DOT__", ".").replace("__QMARK__", "?").replace("__BANG__", "!")


func clean_sentence_text(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\s+")
	var cleaned := re.sub(text.strip_edges(), " ", true)
	cleaned = strip_leading_list_marker(cleaned)
	return cleaned


func strip_leading_list_marker(text: String) -> String:
	var re := RegEx.new()
	re.compile("^\\s*#{1,6}\\s+")
	var out := re.sub(text, "", false)
	re.compile("^\\s*(?:[-*+]+\\s+(?=[A-Za-z0-9\"'])|\\(?\\d+\\)\\s+)")
	return strip_leading_web_label(re.sub(out, "", false))


func strip_leading_web_label(text: String) -> String:
	var re := RegEx.new()
	re.compile("(?i)^\\s*(read more|continue reading|continued|advertisement|sponsored)\\s*:\\s+")
	var out := re.sub(text, "", false)
	var caption_re := RegEx.new()
	caption_re.compile("(?i)^\\s*(fig|figure|table|image|photo)\\.?\\s*\\d+[A-Za-z]?\\.?\\s+")
	return caption_re.sub(out, "", false).strip_edges()


func remove_story_artifacts(sentences: Array) -> Array:
	var out := []
	for sentence in sentences:
		var text := str(sentence).strip_edges()
		if text != "" and not is_story_artifact_sentence(text):
			out.append(text)
	return out


func is_story_artifact_sentence(sentence: String) -> bool:
	var text := sentence.strip_edges()
	if text == "":
		return true
	var page_re := RegEx.new()
	page_re.compile("(?i)^(page|p)\\s*\\d+\\.?$|^\\d+\\s*/\\s*\\d+\\.?$|^(fig|figure|table|image|photo)\\.?\\s*\\d+[A-Za-z]?\\.?$")
	if page_re.search(text) != null:
		return true
	var separator_re := RegEx.new()
	separator_re.compile("^(?:[-_*=\\s]{3,})$")
	if separator_re.search(text) != null:
		return true
	var label_re := RegEx.new()
	label_re.compile("(?i)^(advertisement|sponsored|continue reading|read more|by\\s+[A-Za-z][A-Za-z\\s.'-]{1,40})\\.?$")
	return label_re.search(text) != null


func append_story_sentence(sentences: Array, sentence: String) -> void:
	sentence = sentence.strip_edges()
	if sentence == "":
		return
	if is_sentence_prefix_fragment(sentence) and not sentences.is_empty():
		sentences[-1] = str(sentences[-1]) + " " + sentence
		return
	sentences.append(sentence)


func merge_sentence_fragments(sentences: Array) -> Array:
	var out := []
	for sentence in sentences:
		var text := str(sentence).strip_edges()
		if text == "":
			continue
		if out.is_empty():
			out.append(text)
			continue
		if should_merge_with_previous(text) or should_merge_heading_with_next(str(out[-1]), text) or should_merge_dialogue_attribution(str(out[-1]), text) or should_merge_unquoted_dialogue_attribution(str(out[-1]), text):
			out[-1] = str(out[-1]) + " " + text
		else:
			out.append(text)
	var cleaned := []
	for sentence in out:
		var text := str(sentence).strip_edges()
		if text != "":
			cleaned.append(text)
	return cleaned


func should_merge_with_previous(sentence: String) -> bool:
	var text := sentence.strip_edges()
	if is_sentence_prefix_fragment(text):
		return true
	return false


func should_merge_dialogue_attribution(previous: String, sentence: String) -> bool:
	var prev := previous.strip_edges()
	if not (prev.ends_with("\"") or prev.ends_with("'")):
		return false
	if not (prev.contains(".\"") or prev.contains("!\"") or prev.contains("?\"") or prev.contains(".'") or prev.contains("!'") or prev.contains("?'")):
		return false
	var text := sentence.strip_edges().trim_prefix("-").strip_edges()
	var lower := text.to_lower()
	if lower == "":
		return false
	var speech_verbs := ["said", "asked", "yelled", "shouted", "cried", "whispered", "replied", "called", "muttered", "answered", "continued", "laughed", "screamed", "warned", "ordered", "exclaimed", "sobbed", "growled", "sighed"]
	var words := lower.split(" ", false)
	for verb in speech_verbs:
		if words.size() >= 1 and str(words[0]).begins_with(verb):
			return true
		if words.size() >= 2 and str(words[1]).begins_with(verb):
			return true
		if words.size() >= 3 and str(words[2]).begins_with(verb):
			return true
	return false


func should_merge_unquoted_dialogue_attribution(previous: String, sentence: String) -> bool:
	var prev := previous.strip_edges()
	if not (prev.ends_with("!") or prev.ends_with("?")):
		return false
	if prev.ends_with("\"") or prev.ends_with("'"):
		return false
	var text := sentence.strip_edges().trim_prefix("-").strip_edges()
	var words := text.to_lower().split(" ", false)
	if words.size() < 2:
		return false
	if not ["he", "she", "they", "we", "i"].has(str(words[0])):
		return false
	var speech_verbs := ["said", "asked", "yelled", "shouted", "cried", "whispered", "replied", "called", "muttered", "answered", "continued", "laughed", "screamed", "warned", "ordered", "exclaimed", "sobbed", "growled", "sighed"]
	for verb in speech_verbs:
		if str(words[1]).begins_with(verb):
			return true
	return false


func should_merge_heading_with_next(previous: String, sentence: String) -> bool:
	var prev := previous.strip_edges()
	var text := sentence.strip_edges()
	return is_sentence_prefix_fragment(prev) and text != ""


func split_likely_abbreviation_boundaries(sentences: Array) -> Array:
	var contextual := ["Dept.", "Univ.", "No.", "Nos.", "Vol.", "Fig.", "Figs.", "Eq.", "Eqs.", "Ref.", "Refs.", "Inc.", "Ltd.", "Co.", "Corp.", "Ave.", "Blvd.", "Rd.", "Ln.", "Ct.", "Pl.", "Hwy.", "Apt.", "Ste.", "etc.", "a.m.", "p.m.", "ft.", "in.", "oz.", "lb.", "lbs.", "kg.", "cm.", "mm.", "Ph.D.", "Ed.D.", "M.D.", "D.D.", "J.D.", "S.J.D.", "B.C.", "A.D."]
	var out := []
	for sentence in sentences:
		var pending := str(sentence).strip_edges()
		while pending != "":
			var split_at := -1
			var split_len := 0
			for abbr in contextual:
				var abbr_text := str(abbr)
				var needle := abbr_text + " "
				var search_from := 0
				var pos := pending.find(needle, search_from)
				while pos >= 0:
					var next_index: int = pos + needle.length()
					if next_index < pending.length() and is_uppercase_sentence_start(pending.substr(next_index, 1)):
						split_at = pos
						split_len = abbr_text.length()
						break
					search_from = pos + needle.length()
					pos = pending.find(needle, search_from)
				if split_at >= 0:
					break
			if split_at < 0:
				var date_split := find_date_sentence_boundary(pending)
				if date_split >= 0:
					out.append(pending.substr(0, date_split + 1).strip_edges())
					pending = pending.substr(date_split + 1).strip_edges()
					continue
				var number_split := find_numeric_sentence_boundary(pending)
				if number_split >= 0:
					out.append(pending.substr(0, number_split + 1).strip_edges())
					pending = pending.substr(number_split + 1).strip_edges()
				else:
					out.append(pending)
					pending = ""
			else:
				out.append(pending.substr(0, split_at + split_len).strip_edges())
				pending = pending.substr(split_at + split_len).strip_edges()
	return out


func merge_title_fragments(sentences: Array) -> Array:
	var out := []
	for sentence in sentences:
		var text := str(sentence).strip_edges()
		if not out.is_empty() and is_title_intro_fragment(str(out[-1])):
			out[-1] = str(out[-1]) + " " + text
		else:
			out.append(text)
	return out


func is_title_intro_fragment(sentence: String) -> bool:
	var re := RegEx.new()
	re.compile("(?i)^(title|story|chapter|part|section|episode|book)\\s*[:\\-]\\s*[\"']?.*[.!?][\"']?$")
	return re.search(sentence.strip_edges()) != null


func split_after_title_intro_sentence(sentences: Array) -> Array:
	var out := []
	for sentence in sentences:
		var text := str(sentence).strip_edges()
		var split_index := find_second_sentence_boundary_after_title(text)
		if split_index >= 0:
			out.append(text.substr(0, split_index + 1).strip_edges())
			var rest := text.substr(split_index + 1).strip_edges()
			if rest != "":
				out.append(rest)
		else:
			out.append(text)
	return out


func find_second_sentence_boundary_after_title(text: String) -> int:
	var label_re := RegEx.new()
	label_re.compile("(?i)^(title|story|chapter|part|section|episode|book)\\s*[:\\-]")
	if label_re.search(text) == null:
		return -1
	var first := -1
	var i := 0
	while i < text.length():
		var ch := text.substr(i, 1)
		if ".!?".contains(ch):
			while i + 1 < text.length() and ".!?".contains(text.substr(i + 1, 1)):
				i += 1
			while i + 1 < text.length() and sentence_closer_chars().contains(text.substr(i + 1, 1)) and should_consume_sentence_closer(text, i + 1):
				i += 1
			if first < 0:
				first = i
			else:
				return i
		i += 1
	return -1


func find_date_sentence_boundary(text: String) -> int:
	var re := RegEx.new()
	re.compile("\\b(?:Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sept|Sep|Oct|Nov|Dec)\\.\\s+\\d{1,2}\\. ")
	for m in re.search_all(text):
		var next_index := m.get_end()
		if next_index < text.length() and is_uppercase_sentence_start(text.substr(next_index, 1)):
			var segment := m.get_string()
			return m.get_start() + segment.rfind(".")
	return -1


func find_numeric_sentence_boundary(text: String) -> int:
	var re := RegEx.new()
	re.compile("\\b\\d{2,}\\. ")
	for m in re.search_all(text):
		var next_index := m.get_end()
		if next_index < text.length() and is_uppercase_sentence_start(text.substr(next_index, 1)):
			var segment := m.get_string()
			return m.get_start() + segment.find(".")
	return -1


func is_uppercase_sentence_start(ch: String) -> bool:
	if ch == "":
		return false
	if "\"'([{".contains(ch):
		return true
	var upper := ch.to_upper()
	var lower := ch.to_lower()
	return ch == upper and ch != lower


func is_sentence_prefix_fragment(sentence: String) -> bool:
	var text := sentence.strip_edges()
	var lower := text.to_lower()
	if lower in ["prologue.", "epilogue.", "intro.", "introduction.", "preface.", "afterword."]:
		return true
	if is_all_caps_heading(text):
		return true
	var re := RegEx.new()
	re.compile("^(chapter|part|section|book|episode|act)\\s+(\\d+|[ivxlcdm]+)\\.$|^\\d+\\.$|^[a-zA-Z]\\.$")
	return re.search(lower) != null


func is_all_caps_heading(sentence: String) -> bool:
	var text := sentence.strip_edges()
	if not text.ends_with("."):
		return false
	var body := text.substr(0, text.length() - 1).strip_edges()
	if body.length() < 3 or body.length() > 40:
		return false
	var digit_re := RegEx.new()
	digit_re.compile("\\d")
	if digit_re.search(body) != null:
		return false
	var words := body.split(" ", false)
	if words.size() > 5:
		return false
	return body == body.to_upper() and body != body.to_lower()


func pick_words(sentence: String, max_words := DEFAULT_WORDS_PER_LEVEL, dynamic_words := true, cooldown := {}) -> Array:
	max_words = clampi(max_words, MIN_WORDS_PER_LEVEL, MAX_WORDS_PER_LEVEL)
	var re := RegEx.new()
	re.compile("[A-Za-z]+(?:['’][A-Za-z]+)?")
	var raw := []
	for m in re.search_all(sentence):
		var original := m.get_string()
		var word := normalize_story_word(original)
		if word.length() >= 3 and word.length() <= MAX_PICKED_WORD_LENGTH:
			raw.append({"word": word, "original": original})
	var seen := []
	var scored := []
	for item in raw:
		var w: String = item.word
		if not STOP_WORDS.has(w) and not BAD_WORDS.has(w) and not seen.has(w):
			seen.append(w)
			scored.append({"word": w, "score": word_quality_score(w, str(item.original), sentence, cooldown)})
	if seen.size() < max_words:
		for item in raw:
			var w: String = item.word
			if not BAD_WORDS.has(w) and not seen.has(w):
				seen.append(w)
				scored.append({"word": w, "score": word_quality_score(w, str(item.original), sentence, cooldown) - 25})
	scored.sort_custom(func(a, b): return int(a.score) > int(b.score) if int(a.score) != int(b.score) else str(a.word) < str(b.word))
	var out := []
	for item in scored:
		if dynamic_words and out.size() >= MIN_WORDS_PER_LEVEL and int(item.score) < 30:
			continue
		out.append(str(item.word))
		if out.size() >= max_words:
			break
	return out


func word_quality_score(word: String, original: String, sentence: String, cooldown := {}) -> int:
	var score := 0
	var length := word.length()
	if length >= 5 and length <= 8:
		score += 45
	elif length == 4:
		score += 25
	else:
		score += 10
	if original.length() > 0 and original.substr(0, 1) == original.substr(0, 1).to_upper():
		score += 16
	if word.ends_with("ing") or word.ends_with("ed"):
		score += 8
	if word.ends_with("ly"):
		score -= 8
	var vowels := 0
	for i in range(word.length()):
		if "aeiou".contains(word.substr(i, 1)):
			vowels += 1
	if vowels == 0 or vowels == word.length():
		score -= 30
	var frequency := 0
	var lower_sentence := sentence.to_lower().replace("'", "").replace("’", "")
	var cursor := lower_sentence.find(word)
	while cursor >= 0:
		frequency += 1
		cursor = lower_sentence.find(word, cursor + word.length())
	if frequency > 1:
		score += mini(18, frequency * 4)
	if cooldown.has(word):
		score -= 34 * int(cooldown[word])
	return score


func normalize_story_word(word: String) -> String:
	return word.to_lower().replace("'", "").replace("’", "")


func apply_word_cooldown(cooldown: Dictionary, words: Array) -> void:
	for key in cooldown.keys():
		cooldown[key] = int(cooldown[key]) - 1
		if int(cooldown[key]) <= 0:
			cooldown.erase(key)
	for word in words:
		cooldown[str(word)] = WORD_COOLDOWN_LEVELS


func generate_board(sentence: String, words: Array, index: int, story_name: String) -> Dictionary:
	words = unique_word_list(words)
	var max_len := 0
	for w in words:
		max_len = maxi(max_len, str(w).length())
	var size_value := clampi(maxi(10, max_len + 2), 10, 11)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(sentence + str(index)))
	var grid := []
	var entries := []
	for y in range(size_value):
		grid.append([])
		for _x in range(size_value):
			grid[y].append("")
	var sorted_words := words.duplicate()
	sorted_words.sort_custom(func(a, b): return str(a).length() > str(b).length())
	for word_text in sorted_words:
		var word := str(word_text)
		if entries.any(func(entry): return str(entry.text) == word):
			continue
		var placed := false
		for _attempt in range(500):
			var dir: Vector2i = dirs[rng.randi_range(0, dirs.size() - 1)]
			var sx := rng.randi_range(0, size_value - 1)
			var sy := rng.randi_range(0, size_value - 1)
			var ex := sx + dir.x * (word.length() - 1)
			var ey := sy + dir.y * (word.length() - 1)
			if ex < 0 or ey < 0 or ex >= size_value or ey >= size_value:
				continue
			var ok := true
			for i in range(word.length()):
				var gx := sx + dir.x * i
				var gy := sy + dir.y * i
				var existing := str(grid[gy][gx])
				if existing != "" and existing != word.substr(i, 1):
					ok = false
					break
			if ok:
				for i in range(word.length()):
					grid[sy + dir.y * i][sx + dir.x * i] = word.substr(i, 1)
				entries.append({"text": word, "x": sx, "y": sy, "dx": dir.x * (word.length() - 1), "dy": dir.y * (word.length() - 1)})
				placed = true
				break
		if not placed:
			continue
	var filler_letters := "abcdefghijklmnopqrstuvwxyz"
	var duplicate_free := false
	var last_filled := []
	for fill_attempt in range(60):
		var filled := []
		for y in range(size_value):
			filled.append([])
			for x in range(size_value):
				var existing := str(grid[y][x])
				if existing == "":
					filled[y].append(filler_letters.substr(rng.randi_range(0, filler_letters.length() - 1), 1))
				else:
					filled[y].append(existing)
		last_filled = filled
		if not has_extra_word_occurrences(filled, entries):
			grid = filled
			duplicate_free = true
			break
	if not duplicate_free:
		grid = last_filled
	return {"name": "%s-%d" % [story_slug(story_name), index], "number": index, "size": size_value, "letters": grid, "words": entries, "story": sentence}


func unique_word_list(words: Array) -> Array:
	var out := []
	for w in words:
		var word := str(w).to_lower()
		if word.length() <= MAX_PICKED_WORD_LENGTH and not out.has(word):
			out.append(word)
	return out


func has_extra_word_occurrences(grid: Array, entries: Array) -> bool:
	for entry in entries:
		var word := str(entry.text)
		if count_word_occurrences(grid, word) > 1:
			return true
	return false


func count_word_occurrences(grid: Array, word: String) -> int:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	var size_value := grid.size()
	var count := 0
	for y in range(size_value):
		for x in range(size_value):
			for dir in dirs:
				var ok := true
				for i in range(word.length()):
					var gx: int = x + dir.x * i
					var gy: int = y + dir.y * i
					if gx < 0 or gy < 0 or gx >= size_value or gy >= size_value or str(grid[gy][gx]) != word.substr(i, 1):
						ok = false
						break
				if ok:
					count += 1
	return count


func story_slug(story_name: String) -> String:
	var re := RegEx.new()
	re.compile("[^a-z0-9]+")
	var slug := re.sub(story_name.to_lower(), "-", true).strip_edges()
	while slug.begins_with("-"):
		slug = slug.substr(1)
	while slug.ends_with("-"):
		slug = slug.substr(0, slug.length() - 1)
	return slug if slug != "" else "story"


func load_audio() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)
	audio = {
		"ui_click": make_tone(520.0, 0.055, 0.18),
		"word_start": make_tone(420.0, 0.075, 0.15),
		"letter_submit": make_tone(650.0, 0.045, 0.12),
		"word_found": make_chime([660.0, 880.0, 990.0], 0.07, 0.17),
		"word_missed": make_chime([260.0, 220.0], 0.085, 0.13),
		"hint": make_chime([740.0, 980.0], 0.09, 0.13),
		"font": make_chime([500.0, 700.0], 0.06, 0.13),
		"palette": make_chime([540.0, 680.0, 810.0], 0.05, 0.13),
		"reader_open": make_chime([360.0, 480.0, 640.0], 0.075, 0.12),
		"reader_close": make_chime([640.0, 480.0, 360.0], 0.06, 0.1),
		"level_next": make_chime([560.0, 700.0, 930.0], 0.08, 0.15),
		"win": make_chime([523.25, 659.25, 783.99, 1046.5], 0.11, 0.15),
	}
	music_tracks = [
		make_melody([392.0, 440.0, 523.25, 587.33, 523.25, 440.0, 392.0, 329.63], 0.34, 0.045),
		make_melody([329.63, 392.0, 493.88, 587.33, 659.25, 587.33, 493.88, 392.0], 0.34, 0.04),
	]
	for i in range(8):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)


func set_audio_enabled(enabled: bool) -> void:
	if enabled == bool(state.get("volume", true)):
		return
	if enabled:
		state["volume"] = true
		play_music()
		play_sfx("ui_click")
	else:
		play_sfx("ui_click")
		state["volume"] = false
		if music_player:
			music_player.stop()


func play_sfx(key: String) -> void:
	if not bool(state.get("volume", true)) or not audio.has(key):
		return
	for player in sfx_players:
		if not player.playing:
			player.stream = audio[key]
			player.play()
			return


func play_music() -> void:
	if not bool(state.get("volume", true)) or music_tracks.is_empty():
		return
	music_player.stream = music_tracks[music_track_index % music_tracks.size()]
	music_track_index += 1
	music_player.play()


func _on_music_finished() -> void:
	if bool(state.get("volume", true)):
		play_music()


func make_tone(freq: float, duration: float, volume := 0.12) -> AudioStreamWAV:
	return make_chime([freq], duration, volume)


func make_chime(notes: Array, note_duration: float, volume := 0.12) -> AudioStreamWAV:
	var events := []
	for note in notes:
		events.append({"freq": float(note), "duration": note_duration})
	return make_wave_stream(events, volume)


func make_melody(notes: Array, note_duration: float, volume := 0.05) -> AudioStreamWAV:
	var events := []
	for note in notes:
		events.append({"freq": float(note), "duration": note_duration})
		events.append({"freq": 0.0, "duration": 0.03})
	return make_wave_stream(events, volume)


func make_wave_stream(events: Array, volume := 0.12) -> AudioStreamWAV:
	var sample_rate := 22050
	var data := PackedByteArray()
	var phase := 0.0
	for event in events:
		var freq := float(event.get("freq", 0.0))
		var duration := float(event.get("duration", 0.08))
		var sample_count := maxi(1, int(duration * sample_rate))
		for i in range(sample_count):
			var t := float(i) / float(sample_count)
			var envelope := minf(1.0, t / 0.08) * minf(1.0, (1.0 - t) / 0.18)
			var value := 0.0
			if freq > 0.0:
				phase += TAU * freq / float(sample_rate)
				value = sin(phase) * 0.78 + sin(phase * 2.0) * 0.12
			var sample := int(clampf(value * envelope * volume, -1.0, 1.0) * 32767.0)
			if sample < 0:
				sample = 65536 + sample
			data.append(sample & 0xff)
			data.append((sample >> 8) & 0xff)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
