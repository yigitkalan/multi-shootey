extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Object) -> void:
	if body is DeathmatchPlayer:
		body.player_health.die()
