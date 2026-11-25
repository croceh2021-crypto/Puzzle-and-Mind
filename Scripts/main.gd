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
    var available_levels: int = _read_puzzles().size() if world == "logic" else 2
    root.add_child(_label("المراحل المفتوحة: %d" % int(level_unlocked[world]), 18, GOLD))
    root.add_child(_label("المراحل المتاحة حالياً: %d من 25" % available_levels, 15, MUTED))
    var grid = GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    root.add_child(grid)
    for i in range(1, 26):
        var n = i
        var locked = n > int(level_unlocked[world]) or n > available_levels
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
    if level < 1 or level > puzzles.size():
        _show_message("هذه المرحلة لم تُضف إلى محتوى اللعبة بعد.")
        return
    current_level = level
    puzzle_index = level - 1
    current_puzzle = puzzles[puzzle_index].duplicate(true)
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
    if level < 1 or level > 2:
        _show_message("هذه المرحلة قيد الإعداد، وستُفتح عند إضافة صورتها واختبار اختلافاتها.")
        return
    current_level = level
    found_differences = 0
    _show_spot(level)

func _show_spot(level: int) -> void:
    _clear()
    _header("اكتشف الاختلافات")
    root.add_child(_label("المرحلة %d  •  اكتشف 3 اختلافات" % level, 19, GOLD))
    root.add_child(_label("قارن الصورتين واضغط على مواضع الاختلاف في الصورة الثانية", 15, MUTED))
    var image_path := "res://IMG-20261028-WA0002.jpg"
    if level == 2:
        image_path = "res://IMG-20261028-WA0006.jpg"
    var scene = PhotoSpotPuzzle.new()
    scene.image_path = image_path
    scene.custom_minimum_size = Vector2(0, 500)
    scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scene.found.connect(_on_difference_found)
    root.add_child(scene)
    feedback_label = _label("الاختلافات: 0 / 3", 20, GOLD)
    root.add_child(feedback_label)
    root.add_child(_button("تلميح", func(): _show_message("انظر جيداً إلى الصورة الثانية وابحث عن ثلاثة تفاصيل تغيرت.")))
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
    root.add_child(_label("إنجازات النجوم", 20, GOLD))
    root.add_child(_label(("🏅 مبتدئ: %d / 1" % min(stars, 1)) + ("   ✓" if stars >= 1 else ""), 17))
    root.add_child(_label(("🥉 مجتهد: %d / 10" % min(stars, 10)) + ("   ✓" if stars >= 10 else ""), 17))
    root.add_child(_label(("🥈 خبير: %d / 25" % min(stars, 25)) + ("   ✓" if stars >= 25 else ""), 17))
    root.add_child(_label(("🥇 بطل الذكاء: %d / 50" % min(stars, 50)) + ("   ✓" if stars >= 50 else ""), 17))
    root.add_child(_label("تُحتسب النجوم عند إكمال المراحل بنجاح.", 15, MUTED))
    root.add_child(_button("عودة", _show_home))

func _show_settings() -> void:
    _clear()
    _header("الإعدادات")
    root.add_child(_label("اللغة: العربية", 22))
    root.add_child(_label("الصوت: سيضاف التحكم به في النسخة التالية", 17, MUTED))
    root.add_child(_label("الصعوبة: تدرج تلقائي مع إمكانية الاختيار", 17, MUTED))
    root.add_child(_button("عودة", _show_home))


class PhotoSpotPuzzle:
    extends Control
    signal found(total: int)

    var image_path := "res://IMG-20261028-WA0002.jpg"
    var photo: Texture2D
    var hit := [false, false, false]
    var difference_points := [
        Vector2(0.18, 0.68),
        Vector2(0.78, 0.56),
        Vector2(0.52, 0.86)
    ]

    func _ready() -> void:
        photo = load(image_path) as Texture2D
        custom_minimum_size = Vector2(0, 500)
        mouse_filter = Control.MOUSE_FILTER_STOP
        queue_redraw()

    func _photo_rect(slot: int) -> Rect2:
        var gap := 18.0
        var slot_height := (size.y - gap) / 2.0
        var box := Vector2(size.x, slot_height)
        if photo == null:
            return Rect2(0, slot * (slot_height + gap), box.x, box.y)
        var ratio := float(photo.get_width()) / float(photo.get_height())
        var draw_size := box
        if draw_size.x / draw_size.y > ratio:
            draw_size.x = draw_size.y * ratio
        else:
            draw_size.y = draw_size.x / ratio
        var origin := Vector2((size.x - draw_size.x) * 0.5, slot * (slot_height + gap) + (slot_height - draw_size.y) * 0.5)
        return Rect2(origin, draw_size)

    func _draw() -> void:
        var top_rect := _photo_rect(0)
        var bottom_rect := _photo_rect(1)
        draw_rect(Rect2(Vector2.ZERO, size), Color("#0a1c35"), true)
        if photo == null:
            draw_string(ThemeDB.fallback_font, Vector2(20, 50), "تعذر تحميل الصورة", HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 20, Color("#ffffff"))
            return
        draw_texture_rect(photo, top_rect, false)
        draw_texture_rect(photo, bottom_rect, false)
        draw_rect(top_rect, Color("#f2bd4b"), false, 3.0)
        draw_rect(bottom_rect, Color("#f2bd4b"), false, 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(12, 24), "الصورة الأولى", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#f2bd4b"))
        draw_string(ThemeDB.fallback_font, Vector2(12, bottom_rect.position.y + 24), "الصورة الثانية", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#f2bd4b"))
        # اختلافات مرئية صغيرة مضافة فوق نسخة الصورة الثانية؛ الأصل محفوظ كما هو.
        for i in range(difference_points.size()):
            if hit[i]:
                continue
            var p := bottom_rect.position + Vector2(difference_points[i].x * bottom_rect.size.x, difference_points[i].y * bottom_rect.size.y)
            match i:
                0:
                    draw_circle(p, 7.0, Color("#f4c542"))
                1:
                    draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), Color("#e65d55"), true)
                2:
                    draw_circle(p, 8.0, Color("#e9f0f7"))
                    draw_circle(p, 3.0, Color("#24466b"))

    func _gui_input(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            var bottom_rect := _photo_rect(1)
            if not bottom_rect.has_point(event.position):
                return
            var local: Vector2 = (event.position - bottom_rect.position) / bottom_rect.size
            var total := 0
            for i in range(difference_points.size()):
                if hit[i]:
                    total += 1
                    continue
                var target: Vector2 = difference_points[i] * bottom_rect.size
                if (local * bottom_rect.size).distance_to(target) <= max(22.0, bottom_rect.size.x * 0.055):
                    hit[i] = true
                    total += 1
            if total > 0:
                queue_redraw()
                found.emit(total)

