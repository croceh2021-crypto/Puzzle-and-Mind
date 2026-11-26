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
var active_world := "logic"
var hints_left := 3
var found_differences := 0
var stage_completed := false
var room_challenge := ""
var room_answer := ""
var room_sequence_progress := 0
var room_completed := {}
var room_evidence := {}
var temple_unlocked := false
var temple_relics := {}
var temple_completed := false
var logic_completed := {}
var spot_completed := {}
var level_unlocked := {"logic": 1, "spot": 1}
var save_path := "user://puzzle_mind_save.json"
var root: Control
var feedback_label: Label
var music_enabled := true
var music_volume := 0.35
var music_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var music_sample_index := 0
const MUSIC_RATE := 22050
const MUSIC_STEP := 0.52
const MUSIC_MELODY := [523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 698.46, 523.25, 659.25, 783.99, 1046.5, 880.0, 783.99, 659.25, 587.33]

func _ready() -> void:
    _load_progress()
    _setup_music()
    _show_home()

func _setup_music() -> void:
    music_player = AudioStreamPlayer.new()
    var generator = AudioStreamGenerator.new()
    generator.mix_rate = MUSIC_RATE
    generator.buffer_length = 0.5
    music_player.stream = generator
    music_player.volume_db = linear_to_db(maxf(music_volume, 0.001)) if music_enabled else -80.0
    add_child(music_player)
    music_player.play()
    music_playback = music_player.get_stream_playback() as AudioStreamGeneratorPlayback
    set_process(true)

func _process(_delta: float) -> void:
    if music_playback == null or not music_enabled:
        return
    var frames := music_playback.get_frames_available()
    if frames <= 0:
        return
    var samples := PackedVector2Array()
    samples.resize(frames)
    for i in range(frames):
        var t := float(music_sample_index) / float(MUSIC_RATE)
        var step_index := int(floor(t / MUSIC_STEP)) % MUSIC_MELODY.size()
        var phase := fposmod(t, MUSIC_STEP) / MUSIC_STEP
        var note: float = float(MUSIC_MELODY[step_index])
        var bass_index: int = (int(step_index / 4) * 4) % MUSIC_MELODY.size()
        var bass: float = float(MUSIC_MELODY[bass_index]) * 0.25
        var attack := minf(phase * 9.0, 1.0)
        var release := 1.0 - smoothstep(0.68, 1.0, phase)
        var envelope := attack * release
        var melody := sin(TAU * note * t) * 0.52 + sin(TAU * note * 2.0 * t) * 0.10
        var harmony := sin(TAU * bass * t) * 0.20
        var shimmer := sin(TAU * note * 1.5 * t) * 0.035
        var sample := (melody + harmony + shimmer) * envelope * 0.13
        samples[i] = Vector2(sample, sample * 0.985)
        music_sample_index += 1
    music_playback.push_buffer(samples)

func _on_music_enabled_changed(enabled: bool) -> void:
    music_enabled = enabled
    if is_instance_valid(music_player):
        music_player.volume_db = linear_to_db(maxf(music_volume, 0.001)) if enabled else -80.0
    _save_progress()

func _on_music_volume_changed(value: float) -> void:
    music_volume = clampf(value / 100.0, 0.0, 1.0)
    if is_instance_valid(music_player) and music_enabled:
        music_player.volume_db = linear_to_db(maxf(music_volume, 0.001))
    _save_progress()

func _save_progress() -> void:
    var data = {"coins": coins, "stars": stars, "logic": level_unlocked.logic, "spot": level_unlocked.spot, "music_enabled": music_enabled, "music_volume": music_volume, "room_completed": room_completed, "room_evidence": room_evidence, "temple_unlocked": temple_unlocked, "temple_relics": temple_relics, "temple_completed": temple_completed, "logic_completed": logic_completed, "spot_completed": spot_completed}
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
        music_enabled = bool(parsed.get("music_enabled", true))
        music_volume = clampf(float(parsed.get("music_volume", 0.35)), 0.0, 1.0)
        temple_unlocked = bool(parsed.get("temple_unlocked", false))
        temple_completed = bool(parsed.get("temple_completed", false))
        var saved_logic_completed = parsed.get("logic_completed", {})
        logic_completed = saved_logic_completed if typeof(saved_logic_completed) == TYPE_DICTIONARY else {}
        var saved_spot_completed = parsed.get("spot_completed", {})
        spot_completed = saved_spot_completed if typeof(saved_spot_completed) == TYPE_DICTIONARY else {}
        var saved_room_completed = parsed.get("room_completed", {})
        room_completed = saved_room_completed if typeof(saved_room_completed) == TYPE_DICTIONARY else {}
        var saved_room_evidence = parsed.get("room_evidence", {})
        room_evidence = saved_room_evidence if typeof(saved_room_evidence) == TYPE_DICTIONARY else {}
        var saved_temple_relics = parsed.get("temple_relics", {})
        temple_relics = saved_temple_relics if typeof(saved_temple_relics) == TYPE_DICTIONARY else {}

func _clear() -> void:
    for child in get_children():
        if child != music_player:
            child.queue_free()
    var backdrop = ScreenBackdrop.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)
    root = VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 8)
    add_child(root)
    var margin = MarginContainer.new()
    var viewport_width := get_viewport_rect().size.x
    var side_margin := int(clampf(viewport_width * 0.045, 12.0, 28.0))
    margin.add_theme_constant_override("margin_left", side_margin)
    margin.add_theme_constant_override("margin_right", side_margin)
    margin.add_theme_constant_override("margin_top", 12)
    margin.add_theme_constant_override("margin_bottom", 12)
    margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.add_child(margin)
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(scroll)
    var body = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    scroll.add_child(body)
    root = body

func _label(text_value: String, size: int = 24, color: Color = CREAM, centered := true) -> Label:
    var l = Label.new()
    l.text = text_value
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_RIGHT
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var scale_factor := clampf(get_viewport_rect().size.x / 720.0, 0.78, 1.12)
    l.add_theme_font_size_override("font_size", maxi(14, int(round(float(size) * scale_factor))))
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return l

func _button(text_value: String, callback: Callable, primary := false) -> Button:
    var b = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.052, 52.0, 68.0))
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", int(clampf(get_viewport_rect().size.x * 0.033, 17.0, 23.0)))
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
    hover.border_color = Color("#fff0bd")
    b.add_theme_stylebox_override("hover", hover)
    var pressed = normal.duplicate()
    pressed.bg_color = Color("#bd8425") if primary else Color("#0b2341")
    b.add_theme_stylebox_override("pressed", pressed)
    var disabled = normal.duplicate()
    disabled.bg_color = Color("#26364b")
    disabled.border_color = Color("#3c4c60")
    b.add_theme_stylebox_override("disabled", disabled)
    b.add_theme_stylebox_override("focus", hover)
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
    root.add_child(_button("🧩  غرفة الألغاز الذهنية\nتحديات تفاعلية داخل الغرفة", func(): _show_puzzle_room(), true))
    root.add_child(_button("🔎  عالم اكتشاف الاختلافات\nصور واقعية • ملاحظة • تركيز", func(): _show_levels("spot"), true))
    root.add_child(_label("تقدمك محفوظ بشكل مستقل في كل عالم", 16, MUTED))
    var spacer = Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer)
    root.add_child(_button("القائمة الرئيسية", _show_home))

