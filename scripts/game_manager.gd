extends Node


var current_state: Globals.GameState = Globals.GameState.LOBBY
var player_scores: Dictionary = {}
var alive_players: Array[int] = []
var round_number: int = 0
var max_rounds: int = 3

signal state_changed(new_state: Globals.GameState)
signal player_died(peer_id: int)
signal round_winner(peer_id: int)

func change_state(new_state: Globals.GameState):
	current_state = new_state
	state_changed.emit(new_state)
	_on_state_entered(new_state)

func kill_player(player_id: int):
	alive_players.erase(player_id)
	player_died.emit(player_id)
	if alive_players.size() == 1:
		var winner_id = alive_players[0]
		round_winner.emit(winner_id)
		player_scores[winner_id] += 1
		if player_scores[winner_id] >= max_rounds:
			change_state(Globals.GameState.GAME_OVER)
			return
		change_state(Globals.GameState.POST_ROUND)
		return
	
func add_player(player_id: int):
	alive_players.append(player_id)
	player_scores[player_id] = 0
		
	
func _on_state_entered(state: Globals.GameState):
	match state:
		Globals.GameState.PRE_ROUND:
			player_scores.clear()
			alive_players.clear()
			pass
		Globals.GameState.IN_ROUND:
			# _start_round()
			pass
		Globals.GameState.POST_ROUND:
			# _end_round()
			pass