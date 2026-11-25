extends SceneTree

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var packed := load("res://Main.tscn") as PackedScene
    if packed == null:
        push_error("Main.tscn could not be loaded.")
        quit(1)
        return

    var game := packed.instantiate()
    root.add_child(game)
    await process_frame

    for level in [1, 2]:
        game.call("_start_spot", level)
        await process_frame

        var puzzle: Control = null
        for node in game.find_children("*", "Control", true, false):
            if node.has_method("_photo_rect"):
                puzzle = node as Control
                break

        if puzzle == null:
            push_error("Photo difference control was not created for stage %d." % level)
            quit(1)
            return

        puzzle.size = Vector2(620, 500)
        await process_frame

        var photo := puzzle.get("photo") as Texture2D
        if photo == null:
            push_error("Stage %d image did not load." % level)
            quit(1)
            return

        var image_rect: Rect2 = puzzle.call("_photo_rect", 1)
        var points: Array = puzzle.get("difference_points")
        for point in points:
            var position := image_rect.position + Vector2(point.x * image_rect.size.x, point.y * image_rect.size.y)
            var tap := InputEventMouseButton.new()
            tap.button_index = MOUSE_BUTTON_LEFT
            tap.pressed = true
            tap.position = position
            puzzle.call("_gui_input", tap)

        if int(game.get("found_differences")) != 3:
            push_error("Stage %d did not register all three difference taps." % level)
            quit(1)
            return

    print("Photo difference smoke test passed for stages 1 and 2.")
    quit(0)