func _show_puzzle_room(push := true) -> void:
    if push: _push("worlds")
    _clear()
    _header("استكشاف قاعة الأسرار")
    root.add_child(_label("حرّك المستكشف بلمس الأرض، ثم المس الأثر عندما تقترب منه.", 16, MUTED))
    var explore_view := RoomExploreView.new()
    explore_view.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.43, 285.0, 390.0))
    explore_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    explore_view.evidence_state = room_evidence.duplicate(true)
    explore_view.completed_state = room_completed.duplicate(true)
    explore_view.chest_open = _room_evidence_count() == 4 and _room_completed_count() == 4
    explore_view.object_interacted.connect(_on_room_object_interacted)
    root.add_child(explore_view)
    root.add_child(_label("🕹️ المس مكاناً فارغاً للمشي. اقترب من المشعل أو الرقعة أو المرآة أو الحارس ثم المسه لفحصه.", 15, GOLD))
    root.add_child(_label("🧭 الأدلة المجموعة: %d / 4" % _room_evidence_count(), 17, MUTED))
    var stations := [
        ["🔢 قفل الأرقام", "code", "clue_code"],
        ["🧩 لوحة المتتاليات", "sequence", "clue_sequence"],
        ["🔮 ذاكرة الرموز", "memory", "clue_memory"],
        ["📜 لغز الحارس", "riddle", "clue_riddle"]
    ]
    for station in stations:
        var kind: String = station[1]
        var evidence_id: String = station[2]
        var done := bool(room_completed.get(kind, false))
        var unlocked := bool(room_evidence.get(evidence_id, false))
        var b := _button(("✓ " if done else ("🔓 " if unlocked else "🔒 ")) + str(station[0]), func(): _start_room_challenge(kind), not done and unlocked)
        b.disabled = done or not unlocked
        root.add_child(b)
    var completed_count := 0
    for station_kind in ["code", "sequence", "memory", "riddle"]:
        if bool(room_completed.get(station_kind, false)):
            completed_count += 1
    root.add_child(_label("تقدم القاعة: %d / 4     ⭐ %d     🪙 %d" % [completed_count, stars, coins], 17, GOLD))
    root.add_child(_label("🎁 صندوق الكنز مفتوح!" if completed_count == 4 else "🔒 افتح المحطات الأربع للوصول إلى صندوق الكنز.", 18, GOLD))
    root.add_child(_button("خريطة المراحل التقليدية", func(): _show_levels("logic"), false))
    root.add_child(_button("العودة للعوالم", _show_worlds))

func _on_room_object_interacted(object_id: String) -> void:
    var evidence := {
        "torch": ["clue_code", "نقش خلف المشعل: رمز القفل هو 6 ثم 3."],
        "scroll": ["clue_sequence", "الرقعة تقول: الفروق تزداد بمقدار 2 كل مرة."],
        "mirror": ["clue_memory", "انعكاس المرآة يريك الترتيب: 🌙 ثم ⭐ ثم 🔑."],
        "guardian": ["clue_riddle", "الحارس يهمس: ما الذي يكبر كلما أزلت منه؟"]
    }
    if object_id == "chest":
        if _room_evidence_count() == 4 and _room_completed_count() == 4:
            temple_unlocked = true
            _save_progress()
            _clear()
            _header("كنز قاعة الأسرار")
            var portal_fx := RoomRewardVisual.new()
            portal_fx.custom_minimum_size = Vector2(0, 190)
            root.add_child(portal_fx)
            root.add_child(_label("🏆 لقد فتحت صندوق الكنز!", 28, GOLD))
            root.add_child(_label("من بين الكنوز ظهر ممر مضيء يقود إلى المعبد القديم. مغامرتك لم تنتهِ بعد!", 20))
            root.add_child(_button("✨ الانتقال إلى المعبد القديم", _show_temple_room, true))
            root.add_child(_button("العودة إلى القاعة", _show_puzzle_room, false))
        else:
            _show_message("الصندوق مغلق. اجمع الأدلة الأربعة وافتح الأقفال أولاً.")
        return
    if not evidence.has(object_id):
        return
    var clue: Array = evidence[object_id]
    _discover_room_evidence(str(clue[0]), str(clue[1]))

func _show_temple_room(push := true) -> void:
    if not temple_unlocked:
        _show_message("افتح كنز قاعة الأسرار أولاً للوصول إلى المعبد القديم.")
        return
    if push: _push("worlds")
    _clear()
    _header("المعبد القديم")
    root.add_child(_label("منحوتات غامضة وثلاثة أختام تحرس بوابة المعبد.", 16, MUTED))
    var temple_view := TempleExploreView.new()
    temple_view.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.43, 285.0, 390.0))
    temple_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    temple_view.relic_state = temple_relics.duplicate(true)
    temple_view.gate_open = temple_completed
    temple_view.object_interacted.connect(_on_temple_object_interacted)
    root.add_child(temple_view)
    root.add_child(_label("المس الأرض للتحرك، واقترب من الأختام الثلاثة ثم افحص بوابة المعبد.", 15, GOLD))
    root.add_child(_label("الأختام المكتشفة: %d / 3" % _temple_relic_count(), 17, MUTED))
    root.add_child(_button("العودة إلى قاعة الأسرار", _show_puzzle_room, false))

func _temple_relic_count() -> int:
    var total := 0
    for key in ["sun", "moon", "eye"]:
        if bool(temple_relics.get(key, false)):
            total += 1
    return total

func _on_temple_object_interacted(object_id: String) -> void:
    if object_id == "gate":
        if _temple_relic_count() == 3:
            temple_completed = true
            _save_progress()
            _clear()
            _header("بوابة المعبد")
            var portal_fx := RoomRewardVisual.new()
            portal_fx.custom_minimum_size = Vector2(0, 210)
            root.add_child(portal_fx)
            root.add_child(_label("🌟 لقد فتحت بوابة المعبد القديم!", 27, GOLD))
            root.add_child(_label("حللت ألغاز الأختام الثلاثة وأيقظت البوابة. المنطقة الثانية مكتملة!", 19))
            root.add_child(_button("العودة إلى المعبد", _show_temple_room, true))
        else:
            _show_message("البوابة لا تستجيب. حل ألغاز أختام الشمس والقمر والعين أولاً.")
        return
    if not ["sun", "moon", "eye"].has(object_id):
        return
    if bool(temple_relics.get(object_id, false)):
        _show_message("هذا الختم محفوظ في سجل مغامرتك.")
        return
    _show_temple_trial(object_id)

func _show_temple_trial(relic_id: String) -> void:
    _clear()
    var title := ""
    var question := ""
    var options: Array[String] = []
    match relic_id:
        "sun":
            title = "لغز ختم الشمس"
            question = "تزداد الأعداد بمقدار 2:  2 ، 4 ، 6 ، ؟"
            options = ["7", "8", "9"]
        "moon":
            title = "لغز ختم القمر"
            question = "أي ترتيب يمثل تعاقب الليل ثم النهار ثم الليل؟"
            options = ["☾  ☀  ☾", "☀  ☀  ☾", "☾  ☾  ☀"]
        "eye":
            title = "لغز ختم العين"
            question = "شيء له عين واحدة ولا يرى، ما هو؟"
            options = ["المرآة", "الإبرة", "المصباح"]
    _header(title)
    root.add_child(_label("أجب إجابة صحيحة لتفعيل الختم الأثري.", 16, MUTED))
    root.add_child(_label(question, 23, GOLD))
    for option in options:
        var answer := option
        root.add_child(_button(answer, func(): _answer_temple_trial(relic_id, answer), true))
    root.add_child(_button("العودة إلى المعبد", _show_temple_room, false))

