extends CharacterBody3D

@onready var anim_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = $AnimationTree.get("parameters/playback")
@onready var center: Node3D = $Center

var mouse_position = Vector2.ZERO
var total_pitch = 0.0
@export_range(0.0, 1.0) var sensitivity = 0.25

const SPEED = 5.0
const ACCELERATION = SPEED/20.0

@export var axe: CharacterBody3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _process(delta):
	_update_mouselook()
	
	if Input.is_action_just_pressed("throw"):
		if axe.state == axe.STATE.HELD:
			state_machine.travel("Throw")
		
	if Input.is_action_just_pressed("recall"):
		axe.recall()
		state_machine.travel("Recall")
		
func throw_axe():
	axe.throw()


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = transform.basis * Vector3(input_dir.x/2, 0, input_dir.y)
	if direction && state_machine.get_current_node() == "Move":
		velocity = velocity.lerp(direction * SPEED, ACCELERATION)
	else:
		velocity = velocity.lerp(Vector3.ZERO, ACCELERATION)
		
	var local_vel = transform.basis.inverse() * velocity
	anim_tree.set("parameters/Move/blend_position", Vector2(local_vel.x, -local_vel.z))
		
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion:
		mouse_position = event.relative
	
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			KEY_TAB:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _update_mouselook():
	mouse_position *= sensitivity
	var yaw = mouse_position.x
	var pitch = mouse_position.y
	
	pitch = clamp(pitch, -50 - total_pitch, 50 - total_pitch)
	total_pitch += pitch

	rotate_y(deg_to_rad(-yaw))
	center.rotate_x(deg_to_rad(-pitch))


func _on_axe_returned():
	state_machine.travel("Catch")
