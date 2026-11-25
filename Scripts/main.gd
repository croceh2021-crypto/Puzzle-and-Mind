extends Control

const BG := Color("#07152d")
const PANEL := Color("#10294b")
const PANEL2 := Color("#17375f")
const GOLD := Color("#f2bd4b")
const CREAM := Color("#fff1cf")
const MUTED := Color("#a9bdd7")
const GREEN := Color("#39b879")
const RED := Color("#df6262")

var screen_stack: Array[String] = []
var coins := 0
var stars := 0
var current_puzzle: Dictionary = {}
var puzzle_index := 0
var current_level := 1
var hints_left := 3
var found_differences := 0
var level_unlocked := {"logic": 1, "spot": 1}
var save_path := "user://puzzle_mind_save.json"
var root: Control
var feedback_label: Label

func _ready() -> void:
    _load_progress()
    _show_home()

func _save_progress() -> void:
    var data = {"coins": coins, "stars": stars, "logic": level_unlocked.logic, "spot": level_unlocked.spot}
    var f = FileAccess.open(save_path, FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify(data))

func _load_progress() -> void:
    if not FileAccess.file_exists(save_path):
        return
    var f = FileAccess.open(save_path, FileAccess.READ)
    if not f:
        return
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        coins = int(parsed.get("coins", 0))
        stars = int(parsed.get("stars", 0))
        level_unlocked.logic = int(parsed.get("logic", 1))
        level_unlocked.spot = int(parsed.get("spot", 1))

func _clear() -> void:
    for child in get_children():
        child.queue_free()
    root = VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 14)
    add_child(root)
    var margin = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_bottom", 26)
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(margin)
    var body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 16)
    margin.add_child(body)
    root = body

func _label(text_value: String, size: int = 24, color: Color = CREAM, centered := true) -> Label:
    var l = Label.new()
    l.text = text_value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_RIGHT
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return l

func _button(text_value: String, callback: Callable, primary := false) -> Button:
    var b = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(0, 72)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 24)
    b.add_theme_color_override("font_color", CREAM)
    var normal = StyleBoxFlat.new()
    normal.bg_color = GOLD if primary else PANEL2
    normal.border_color = Color("#ffe29a") if primary else Color("#52749e")
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(18)
    normal.content_margin_left = 14
    normal.content_margin_right = 14
    b.add_theme_stylebox_override("normal", normal)
    var hover = normal.duplicate()
    hover.bg_color = Color("#d99d2e") if primary else Color("#214a79")
    b.add_theme_stylebox_override("hover", hover)
    b.pressed.connect(callback)
    return b

func _header(title_text: String) -> void:
    var row = HBoxContainer.new()
    root.add_child(row)
    var back = _button("‹", _go_back)
    back.custom_minimum_size.x = 64
    row.add_child(back)
    var title = _label(title_text, 28, GOLD)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(title)
    var spacer = Control.new()
    spacer.custom_minimum_size.x = 64
    row.add_child(spacer)

func _go_back() -> void:
    if screen_stack.is_empty():
        _show_home()
        return
    var previous = screen_stack.pop_back()
    match previous:
        "home": _show_home(false)
        "worlds": _show_worlds(false)
        "logic_levels": _show_levels("logic", false)
        "spot_levels": _show_levels("spot", false)
        _: _show_home()

func _push(screen: String) -> void:
    screen_stack.append(screen)

func _show_home(push := true) -> void:
    if push: screen_stack.clear()
    _clear()
    var hero_frame = PanelContainer.new()
    hero_frame.custom_minimum_size = Vector2(0, 330)
    hero_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var hero_style = StyleBoxFlat.new()
    hero_style.bg_color = PANEL
    hero_style.border_color = GOLD
    hero_style.set_border_width_all(2)
    hero_style.set_corner_radius_all(22)
    hero_frame.add_theme_stylebox_override("panel", hero_style)
    var hero_image = TextureRect.new()
    hero_image.texture = load("res://moh.png")
    hero_image.custom_minimum_size = Vector2(0, 310)
    hero_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    hero_frame.add_child(hero_image)
    root.add_child(hero_frame)
    root.add_child(_label("لغز وذكاء", 42, GOLD))
    root.add_child(_label("PUZZLE & MIND", 20, MUTED))
    root.add_child(_label("اكتشف .. فكّر .. حقق الفوز", 20))
    var gap = Control.new()
    gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(gap)
    root.add_child(_button("ابدأ اللعب", func(): _push("home"); _show_worlds(), true))
    root.add_child(_button("متابعة اللعب", func(): _push("home"); _show_worlds()))
    var row = HBoxContainer.new()
    root.add_child(row)
    row.add_child(_label("⭐ %d" % stars, 20, GOLD))
    row.add_child(_label("🪙 %d" % coins, 20, GOLD))
    root.add_child(_button("الإنجازات", _show_achievements))
    root.add_child(_button("الإعدادات", _show_settings))
    root.add_child(_label("نسخة تجريبية أولية • تعمل دون إنترنت", 14, MUTED))

