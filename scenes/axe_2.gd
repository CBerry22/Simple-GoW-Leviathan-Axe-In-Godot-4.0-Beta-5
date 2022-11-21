extends CharacterBody3D

signal returned


@export var recall_curve: Curve
@export_flags_3d_physics var aim_collision_mask

@export var throw_force: float = 1000.0
@export var spin_speed: float = 50.0
@export var recall_speed: float = 10.0

@export var player: Node3D
@onready var parent: Node3D = get_parent()

enum STATE {HELD, THROWN, LANDED, RECALLED}
var state: STATE = STATE.HELD

var recall_start: Vector3
var recall_progress: float = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):	
	if state == STATE.THROWN || state == STATE.RECALLED:
		rotate_object_local(Vector3.RIGHT, deg_to_rad(spin_speed))
		
	if state == STATE.THROWN:
		if !is_on_floor():
			velocity.y -= gravity * delta
		move_and_collide(velocity * delta)
		
	if state == STATE.RECALLED:
		recall_progress += recall_speed * delta
		
		if abs(global_position.distance_to(parent.global_position)) < 0.1:
			global_position = parent.global_position
			global_rotation = parent.global_rotation
			top_level = false
			state = STATE.HELD
			emit_signal("returned")
		else:
			var x = recall_curve.sample_baked(recall_progress / recall_start.distance_to(parent.global_position))
			var offset = player.transform.basis * Vector3(x, 0, 0)
			global_position = recall_start.move_toward(parent.global_position, recall_progress) + offset
			
	
func throw():
	if state == STATE.HELD:
		top_level = true
		var direction = _get_direction()
		transform = transform.looking_at(global_position + direction, Vector3.UP)
		velocity = direction * throw_force
		state = STATE.THROWN
		
func _get_direction():
	var viewport := get_viewport()
	var camera := viewport.get_camera_3d()
	var center: Vector2 = viewport.size/2
	var from: Vector3 = camera.project_ray_origin(center)
	var to: Vector3 = from + camera.project_ray_normal(center) * 1000
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var collision = get_world_3d().direct_space_state.intersect_ray(query)
	if collision:
		return global_position.direction_to(collision.position)
	else:
		return global_position.direction_to(to)
	
func recall():
	if state == STATE.RECALLED:
		return
		
	recall_start = global_position
	recall_progress = 0.0
	state = STATE.RECALLED
	velocity = Vector3.ZERO

func _on_area_3d_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	if state == STATE.RECALLED:
		return
	
	velocity = Vector3.ZERO
	state = STATE.LANDED