func _answer_temple_trial(relic_id: String, answer: String) -> void:
    var correct := ""
    var description := ""
    match relic_id:
        "sun":
            correct = "8"
            description = "ختم الشمس: اكتشفت أن النمط يزداد بمقدار اثنين."
        "moon":
            correct = "☾  ☀  ☾"
            description = "ختم القمر: عرفت ترتيب الليل والنهار."
        "eye":
            correct = "الإبرة"
            description = "ختم العين: عرفت أن عين الإبرة لا ترى."
    if answer != correct:
        _show_temple_trial_feedback(relic_id)
        return
    temple_relics[relic_id] = true
    _save_progress()
    _clear()
    _header("تفعيل الختم")
    var fx := RoomRewardVisual.new()
    fx.custom_minimum_size = Vector2(0, 150)
    root.add_child(fx)
    root.add_child(_label("✨ إجابة صحيحة! اكتسبت الختم.", 27, GOLD))
    root.add_child(_label(description, 20))
    root.add_child(_label("الأختام المكتشفة: %d / 3" % _temple_relic_count(), 17, MUTED))
    root.add_child(_button("متابعة استكشاف المعبد", _show_temple_room, true))

func _show_temple_trial_feedback(relic_id: String) -> void:
    _clear()
    _header("حاول مرة أخرى")
    root.add_child(_label("ليست هذه الإجابة الصحيحة. فكّر في اللغز وحاول مجدداً.", 21, GOLD))
    root.add_child(_button("إعادة المحاولة", func(): _show_temple_trial(relic_id), true))
    root.add_child(_button("العودة إلى المعبد", _show_temple_room, false))

func _room_completed_count() -> int:
    var total := 0
    for key in ["code", "sequence", "memory", "riddle"]:
        if bool(room_completed.get(key, false)):
            total += 1
    return total

func _room_evidence_count() -> int:
    var total := 0
    for key in ["clue_code", "clue_sequence", "clue_memory", "clue_riddle"]:
        if bool(room_evidence.get(key, false)):
            total += 1
    return total

func _discover_room_evidence(clue_id: String, description: String) -> void:
    if bool(room_evidence.get(clue_id, false)):
        _show_message("هذا الدليل محفوظ لديك بالفعل.")
        return
    room_evidence[clue_id] = true
    _save_progress()
    _clear()
    _header("اكتشاف دليل")
    var reward_fx := RoomRewardVisual.new()
    reward_fx.custom_minimum_size = Vector2(0, 150)
    root.add_child(reward_fx)
    root.add_child(_label("✨ عثرت على دليل مخفي!", 30, GOLD))
    root.add_child(_label(description, 22, CREAM))
    root.add_child(_label("أُضيف الدليل إلى سجل استكشافك وحُفظ تقدمك.", 16, MUTED))
    root.add_child(_button("متابعة الاستكشاف", _show_puzzle_room, true))

func _start_room_challenge(kind: String) -> void:
    room_challenge = kind
    room_answer = ""
    room_sequence_progress = 0
    _show_room_challenge()

func _show_room_challenge() -> void:
    _clear()
    _header("غرفة الألغاز")
    var clue_text := ""
    match room_challenge:
        "code": clue_text = "الدليل: الرمز 6 ثم 3."
        "sequence": clue_text = "الدليل: الفروق تزداد بمقدار 2."
        "memory": clue_text = "الدليل: 🌙 ثم ⭐ ثم 🔑."
        "riddle": clue_text = "الدليل: فكّر فيما يكبر عند إزالة جزء منه."
    root.add_child(_label(clue_text, 16, GOLD))
    match room_challenge:
        "code":
            root.add_child(_label("🔢 قفل الخزنة", 27, GOLD))
            root.add_child(_label("أنا عدد من رقمين. مجموع رقميّ 9، ورقم العشرات أكبر من الآحاد بثلاثة. ما الرمز؟", 19))
            root.add_child(_label("الرمز: " + room_answer, 24, GOLD))
            var grid := GridContainer.new()
            grid.columns = 3
            for digit in range(1, 10):
                var d := str(digit)
                grid.add_child(_button(d, func(): _room_key(d)))
            root.add_child(grid)
            root.add_child(_button("مسح", func(): room_answer = ""; _show_room_challenge()))
            root.add_child(_button("تحقق من الرمز", _check_room_code, true))
        "sequence":
            root.add_child(_label("🧩 لوحة المتتاليات", 27, GOLD))
            root.add_child(_label("ما العدد التالي؟", 21))
            root.add_child(_label("2   •   6   •   12   •   20   •   ؟", 30, GOLD))
            for option in ["26", "28", "30", "32"]:
                root.add_child(_button(option, func(): _finish_room_challenge(option == "30", "الفروق هي 4 ثم 6 ثم 8 ثم 10؛ لذلك العدد 30.")))
        "memory":
            root.add_child(_label("🔮 ذاكرة الرموز", 27, GOLD))
            root.add_child(_label("تذكّر الترتيب التالي ثم اضغط الرموز بالترتيب نفسه:", 18))
            root.add_child(_label("🌙  ⭐  🔑", 38, GOLD))
            root.add_child(_label("اختيارك: %d / 3" % room_sequence_progress, 19, MUTED))
            for symbol in ["🌙", "⭐", "🔑"]:
                root.add_child(_button(symbol, func(): _room_memory_pick(symbol)))
        "riddle":
            root.add_child(_label("📜 لغز الحارس", 27, GOLD))
            root.add_child(_label("شيء كلما أخذت منه كبر، فما هو؟", 21))
            for option in ["الحفرة", "العمر", "الظل", "الكتاب"]:
                root.add_child(_button(option, func(): _finish_room_challenge(option == "الحفرة", "كلما أزلت التراب من الحفرة اتسعت وكبرت.")))
    root.add_child(_button("العودة إلى قاعة التحديات", _show_puzzle_room))

func _room_key(digit: String) -> void:
    if room_answer.length() < 2:
        room_answer += digit
        _show_room_challenge()

func _check_room_code() -> void:
    _finish_room_challenge(room_answer == "63", "مجموع 6 و3 يساوي 9، والفرق بينهما 3.")

func _room_memory_pick(symbol: String) -> void:
    var expected := ["🌙", "⭐", "🔑"]
    if room_sequence_progress >= expected.size():
        return
    if symbol != expected[room_sequence_progress]:
        room_sequence_progress = 0
        _show_message("ليس هذا الترتيب. حاول تذكر الرموز من جديد.")
        _show_room_challenge()
        return
    room_sequence_progress += 1
    if room_sequence_progress == expected.size():
        _finish_room_challenge(true, "ذاكرتك ممتازة! رتبت الرموز الثلاثة بشكل صحيح.")
    else:
        _show_room_challenge()