func _show_worlds(push := true) -> void:
    if push: _push("worlds")
    _clear()
    _header("اختر العالم")
    root.add_child(_label("اختر نوع التحدي الذي ترغب في خوضه", 19, MUTED))
    root.add_child(_button("🧩  عالم الألغاز الذهنية\nمنطق • أرقام • ذاكرة • شفرات", func(): _show_levels("logic"), true))
    root.add_child(_button("🔎  عالم اكتشاف الاختلافات\nصور واقعية • ملاحظة • تركيز", func(): _show_levels("spot"), true))
    root.add_child(_label("تقدمك محفوظ بشكل مستقل في كل عالم", 16, MUTED))
    var spacer = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    root.add_child(_button("القائمة الرئيسية", _show_home))

func _show_levels(world: String, push := true) -> void:
    if push: _push("worlds")
    _clear()
    _header("مراحل الألغاز" if world == "logic" else "مراحل الاختلافات")
    root.add_child(_label("المراحل المفتوحة: %d" % int(level_unlocked[world]), 18, GOLD))
    var grid = GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    root.add_child(grid)
    for i in range(1, 26):
        var n = i
        var locked = n > int(level_unlocked[world])
        var b = _button("🔒" if locked else str(n), func(): _start_logic(n) if world == "logic" else _start_spot(n), not locked)
        b.custom_minimum_size = Vector2(0, 68)
        b.disabled = locked
        grid.add_child(b)
    var spacer = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    root.add_child(_button("العودة للعوالم", _show_worlds))

func _read_puzzles() -> Array:
    var f = FileAccess.open("res://Data/logic_puzzles.json", FileAccess.READ)
    if not f: return []
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if typeof(parsed) == TYPE_ARRAY else []

func _start_logic(level: int) -> void:
    var puzzles = _read_puzzles()
    if puzzles.is_empty():
        _show_message("تعذر تحميل الألغاز")
        return
    current_level = level
    puzzle_index = (level - 1) % puzzles.size()
    current_puzzle = puzzles[puzzle_index].duplicate(true)
    current_puzzle["id"] = level
    _show_logic()

func _show_logic() -> void:
    _clear()
    _header("لغز منطقي")
    root.add_child(_label("المرحلة %d  •  %s" % [int(current_puzzle.id), str(current_puzzle.difficulty)], 18, GOLD))
    root.add_child(_label(str(current_puzzle.question), 26))
    var card = PanelContainer.new()
    var style = StyleBoxFlat.new()
    style.bg_color = Color("#f2dfbd")
    style.set_corner_radius_all(18)
    style.content_margin_top = 30
    style.content_margin_bottom = 30
    card.add_theme_stylebox_override("panel", style)
    var visual = _label(str(current_puzzle.visual), 30, Color("#18243a"))
    card.add_child(visual)
    root.add_child(card)
    root.add_child(_label("اختر الإجابة الصحيحة", 18, MUTED))
    var answers = current_puzzle.answers
    for i in range(answers.size()):
        var index = i
        root.add_child(_button(str(answers[i]), func(): _check_logic(index)))
    root.add_child(_button("💡 تلميح (%d)" % hints_left, _show_hint))
    root.add_child(_button("خريطة المراحل", func(): _show_levels("logic", false)))

func _check_logic(choice: int) -> void:
    if choice == int(current_puzzle.correct):
        coins += 10
        stars += 1
        level_unlocked.logic = max(int(level_unlocked.logic), current_level + 1)
        _save_progress()
        _show_result(true, str(current_puzzle.explanation))
    else:
        _show_message("ليست الإجابة الصحيحة. حاول مرة أخرى!")

func _show_hint() -> void:
    if hints_left <= 0:
        _show_message("لا توجد تلميحات متبقية في هذه الجلسة.")
        return
    hints_left -= 1
    _show_message(str(current_puzzle.hint))

func _start_spot(level: int) -> void:
    current_level = level
    found_differences = 0
    _show_spot(level)

func _show_spot(level: int) -> void:
    _clear()
    _header("اكتشف الاختلافات")
    root.add_child(_label("المرحلة %d  •  اكتشف 3 اختلافات" % level, 19, GOLD))
    root.add_child(_label("نموذج تجريبي: اضغط على الدوائر الثلاث في الصورة", 16, MUTED))
    var scene = SpotPuzzle.new()
    scene.custom_minimum_size = Vector2(0, 470)
    scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scene.found.connect(_on_difference_found)
    root.add_child(scene)
    feedback_label = _label("الاختلافات: 0 / 3", 20, GOLD)
    root.add_child(feedback_label)
    root.add_child(_button("تلميح", func(): _show_message("ابحث عن العناصر المحاطة بعلامات خافتة.")))
    root.add_child(_button("خريطة المراحل", func(): _show_levels("spot", false)))

