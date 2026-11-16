
extends Node2D

@export var spark_count: int = 8
@export var spark_speed_min: float = 90.0
@export var spark_speed_max: float = 180.0
@export var gravity: float = 350.0
@export var spark_lifetime: float = 0.45
@export var trail_length: int = 9
@export var trail_spacing: float = 0.025

var sparks: Array[Dictionary] = []
var emission_timer: float = 0.0


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	emission_timer -= delta

	if emission_timer <= 0.0:
		_emit_burst()
		emission_timer = randf_range(1.5, 4.0)

	for i in range(sparks.size() - 1, -1, -1):
		var spark: Dictionary = sparks[i]

		spark["age"] += delta
		spark["velocity"] += Vector2(0.0, gravity) * delta
		spark["position"] += spark["velocity"] * delta

		spark["trail_timer"] += delta

		if spark["trail_timer"] >= trail_spacing:
			spark["trail_timer"] = 0.0
			spark["trail"].push_front(spark["position"])
			while spark["trail"].size() > trail_length:
				spark["trail"].pop_back()

		if spark["age"] >= spark_lifetime:
			sparks.remove_at(i)
		else:
			sparks[i] = spark

	queue_redraw()

func _emit_burst() -> void:
	var burst_size := randi_range(3, 7)
	
	for i in range(burst_size):
		_emit_spark()

func _emit_spark() -> void:
	var angle := randf_range(0.0, TAU)
	var speed := randf_range(spark_speed_min, spark_speed_max)
	
	var velocity := Vector2(
		cos(angle) * speed,
		sin(angle) * speed
	)
	
	sparks.append({
		"position": Vector2.ZERO,
		"velocity": velocity,
		"age" : 0.0,
		"trail_timer" : 0.0,
		"trail": [Vector2.ZERO]
	})


func _draw() -> void:
	for spark in sparks:
		var trail: Array = spark["trail"]
		var age: float = spark["age"]
		var lifetime_ratio: float = 1.0 - (age / spark_lifetime)

		for i in range(trail.size()):
			var fade := 1.0 - (float(i) / maxf(float(trail_length), 1.0))
			var alpha := fade * lifetime_ratio

			var radius := lerpf(1.5, 0.4, float(i) / maxf(float(trail_length), 1.0))

			draw_circle(
				trail[i],
				radius,
				Color(1.0, 0.75, 0.35, alpha)
			)

		draw_circle(
			spark["position"],
			2.0,
			Color(1.0, 0.95, 0.75, lifetime_ratio)
		)