func _finish_room_challenge(correct: bool, explanation: String) -> void:
    if not correct:
        _show_message("لم تُفتح المحطة بعد. حاول مرة أخرى!")
        return
    if bool(room_completed.get(room_challenge, false)):
        _show_puzzle_room(false)
        return
    room_completed[room_challenge] = true
    coins += 15
    stars += 1
    _save_progress()
    _clear()
    _header("تم حل اللغز!")
    root.add_child(_label("🏆", 64, GOLD))
    root.add_child(_label("أحسنت! فتحت المحطة", 27, GOLD))
    root.add_child(_label(explanation, 20))
    root.add_child(_label("مكافأتك: ⭐ نجمة واحدة و 🪙 15 عملة", 19, GOLD))
    root.add_child(_button("العودة إلى الغرفة", _show_puzzle_room, true))

func _show_levels(world: String, push := true) -> void:
    if push: _push("worlds")
    _clear()
    _header("مراحل الألغاز" if world == "logic" else "مراحل الاختلافات")
    var available_levels: int = _read_puzzles().size() if world == "logic" else 25
    root.add_child(_label("المراحل المفتوحة: %d" % int(level_unlocked[world]), 18, GOLD))
    root.add_child(_label("المراحل المتاحة حالياً: %d من 25" % available_levels, 15, MUTED))
    var grid = GridContainer.new()
    grid.columns = 5 if get_viewport_rect().size.x >= 850.0 else (4 if get_viewport_rect().size.x >= 560.0 else 3)
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
    active_world = "logic"
    stage_completed = false
    hints_left = 3
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
        stage_completed = true
        var completion_key := str(current_level)
        var first_completion := not bool(logic_completed.get(completion_key, false))
        if first_completion:
            logic_completed[completion_key] = true
            coins += 10
            stars += 1
        level_unlocked.logic = max(int(level_unlocked.logic), current_level + 1)
        _save_progress()
        var detail := str(current_puzzle.explanation)
        if first_completion:
            detail += "\nمكافأتك: 10 عملات ونجمة واحدة."
        else:
            detail += "\nهذه المرحلة مكتملة سابقاً؛ لم تُكرر المكافأة."
        _show_result(true, detail)
    else:
        _show_message("ليست الإجابة الصحيحة. حاول مرة أخرى!")

func _show_hint() -> void:
    if hints_left <= 0:
        _show_message("لا توجد تلميحات متبقية في هذه الجلسة.")
        return
    hints_left -= 1
    _show_message(str(current_puzzle.hint))

func _start_spot(level: int) -> void:
    active_world = "spot"
    hints_left = 3
    if level < 1 or level > 25:
        _show_message("هذه المرحلة غير متاحة حالياً.")
        return
    current_level = level
    found_differences = 0
    stage_completed = false
    _show_spot(level)

func _spot_stage_data(level: int) -> Dictionary:
    if level == 1:
        var file := FileAccess.open("res://Data/spot_stage_01.json", FileAccess.READ)
        if file:
            var parsed = JSON.parse_string(file.get_as_text())
            if typeof(parsed) == TYPE_DICTIONARY:
                var points: Array[Vector2] = []
                var radii: Array[float] = []
                for difference in parsed.get("differences", []):
                    var center: Array = difference.get("center", [0.5, 0.5])
                    points.append(Vector2(float(center[0]), float(center[1])))
                    radii.append(float(difference.get("radius", 0.035)))
                if points.size() == 7:
                    return {
                        "image_a": "res://Art/a_bright_high_detail_photorealistic_mountain_vil.png",
                        "image_b": "res://Art/PM_stage01_B_local.png",
                        "points": points,
                        "radii": radii
                    }
    var points := [
        Vector2(0.125, 0.310), Vector2(0.3125, 0.310),
        Vector2(0.500, 0.310), Vector2(0.6875, 0.310),
        Vector2(0.875, 0.310), Vector2(0.3125, 0.738),
        Vector2(0.6875, 0.738)
    ]
    return {
        "image_a": "res://Art/spot_%d_a.svg" % level,
        "image_b": "res://Art/spot_%d_b.svg" % level,
        "points": points,
        "radii": []
    }

func _show_spot(level: int) -> void:
    _clear()
    _header("اكتشف الاختلافات")
    root.add_child(_label("المرحلة %d  •  اكتشف 7 اختلافات" % level, 19, GOLD))
    root.add_child(_label("قارن الصورتين واضغط على مواضع الاختلاف في الصورة الثانية", 15, MUTED))
    var stage_data: Dictionary = _spot_stage_data(level)
    var scene = PhotoSpotPuzzle.new()
    scene.image_a_path = str(stage_data.image_a)
    scene.image_b_path = str(stage_data.image_b)
    scene.difference_points = stage_data.points
    scene.difference_radii = stage_data.radii
    scene.custom_minimum_size = Vector2(0, clampf(get_viewport_rect().size.y * 0.48, 330.0, 560.0))
    scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scene.found.connect(_on_difference_found)
    root.add_child(scene)
    feedback_label = _label("الاختلافات: 0 / 7", 20, GOLD)
    root.add_child(feedback_label)
    root.add_child(_button("تلميح", func(): _show_message("انظر جيداً إلى الصورة الثانية وابحث عن سبعة تفاصيل تغيرت.")))
    root.add_child(_button("خريطة المراحل", func(): _show_levels("spot", false)))

func _on_difference_found(total: int) -> void:
    found_differences = total
    if is_instance_valid(feedback_label):
        feedback_label.text = "الاختلافات: %d / 7" % total
    if total >= 7 and not stage_completed:
        stage_completed = true
        var completion_key := str(current_level)
        var first_completion := not bool(spot_completed.get(completion_key, false))
        if first_completion:
            spot_completed[completion_key] = true
            coins += 10
            stars += 1
        level_unlocked.spot = max(int(level_unlocked.spot), current_level + 1)
        _save_progress()
        var detail := "أحسنت! اكتشفت الاختلافات السبعة."
        if first_completion:
            detail += "\nمكافأتك: 10 عملات ونجمة واحدة."
        else:
            detail += "\nهذه المرحلة مكتملة سابقاً؛ لم تُكرر المكافأة."
        _show_result(true, detail)

func _show_result(won: bool, detail: String) -> void:
    _clear()
    var spacer_top = Control.new()
    spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer_top)
    var result_card = PanelContainer.new()
    var result_style = StyleBoxFlat.new()
    result_style.bg_color = Color("#102d4d")
    result_style.border_color = GOLD
    result_style.set_border_width_all(2)
    result_style.set_corner_radius_all(28)
    result_style.content_margin_left = 22
    result_style.content_margin_right = 22
    result_style.content_margin_top = 28
    result_style.content_margin_bottom = 28
    result_card.add_theme_stylebox_override("panel", result_style)
    var result_body = VBoxContainer.new()
    result_body.add_theme_constant_override("separation", 18)
    result_card.add_child(result_body)
    result_body.add_child(_label("🏆" if won else "حاول مجدداً", 58, GOLD))
    result_body.add_child(_label("أحسنت! اكتملت المرحلة" if won else "لم تكتمل المرحلة", 28))
    result_body.add_child(_label(detail, 19, MUTED))
    result_body.add_child(_label("🪙 %d     ⭐ %d" % [coins, stars], 22, GOLD))
    root.add_child(result_card)
    root.add_child(_label("سيتم نقلك تلقائياً إلى خريطة المراحل...", 16, MUTED))
    var spacer_bottom = Control.new()
    spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(spacer_bottom)
    if won:
        await get_tree().create_timer(1.8).timeout
        if is_inside_tree():
            _show_levels(active_world, false)
    else:
        root.add_child(_button("العودة للمراحل", func(): _show_levels(active_world, false), true))
        root.add_child(_button("القائمة الرئيسية", _show_home))

