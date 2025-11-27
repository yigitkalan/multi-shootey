class_name DeathmatchMode
extends GameMode

var alive_players: Array[int] = []


func on_round_start() -> void:
	alive_players.clear()
	# Players will be added via on_player_spawned
	

func on_round_end() -> void:
	alive_players.clear()


# Custom method - called by player when they die
func on_player_eliminated(player_id: int) -> void:
	if not multiplayer.is_server():
		return
		
	alive_players.erase(player_id)
	data_updated.emit()
	
	# Check win condition
	if alive_players.size() <= 1:
		round_should_end.emit()


# Custom method - called when a player spawns
func on_player_spawned(player_id: int) -> void:
	if not alive_players.has(player_id):
		alive_players.append(player_id)
		data_updated.emit()


func get_winner_ids() -> Array[int]:
	# Return last player standing, or empty array if draw (everyone died)
	return alive_players.duplicate()


func get_mode_data() -> Dictionary:
	return {
		"mode_name": "Last Man Standing",
		"alive_count": alive_players.size(),
		"total_players": alive_players.size()
	}
