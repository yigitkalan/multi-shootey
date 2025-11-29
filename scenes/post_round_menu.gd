class_name PostRoundMenu
extends MenuBase


@onready var player_scores: VBoxContainer = $Background/MarginContainer/PlayerScores
@export var player_score_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func open():
	super ()
	if not is_multiplayer_authority():
		return
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