func _show_message(message: String) -> void:
    var dialog = AcceptDialog.new()
    dialog.dialog_text = message
    dialog.confirmed.connect(dialog.queue_free)
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
    root.add_child(_label("الموسيقى الخلفية", 22, GOLD))
    var music_toggle := CheckButton.new()
    music_toggle.text = "تشغيل الموسيقى"
    music_toggle.button_pressed = music_enabled
    music_toggle.add_theme_font_size_override("font_size", 20)
    music_toggle.toggled.connect(_on_music_enabled_changed)
    root.add_child(music_toggle)
    root.add_child(_label("مستوى الصوت: %d%%" % int(round(music_volume * 100.0)), 18, MUTED))
    var volume_slider := HSlider.new()
    volume_slider.min_value = 0
    volume_slider.max_value = 100
    volume_slider.step = 1
    volume_slider.value = music_volume * 100.0
    volume_slider.custom_minimum_size = Vector2(0, 54)
    volume_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    volume_slider.value_changed.connect(func(value: float):
        _on_music_volume_changed(value)
        var labels = root.find_children("*", "Label", true, false)
        for item in labels:
            if item is Label and item.text.begins_with("مستوى الصوت:"):
                item.text = "مستوى الصوت: %d%%" % int(round(value))
    )
    root.add_child(volume_slider)
    root.add_child(_label("يمكنك إيقاف الموسيقى أو خفضها في أي وقت.", 16, MUTED))
    root.add_child(_label("الصعوبة: تدرج تلقائي مع إمكانية الاختيار", 17, MUTED))
    root.add_child(_button("عودة", _show_home))


class PhotoSpotPuzzle:
    extends Control
    signal found(total: int)

    var image_a_path := "res://Art/spot_1_a.svg"
    var image_b_path := "res://Art/spot_1_b.svg"
    var photo_a: Texture2D
    var photo_b: Texture2D
    var hit: Array[bool] = []
    var difference_points: Array = []
    var difference_radii: Array = []

    func _ready() -> void:
        photo_a = load(image_a_path) as Texture2D
        photo_b = load(image_b_path) as Texture2D
        hit.clear()
        for i in range(difference_points.size()):
            hit.append(false)
        custom_minimum_size = Vector2(0, 500)
        mouse_filter = Control.MOUSE_FILTER_STOP
        queue_redraw()

    func _photo_rect(slot: int, photo: Texture2D) -> Rect2:
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
        var top_rect := _photo_rect(0, photo_a)
        var bottom_rect := _photo_rect(1, photo_b)
        draw_rect(Rect2(Vector2.ZERO, size), Color("#0a1c35"), true)
        if photo_a == null or photo_b == null:
            draw_string(ThemeDB.fallback_font, Vector2(20, 50), "تعذر تحميل صور المرحلة", HORIZONTAL_ALIGNMENT_CENTER, size.x - 40, 20, Color("#ffffff"))
            return
        draw_texture_rect(photo_a, top_rect, false)
        draw_texture_rect(photo_b, bottom_rect, false)
        draw_rect(top_rect, Color("#f2bd4b"), false, 3.0)
        draw_rect(bottom_rect, Color("#f2bd4b"), false, 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(12, 24), "الصورة الأولى", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#f2bd4b"))
        draw_string(ThemeDB.fallback_font, Vector2(12, bottom_rect.position.y + 24), "الصورة الثانية", HORIZONTAL_ALIGNMENT_LEFT, 180, 16, Color("#f2bd4b"))
        for i in range(difference_points.size()):
            if hit[i]:
                var p := bottom_rect.position + Vector2(difference_points[i].x * bottom_rect.size.x, difference_points[i].y * bottom_rect.size.y)
                draw_circle(p, 15.0, Color(0.25, 0.85, 0.55, 0.75))
                draw_circle(p, 8.0, Color("#ffffff"))

    func _gui_input(event: InputEvent) -> void:
        var touch_position := Vector2(-1.0, -1.0)
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            touch_position = event.position
        elif event is InputEventScreenTouch and event.pressed:
            touch_position = event.position
        else:
            return
        if photo_b == null:
            return
        var bottom_rect := _photo_rect(1, photo_b)
        if bottom_rect.size.x <= 0.0 or bottom_rect.size.y <= 0.0:
            return
        if not bottom_rect.has_point(touch_position):
            return
        var local: Vector2 = (touch_position - bottom_rect.position) / bottom_rect.size
        var total := 0
        for i in range(difference_points.size()):
            if hit[i]:
                total += 1
                continue
            var target: Vector2 = difference_points[i] * bottom_rect.size
            var radius := float(difference_radii[i]) if i < difference_radii.size() else 0.035
            if (local * bottom_rect.size).distance_to(target) <= maxf(16.0, bottom_rect.size.x * radius):
                hit[i] = true
                total += 1
        if total > 0:
            queue_redraw()
            found.emit(total)
        accept_event()


class ScreenBackdrop:
    extends Control

    func _notification(what: int) -> void:
        if what == NOTIFICATION_RESIZED:
            queue_redraw()

    func _draw() -> void:
        var h := maxf(size.y, 1.0)
        for i in range(32):
            var t := float(i) / 31.0
            var c := Color("#07152d").lerp(Color("#102c4b"), t * 0.72)
            draw_rect(Rect2(0, h * t, size.x, h / 32.0 + 2.0), c, true)
        draw_circle(Vector2(size.x * 0.88, size.y * 0.12), size.x * 0.30, Color(0.16, 0.36, 0.58, 0.12))
        draw_circle(Vector2(size.x * 0.08, size.y * 0.78), size.x * 0.24, Color(0.12, 0.52, 0.48, 0.09))
        for i in range(8):
            var x := size.x * (0.08 + float(i) * 0.12)
            draw_circle(Vector2(x, size.y * 0.08), 2.0 + float(i % 3), Color(0.95, 0.76, 0.35, 0.35))


class RoomHallVisual:
    extends Control

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        queue_redraw()

    func _notification(what: int) -> void:
        if what == NOTIFICATION_RESIZED:
            queue_redraw()

    func _draw() -> void:
        var w := size.x
        var h := size.y
        if w < 10.0 or h < 10.0:
            return
        # أرضية القاعة وجدرانها
        draw_rect(Rect2(Vector2.ZERO, size), Color("#081326"), true)
        draw_colored_polygon(PackedVector2Array([
            Vector2(w * 0.08, h * 0.10), Vector2(w * 0.92, h * 0.10),
            Vector2(w * 0.78, h * 0.72), Vector2(w * 0.22, h * 0.72)
        ]), Color("#17375a"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h * 0.12), Vector2(w * 0.08, h * 0.10),
            Vector2(w * 0.22, h * 0.72), Vector2(0, h)
        ]), Color("#102744"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(w, h * 0.12), Vector2(w * 0.92, h * 0.10),
            Vector2(w * 0.78, h * 0.72), Vector2(w, h)
        ]), Color("#102744"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h), Vector2(w, h), Vector2(w * 0.78, h * 0.72),
            Vector2(w * 0.22, h * 0.72)
        ]), Color("#142b45"))
        # خطوط بلاط المنظور
        for i in range(1, 5):
            var t := float(i) / 5.0
            var y := lerpf(h * 0.73, h * 0.98, t)
            draw_line(Vector2(w * (0.22 - t * 0.18), y), Vector2(w * (0.78 + t * 0.18), y), Color("#34506a"), 1.2)
        for i in range(1, 7):
            var x := float(i) / 7.0
            draw_line(Vector2(w * 0.5, h * 0.72), Vector2(w * x, h), Color("#34506a"), 1.0)
        # بوابة الكنز في منتصف الجدار الخلفي
        draw_rect(Rect2(w * 0.39, h * 0.20, w * 0.22, h * 0.48), Color("#07101e"), true)
        draw_rect(Rect2(w * 0.415, h * 0.24, w * 0.17, h * 0.44), Color("#6d4828"), true)
        draw_rect(Rect2(w * 0.435, h * 0.27, w * 0.13, h * 0.41), Color("#18283a"), true)
        draw_arc(Vector2(w * 0.50, h * 0.30), w * 0.065, PI, TAU, 32, Color("#d6a64c"), 4.0)
        draw_circle(Vector2(w * 0.545, h * 0.49), 4.0, Color("#f5cb69"))
        # أعمدة جانبية
        for side in [0.16, 0.84]:
            draw_rect(Rect2(w * (side - 0.025), h * 0.20, w * 0.05, h * 0.53), Color("#274866"), true)
            draw_rect(Rect2(w * (side - 0.04), h * 0.19, w * 0.08, h * 0.035), Color("#bd9652"), true)
            draw_rect(Rect2(w * (side - 0.04), h * 0.70, w * 0.08, h * 0.035), Color("#bd9652"), true)
        # مشاعل مضيئة
        for x in [w * 0.27, w * 0.73]:
            draw_line(Vector2(x, h * 0.35), Vector2(x, h * 0.47), Color("#9a7542"), 5.0)
            draw_circle(Vector2(x, h * 0.32), 13.0, Color(1.0, 0.60, 0.18, 0.13))
            draw_circle(Vector2(x, h * 0.32), 6.0, Color("#ffc65c"))
            draw_circle(Vector2(x - 2.0, h * 0.315), 2.0, Color("#fff0b0"))
        # أربع منصات ألغاز في مقدمة القاعة
        var centers := [Vector2(w * 0.19, h * 0.77), Vector2(w * 0.39, h * 0.84), Vector2(w * 0.61, h * 0.84), Vector2(w * 0.81, h * 0.77)]
        var symbols := ["9", "?", "◆", "✦"]
        for i in range(centers.size()):
            var p: Vector2 = centers[i]
            draw_colored_polygon(PackedVector2Array([
                p + Vector2(-w * 0.075, 0), p + Vector2(-w * 0.055, -h * 0.075),
                p + Vector2(w * 0.055, -h * 0.075), p + Vector2(w * 0.075, 0)
            ]), Color("#254a6a"))
            draw_rect(Rect2(p.x - w * 0.052, p.y - h * 0.075, w * 0.104, h * 0.035), Color("#c49a4e"), true)
            draw_circle(p + Vector2(0, -h * 0.045), minf(w * 0.025, 12.0), Color("#0a1b30"))
            draw_string(ThemeDB.fallback_font, p + Vector2(-8, -h * 0.035), symbols[i], HORIZONTAL_ALIGNMENT_CENTER, 16, 15, Color("#ffdc83"))
        # صندوق الكنز في المقدمة
        var chest := Rect2(w * 0.43, h * 0.89, w * 0.14, h * 0.075)
        draw_rect(chest, Color("#9b642d"), true)
        draw_rect(Rect2(chest.position.x, chest.position.y, chest.size.x, chest.size.y * 0.30), Color("#d3a14d"), true)
        draw_rect(Rect2(w * 0.485, h * 0.90, w * 0.03, h * 0.05), Color("#f5d16f"), true)
        draw_rect(Rect2(2, 2, w - 4, h - 4), Color("#d3ad65"), false, 2.0)

