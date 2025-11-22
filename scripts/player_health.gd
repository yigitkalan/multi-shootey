class_name PlayerHealth
extends Node2D


@export var health_stat: HealthStat

signal died
signal took_damage(left_percentage: float)

@export var current_health: int

func _ready() -> void:
	current_health = health_stat.max_health

func take_damage(amount: int):
	current_health = clamp(current_health-amount, 0, health_stat.max_health)
	took_damage.emit(float(current_health)/float(health_stat.max_health))
	if current_health == 0:
		die()
		
func die():
	died.emit()	
