extends Node

enum GameState {LOBBY, PRE_ROUND, IN_ROUND, POST_ROUND, GAME_OVER}

var current_state: GameState = GameState.LOBBY
var player_scores: Dictionary = {}
var alive_players: Array = []
var round_number: int = 0
var max_rounds: int = 3

signal state_changed(new_state: GameState)
signal player_died(peer_id: int)
signal round_winner(peer_id: int)

func change_state(new_state: GameState):
	current_state = new_state
	state_changed.emit(new_state)
	_on_state_entered(new_state)

func _on_state_entered(state: GameState):
	match state:
		GameState.PRE_ROUND:
			# _start_pre_round()
			pass
		GameState.IN_ROUND:
			# _start_round()
			pass
		GameState.POST_ROUND:
			# _end_round()
			pass