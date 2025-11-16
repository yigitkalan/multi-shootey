class_name PlayerStat
extends Resource

@export var movement_force: int
@export var stop_force: int
@export var max_velocity: int
@export var air_movement_coefficient: float
@export var jump_force: int:
	get: return -jump_force
