extends Node2D

const PLAYER_SCENE := preload("uid://b2xyd22qyvitu")
@onready var spawn_points: Array = $SpawnPoints.get_children()
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
# Mode is now created dynamically
var game_mode: DeathmatchMode

var spawned_players := {}


func _ready() -> void:
	await get_tree().process_frame
	
	# Create and setup mode
	# We create it on all peers so they have the local instance to query state from
	# In a real networked scenario, we might want to spawn this via MultiplayerSpawner
	# if we want to sync its state automatically, but for now we mirror the previous
	# behavior where the node existed on all clients.
	game_mode = DeathmatchMode.new()
	game_mode.name = "DeathmatchMode"
	add_child(game_mode)
	
	GameManager.set_active_mode(game_mode)
	
	# Connect signals
	Lobby.player_joined.connect(_on_lobby_player_joined)
	Lobby.player_left.connect(_on_lobby_player_left)
	
	if Lobby.is_host():
		spawn_existing_players()

func spawn_existing_players() -> void:
	for peer_id in Lobby.players.keys():
		spawn_player_for_peer(peer_id)


func _on_lobby_player_joined(peer_id: int, _player_info: Dictionary) -> void:
	if (
		not Lobby.is_host()
		or (
			GameManager.current_state != Globals.GameState.IN_ROUND
			and GameManager.current_state != Globals.GameState.PRE_ROUND
		)
		):
		return
	# Initialize player score
	GameManager.init_player_score(peer_id)
	await get_tree().create_timer(0.5).timeout
	if not spawned_players.has(peer_id):
		spawn_player_for_peer(peer_id)


func _on_lobby_player_left(peer_id: int, _player_info: Dictionary) -> void:
	if not Lobby.is_host():
		return
	if spawned_players.has(peer_id):
		var player_node = spawned_players[peer_id]
		if is_instance_valid(player_node):
			player_node.queue_free()
		spawned_players.erase(peer_id)
		
		# Notify mode that player left
		if game_mode and game_mode.has_method("on_player_eliminated"):
			game_mode.on_player_eliminated(peer_id)


func spawn_player_for_peer(peer_id: int) -> void:
	if not Lobby.is_host():
		return
	if spawned_players.has(peer_id):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id) # Name should be the peer_id as string

	# Set position
	var spawn_index = spawned_players.size() % spawn_points.size()
	player.global_position = spawn_points[spawn_index].global_position

	# CRITICAL: Use an exported property to set the peer_id
	# This will be synchronized via the MultiplayerSynchronizer's "Spawn" properties
	player.player_id = peer_id # Or whatever your exported property is called

	# Add to tree
	$Players.add_child(player, true)

	spawned_players[peer_id] = player

	# Initialize player score
	GameManager.init_player_score(peer_id)
	
	# Notify mode that player spawned
	if game_mode and game_mode.has_method("on_player_spawned"):
		game_mode.on_player_spawned(peer_id)