class RoomExploreView:
    extends Control

    signal object_interacted(object_id: String)

    var evidence_state: Dictionary = {}
    var completed_state: Dictionary = {}
    var chest_open := false
    var player := Vector2(0.50, 0.84)
    var destination := Vector2(0.50, 0.84)
    var pending_object := ""
    var move_speed := 0.72
    var walk_time := 0.0
    var facing := 1.0
    var hint_text := "المس الأرض للتحرك"
    var effect_timer := 0.0
    var effect_position := Vector2(0.5, 0.5)
    var effect_color := Color("#ffd36a")

    const OBJECTS := {
        "torch": Vector2(0.17, 0.43),
        "scroll": Vector2(0.39, 0.43),
        "mirror": Vector2(0.61, 0.43),
        "guardian": Vector2(0.83, 0.43),
        "chest": Vector2(0.50, 0.76)
    }

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        set_process(true)
        queue_redraw()

    func _process(delta: float) -> void:
        var difference := destination - player
        if difference.length() > 0.006:
            facing = signf(difference.x) if absf(difference.x) > 0.01 else facing
            player = player.move_toward(destination, move_speed * delta)
            walk_time += delta * 10.0
            if pending_object != "" and player.distance_to(_approach_point(pending_object)) <= 0.035:
                var reached := pending_object
                pending_object = ""
                hint_text = "وصلت إلى المكان، يجري فحصه..."
                _trigger_interaction(reached)
        else:
            walk_time = move_toward(walk_time, 0.0, delta * 8.0)
        if effect_timer > 0.0:
            effect_timer = maxf(0.0, effect_timer - delta)
        queue_redraw()

    func _approach_point(object_id: String) -> Vector2:
        var target: Vector2 = OBJECTS[object_id]
        return Vector2(target.x, minf(target.y + 0.13, 0.91))

    func _trigger_interaction(object_id: String) -> void:
        effect_position = OBJECTS[object_id]
        effect_color = Color("#ffd36a") if object_id != "chest" else Color("#ffe28a")
        effect_timer = 0.9
        object_interacted.emit(object_id)

    func _gui_input(event: InputEvent) -> void:
        var point := Vector2(-1, -1)
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            point = event.position
        elif event is InputEventScreenTouch and event.pressed:
            point = event.position
        if point.x < 0.0:
            return
        var local := Vector2(point.x / maxf(size.x, 1.0), point.y / maxf(size.y, 1.0))
        local.x = clampf(local.x, 0.04, 0.96)
        local.y = clampf(local.y, 0.16, 0.94)
        var nearest_id := ""
        var nearest_distance := 10.0
        for object_id in OBJECTS:
            var object_pos: Vector2 = OBJECTS[object_id]
            var distance := local.distance_to(object_pos)
            if distance < nearest_distance and distance < 0.105:
                nearest_id = str(object_id)
                nearest_distance = distance
        if nearest_id != "":
            if player.distance_to(OBJECTS[nearest_id]) <= 0.155:
                pending_object = ""
                _trigger_interaction(nearest_id)
                hint_text = "تفحص المكان..."
            else:
                pending_object = nearest_id
                destination = _approach_point(nearest_id)
                hint_text = "يتجه المستكشف إلى الأثر..."
        else:
            pending_object = ""
            destination = local
            hint_text = "تحرّك نحو الأثر ثم المسه لفحصه"
        queue_redraw()
        accept_event()

    func _draw() -> void:
        var w := size.x
        var h := size.y
        if w < 20.0 or h < 20.0:
            return
        draw_rect(Rect2(Vector2.ZERO, size), Color("#081326"), true)
        draw_colored_polygon(PackedVector2Array([
            Vector2(w * 0.08, h * 0.10), Vector2(w * 0.92, h * 0.10),
            Vector2(w * 0.78, h * 0.72), Vector2(w * 0.22, h * 0.72)
        ]), Color("#17375a"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h * 0.12), Vector2(w * 0.08, h * 0.10),
            Vector2(w * 0.22, h * 0.72), Vector2(0, h)
        ]), Color("#102744"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(w, h * 0.12), Vector2(w * 0.92, h * 0.10),
            Vector2(w * 0.78, h * 0.72), Vector2(w, h)
        ]), Color("#102744"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h), Vector2(w, h), Vector2(w * 0.78, h * 0.72),
            Vector2(w * 0.22, h * 0.72)
        ]), Color("#142b45"))
        for i in range(1, 6):
            var t := float(i) / 6.0
            var y := lerpf(h * 0.72, h * 0.98, t)
            draw_line(Vector2(w * (0.22 - t * 0.18), y), Vector2(w * (0.78 + t * 0.18), y), Color("#34506a"), 1.2)
        for i in range(1, 7):
            draw_line(Vector2(w * 0.5, h * 0.72), Vector2(w * float(i) / 7.0, h), Color("#34506a"), 1.0)
        draw_rect(Rect2(w * 0.39, h * 0.18, w * 0.22, h * 0.48), Color("#07101e"), true)
        draw_rect(Rect2(w * 0.415, h * 0.22, w * 0.17, h * 0.44), Color("#6d4828"), true)
        draw_arc(Vector2(w * 0.50, h * 0.27), w * 0.065, PI, TAU, 32, Color("#d6a64c"), 4.0)
        for side in [0.16, 0.84]:
            draw_rect(Rect2(w * (side - 0.025), h * 0.20, w * 0.05, h * 0.53), Color("#274866"), true)
        _draw_object("torch", "🔥", "المشعل", w, h)
        _draw_object("scroll", "📜", "الرقعة", w, h)
        _draw_object("mirror", "🪞", "المرآة", w, h)
        _draw_object("guardian", "🗿", "الحارس", w, h)
        _draw_object("chest", "🎁", "الصندوق", w, h)
        _draw_player(w, h)
        if effect_timer > 0.0:
            _draw_sparkles(effect_position * Vector2(w, h), effect_timer)
        draw_string(ThemeDB.fallback_font, Vector2(12, 23), hint_text, HORIZONTAL_ALIGNMENT_LEFT, w - 24, 14, Color("#fff1cf"))
        draw_rect(Rect2(2, 2, w - 4, h - 4), Color("#d3ad65"), false, 2.0)

    func _draw_player(w: float, h: float) -> void:
        var bob := sin(walk_time) * 3.0 if absf(destination.distance_to(player)) > 0.006 else sin(Time.get_ticks_msec() / 360.0) * 1.2
        var center := Vector2(player.x * w, player.y * h + bob)
        var swing := sin(walk_time) * 8.0
        var skin := Color("#f0bd8c")
        var coat := Color("#d49a3d")
        draw_circle(center + Vector2(0, 16), 8, Color(0, 0, 0, 0.35))
        draw_line(center + Vector2(-4, 8), center + Vector2(-6 + swing * 0.45, 23), Color("#263b58"), 5.0)
        draw_line(center + Vector2(4, 8), center + Vector2(6 - swing * 0.45, 23), Color("#263b58"), 5.0)
        draw_line(center + Vector2(-5, -2), center + Vector2(-10 - swing * 0.55, 9), skin, 4.0)
        draw_line(center + Vector2(5, -2), center + Vector2(10 + swing * 0.55, 9), skin, 4.0)
        draw_colored_polygon(PackedVector2Array([
            center + Vector2(-8, -7), center + Vector2(8, -7),
            center + Vector2(7, 10), center + Vector2(-7, 10)
        ]), coat)
        draw_circle(center + Vector2(0, -15), 7, skin)
        draw_arc(center + Vector2(0, -15), 7, PI, TAU, 16, Color("#4b3028"), 3.0)
        var eye_x := 2.5 * facing
        draw_circle(center + Vector2(eye_x, -16), 1.1, Color("#17243a"))

    func _draw_sparkles(center: Vector2, remaining: float) -> void:
        var progress := 1.0 - remaining / 0.9
        for i in range(10):
            var angle := TAU * float(i) / 10.0
            var radius := 12.0 + progress * 30.0
            var p := center + Vector2(cos(angle), sin(angle)) * radius
            var alpha := clampf(remaining / 0.9, 0.0, 1.0)
            draw_circle(p, 2.0 + alpha * 1.5, Color(effect_color.r, effect_color.g, effect_color.b, alpha))

    func _draw_object(object_id: String, symbol: String, caption: String, w: float, h: float) -> void:
        var p: Vector2 = OBJECTS[object_id]
        var center := Vector2(p.x * w, p.y * h)
        var clue_key := str({"torch":"clue_code", "scroll":"clue_sequence", "mirror":"clue_memory", "guardian":"clue_riddle"}.get(object_id, ""))
        var station_key := str({"torch":"code", "scroll":"sequence", "mirror":"memory", "guardian":"riddle"}.get(object_id, ""))
        var found := bool(evidence_state.get(clue_key, false))
        var done := bool(completed_state.get(station_key, false))
        var glow := Color("#39b879") if found or done else Color("#f2bd4b")
        draw_circle(center, 24, Color(glow.r, glow.g, glow.b, 0.18))
        draw_circle(center, 17, Color("#10294b"))
        draw_arc(center, 19, 0, TAU, 28, glow, 2.0)
        draw_string(ThemeDB.fallback_font, center + Vector2(-12, 6), symbol, HORIZONTAL_ALIGNMENT_LEFT, 28, 19, Color("#fff1cf"))
        draw_string(ThemeDB.fallback_font, center + Vector2(-35, 37), caption + (" ✓" if found or done else ""), HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color("#fff1cf"))
        if object_id == "chest":
            if chest_open:
                draw_rect(Rect2(center.x - 18, center.y - 2, 36, 15), Color("#b87932"), true)
                draw_colored_polygon(PackedVector2Array([center + Vector2(-18, -7), center + Vector2(-13, -20), center + Vector2(18, -20), center + Vector2(18, -7)]), Color("#e5b653"))
                draw_circle(center + Vector2(0, -13), 22, Color(1.0, 0.78, 0.25, 0.15))
            else:
                draw_rect(Rect2(center.x - 18, center.y - 8, 36, 20), Color("#9b642d"), true)
                draw_rect(Rect2(center.x - 18, center.y - 8, 36, 7), Color("#d3a14d"), true)

