class_name PlayerScore
extends HBoxContainer


@export var player_name: String
@export var player_score: int

@onready var name_label: Label = $Name
@onready var score_label: Label = $Score


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name_label.text = player_name
	score_label.text = str(player_score)