func _on_difference_found(total: int) -> void:
    found_differences = total
    if is_instance_valid(feedback_label):
        feedback_label.text = "الاختلافات: %d / 3" % total
    if total >= 3:
        coins += 10
        stars += 1
        level_unlocked.spot = max(int(level_unlocked.spot), current_level + 1)
        _save_progress()
        _show_result(true, "أحسنت! اكتشفت الاختلافات الثلاثة.")

func _show_result(won: bool, detail: String) -> void:
    _clear()
    root.add_child(_label("🏆" if won else "حاول مجدداً", 58, GOLD))
    root.add_child(_label("أحسنت! اكتملت المرحلة" if won else "لم تكتمل المرحلة", 28))
    root.add_child(_label(detail, 19, MUTED))
    root.add_child(_label("🪙 %d     ⭐ %d" % [coins, stars], 22, GOLD))
    root.add_child(_button("متابعة", _show_worlds, true))
    root.add_child(_button("القائمة الرئيسية", _show_home))

func _show_message(message: String) -> void:
    var dialog = AcceptDialog.new()
    dialog.dialog_text = message
    add_child(dialog)
    dialog.popup_centered()

func _show_achievements() -> void:
    _clear()
    _header("الإنجازات")
    root.add_child(_label("⭐ مجموع النجوم: %d" % stars, 25, GOLD))
    root.add_child(_label("🪙 مجموع العملات: %d" % coins, 25, GOLD))
    root.add_child(_label("إنجازات جديدة ستضاف مع توسعة المراحل.", 18, MUTED))
    root.add_child(_button("عودة", _show_home))

func _show_settings() -> void:
    _clear()
    _header("الإعدادات")
    root.add_child(_label("اللغة: العربية", 22))
    root.add_child(_label("الصوت: سيضاف التحكم به في النسخة التالية", 17, MUTED))
    root.add_child(_label("الصعوبة: تدرج تلقائي مع إمكانية الاختيار", 17, MUTED))
    root.add_child(_button("عودة", _show_home))


class SpotPuzzle:
    extends Control
    signal found(total: int)
    var hit := [false, false, false]
    var taps := 0

    func _ready() -> void:
        custom_minimum_size = Vector2(0, 460)
        mouse_filter = Control.MOUSE_FILTER_STOP

    func _draw() -> void:
        var w = size.x
        var half = w / 2.0 - 6
        var h = size.y
        draw_rect(Rect2(0, 0, half, h), Color("#d7c6a7"), true)
        draw_rect(Rect2(half + 12, 0, half, h), Color("#d7c6a7"), true)
        for side in range(2):
            var ox = 0.0 if side == 0 else half + 12
            draw_rect(Rect2(ox + 18, 20, half - 36, 130), Color("#91b6cb"))
            draw_rect(Rect2(ox + 18, 150, half - 36, 220), Color("#b79a78"))
            draw_rect(Rect2(ox + 38, 175, half - 76, 110), Color("#f0dfc3"))
            draw_circle(Vector2(ox + half * 0.5, 330), 44, Color("#78513d"))
            draw_rect(Rect2(ox + 28, 360, half - 56, 24), Color("#61412f"))
            draw_circle(Vector2(ox + half * 0.5, 95), 24, Color("#e8c46e"))
            draw_rect(Rect2(ox + 42, 190, 36, 60), Color("#427d58"))
            draw_rect(Rect2(ox + half - 78, 190, 36, 60), Color("#427d58"))
        # الاختلافات التجريبية: لون النافذة، النبات، والساعة
        draw_circle(Vector2(half + 12 + half * 0.5, 95), 24, Color("#e86e5c") if not hit[0] else Color("#e8c46e"))
        draw_rect(Rect2(half + 12 + 42, 190, 36, 60), Color("#d1a33c") if not hit[1] else Color("#427d58"))
        draw_circle(Vector2(half + 12 + half * 0.5, 330), 44, Color("#385c8a") if not hit[2] else Color("#78513d"))
        draw_line(Vector2(half + 12, 0), Vector2(half + 12, h), Color("#f4d18b"), 4)

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed:
            var half = size.x / 2.0 - 6
            if event.position.x < half:
                return
            var local = event.position - Vector2(half + 12, 0)
            var idx = -1
            if local.y < 140 and local.x > half * 0.30 and local.x < half * 0.70:
                idx = 0
            elif local.y > 180 and local.y < 270 and local.x < 100:
                idx = 1
            elif local.y > 285 and local.y < 380:
                idx = 2
            if idx >= 0 and not hit[idx]:
                hit[idx] = true
                queue_redraw()
                var total = 0
                for v in hit:
                    if v: total += 1
                found.emit(total)