class TempleExploreView:
    extends Control

    signal object_interacted(object_id: String)

    var relic_state: Dictionary = {}
    var gate_open := false
    var player := Vector2(0.50, 0.86)
    var destination := Vector2(0.50, 0.86)
    var pending_object := ""
    var walk_time := 0.0
    var facing := 1.0
    var hint := "المس الأرض للتحرك"
    var pulse := 0.0

    const OBJECTS := {
        "sun": Vector2(0.20, 0.46),
        "moon": Vector2(0.50, 0.38),
        "eye": Vector2(0.80, 0.46),
        "gate": Vector2(0.50, 0.72)
    }

    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_STOP
        set_process(true)
        queue_redraw()

    func _process(delta: float) -> void:
        var diff := destination - player
        if diff.length() > 0.006:
            if absf(diff.x) > 0.01:
                facing = signf(diff.x)
            player = player.move_toward(destination, 0.72 * delta)
            walk_time += delta * 10.0
            if pending_object != "" and player.distance_to(_approach(pending_object)) <= 0.035:
                var reached := pending_object
                pending_object = ""
                object_interacted.emit(reached)
        else:
            walk_time = move_toward(walk_time, 0.0, delta * 8.0)
        pulse += delta
        queue_redraw()

    func _approach(id: String) -> Vector2:
        var p: Vector2 = OBJECTS[id]
        return Vector2(p.x, minf(p.y + 0.13, 0.92))

    func _gui_input(event: InputEvent) -> void:
        var point := Vector2(-1, -1)
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            point = event.position
        elif event is InputEventScreenTouch and event.pressed:
            point = event.position
        if point.x < 0.0:
            return
        var local := Vector2(clampf(point.x / maxf(size.x, 1.0), 0.04, 0.96), clampf(point.y / maxf(size.y, 1.0), 0.15, 0.95))
        var nearest := ""
        var nearest_d := 10.0
        for id in OBJECTS:
            var d := local.distance_to(OBJECTS[id])
            if d < nearest_d and d < 0.11:
                nearest = str(id)
                nearest_d = d
        if nearest != "":
            if player.distance_to(OBJECTS[nearest]) <= 0.16:
                pending_object = ""
                object_interacted.emit(nearest)
            else:
                pending_object = nearest
                destination = _approach(nearest)
                hint = "يتجه المستكشف إلى النقش..."
        else:
            pending_object = ""
            destination = local
            hint = "تحرّك نحو النقش أو البوابة"
        queue_redraw()
        accept_event()

    func _draw() -> void:
        var w := size.x
        var h := size.y
        if w < 20.0 or h < 20.0:
            return
        draw_rect(Rect2(Vector2.ZERO, size), Color("#100d20"), true)
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h * 0.12), Vector2(w, h * 0.12),
            Vector2(w * 0.82, h * 0.72), Vector2(w * 0.18, h * 0.72)
        ]), Color("#392b48"))
        draw_colored_polygon(PackedVector2Array([
            Vector2(0, h), Vector2(w, h), Vector2(w * 0.82, h * 0.72), Vector2(w * 0.18, h * 0.72)
        ]), Color("#241d35"))
        for i in range(7):
            var x := w * (0.08 + float(i) * 0.14)
            draw_rect(Rect2(x, h * 0.14, w * 0.035, h * 0.52), Color("#59415a"), true)
            draw_line(Vector2(x, h * 0.14), Vector2(x + w * 0.018, h * 0.10), Color("#b58a63"), 3.0)
        for i in range(1, 6):
            var t := float(i) / 6.0
            draw_line(Vector2(w * (0.18 - t * 0.18), h * (0.72 + t * 0.27)), Vector2(w * (0.82 + t * 0.18), h * (0.72 + t * 0.27)), Color("#59415a"), 1.2)
        var gate_center := Vector2(w * 0.50, h * 0.72)
        draw_rect(Rect2(w * 0.39, h * 0.18, w * 0.22, h * 0.54), Color("#171222"), true)
        draw_arc(Vector2(w * 0.50, h * 0.29), w * 0.11, PI, TAU, 40, Color("#bd8c54"), 5.0)
        draw_arc(gate_center, 35.0 + sin(pulse * 2.0) * 4.0, 0, TAU, 40, Color("#e7b85c") if gate_open else Color("#77628c"), 3.0)
        if gate_open:
            draw_rect(Rect2(w * 0.425, h * 0.28, w * 0.15, h * 0.42), Color(0.35, 0.72, 0.95, 0.25), true)
        _draw_relic("sun", "☀", "الشمس", w, h)
        _draw_relic("moon", "☾", "القمر", w, h)
        _draw_relic("eye", "◉", "العين", w, h)
        _draw_relic("gate", "🚪", "البوابة", w, h)
        var c := Vector2(player.x * w, player.y * h + sin(walk_time) * 2.0)
        draw_circle(c + Vector2(0, 15), 9, Color(0, 0, 0, 0.35))
        draw_line(c + Vector2(-4, 7), c + Vector2(-6 + sin(walk_time) * 4, 22), Color("#263b58"), 5.0)
        draw_line(c + Vector2(4, 7), c + Vector2(6 - sin(walk_time) * 4, 22), Color("#263b58"), 5.0)
        draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -7), c + Vector2(8, -7), c + Vector2(7, 10), c + Vector2(-7, 10)]), Color("#b58b58"))
        draw_circle(c + Vector2(0, -15), 7, Color("#edbd8c"))
        draw_arc(c + Vector2(0, -15), 7, PI, TAU, 16, Color("#37263b"), 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(12, 23), hint, HORIZONTAL_ALIGNMENT_LEFT, w - 24, 14, Color("#fff1cf"))
        draw_rect(Rect2(2, 2, w - 4, h - 4), Color("#a77a56"), false, 2.0)

    func _draw_relic(id: String, symbol: String, label: String, w: float, h: float) -> void:
        var p: Vector2 = OBJECTS[id]
        var center := Vector2(p.x * w, p.y * h)
        var found := bool(relic_state.get(id, false))
        var color := Color("#4dd49b") if found else Color("#e6b65c")
        draw_circle(center, 25.0 + sin(pulse * 2.0) * 2.0, Color(color.r, color.g, color.b, 0.15))
        draw_circle(center, 17, Color("#261d37"))
        draw_arc(center, 20, 0, TAU, 28, color, 2.0)
        draw_string(ThemeDB.fallback_font, center + Vector2(-12, 7), symbol, HORIZONTAL_ALIGNMENT_LEFT, 28, 21, Color("#fff1cf"))
        draw_string(ThemeDB.fallback_font, center + Vector2(-32, 39), label + (" ✓" if found else ""), HORIZONTAL_ALIGNMENT_CENTER, 64, 12, Color("#fff1cf"))

class RoomRewardVisual:
    extends Control

    var elapsed := 0.0

    func _ready() -> void:
        set_process(true)
        queue_redraw()

    func _process(delta: float) -> void:
        elapsed += delta
        queue_redraw()

    func _draw() -> void:
        var center := size * 0.5
        draw_circle(center, 42.0 + sin(elapsed * 3.0) * 5.0, Color(1.0, 0.76, 0.25, 0.10))
        for i in range(16):
            var angle := TAU * float(i) / 16.0 + elapsed * 0.45
            var radius := 18.0 + fposmod(elapsed * 28.0 + float(i) * 7.0, 48.0)
            var point := center + Vector2(cos(angle), sin(angle)) * radius
            var alpha := 0.45 + 0.45 * absf(sin(elapsed * 2.0 + float(i)))
            draw_circle(point, 2.0 + absf(sin(elapsed + float(i))) * 2.0, Color(1.0, 0.82, 0.42, alpha))

