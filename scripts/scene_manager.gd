extends Node

signal scene_changing(from_scene: Scene, to_scene: Scene)
signal scene_changed(scene: Scene)

enum Scene {NONE = -1, DEATHMATCH = 0} # Explicit "no scene" state

const SCENE_PATHS = {Scene.DEATHMATCH: "res://scenes/deathmatch_game.tscn"}

var current_scene: Scene = Scene.NONE # Now type-safe!
var _current_scene_node: Node = null
var scene_container: Node = null
var level_spawner: MultiplayerSpawner = null


func _ready():
	await get_tree().process_frame
	scene_container = get_node("/root/Multiplayer/SceneContainer")
	level_spawner = get_node("/root/Multiplayer/LevelSpawner")
	level_spawner.spawned.connect(_on_spawned)
	Lobby.server_closed.connect(reset_current)
	Lobby.player_joined.connect(_on_player_joined)


func change_scene(scene: Scene):
	_load_scene.call_deferred(scene)


func change_scene_multiplayer(scene: Scene):
	if not Lobby.is_host():
		push_error("Only host can change scenes!")
		return
	_load_scene.call_deferred(scene)


@rpc("authority", "call_local", "reliable")
func set_current_scene(scene: Scene):
	current_scene = scene


func _on_spawned(level: Node) -> void:
	MenuManager.hide_all_menus()


func _on_player_joined(peer_id: int, player_info: Dictionary):
	if !multiplayer.is_server():
		return
	set_current_scene.rpc_id(peer_id, current_scene)


func reset_current():
	current_scene = Scene.NONE
	_current_scene_node = null


func _load_scene(scene: Scene):
	var old_scene = current_scene

	# Remove current scene
	if _current_scene_node:
		scene_changing.emit(old_scene, scene)
		_current_scene_node.queue_free()
		await _current_scene_node.tree_exited

	# Load new scene
	var scene_path = SCENE_PATHS[scene]
	var new_scene = load(scene_path).instantiate()
	scene_container.add_child(new_scene, true)
	_current_scene_node = new_scene

	set_current_scene.rpc(scene)

	scene_changed.emit(scene)


func is_in_game() -> bool:
	return current_scene == Scene.DEATHMATCH


# Optional: Get current scene path if needed elsewhere
func get_current_scene_path() -> String:
	if current_scene == Scene.NONE:
		return ""
	return SCENE_PATHS.get(current_scene, "")
