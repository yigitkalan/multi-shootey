extends MenuBase

@onready var quit_button: Button = $Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	quit_button.pressed.connect(_on_quit_button_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if visible:
				MenuManager.hide_all_menus()
			elif SceneManager.is_in_game():
				MenuManager.show_menu(Globals.MenuName.PAUSE)

func _on_quit_button_pressed():
	Lobby.leave_lobby()
	MenuManager.show_menu(Globals.MenuName.MAIN)
