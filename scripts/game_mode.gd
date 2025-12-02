class_name GameMode
extends Node


# === SIGNALS (How modes communicate) ===
signal round_should_end # Emitted when win condition met
signal data_updated # Emitted when UI data changes (scores, etc.)

# === REQUIRED QUERIES (Manager asks these) ===
func get_winner_ids() -> Array[int]:
    """Returns array of winning player IDs, or empty if draw"""
    return []

func get_mode_data() -> Dictionary:
    """Returns current mode state for UI/sync (e.g., scores, time, etc.)"""
    return {}


func get_round_score_updates() -> Dictionary:
    """Returns a dictionary of player_id: score_change for the current round"""
    return {}


# === LIFECYCLE HOOKS (Optional overrides) ===
func on_round_start() -> void: pass
func on_round_end() -> void: pass