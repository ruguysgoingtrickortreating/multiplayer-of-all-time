extends Node

var default_cam = load("res://scenes/camera/default_camera.tscn")
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const ACCEL = 50.0
const DECEL = 50.0
const ACCEL_AIR = 4.0
const DECEL_AIR = 4.0
var speed:float = WALK_SPEED

const BOB_FREQ = 2
const BOB_AMP = 0.05
var bob_progress: float

const BASE_FOV = 90.0
const RUN_FOV = 2
const FIRSTPRS_SENSITIVITY = .002
const THIRDPRS_SENSITIVITY = .0035
var active_sensitivity = THIRDPRS_SENSITIVITY
var cursor_pos:Vector2
var can_move_cam:bool = false
var third_person:bool = true
var cam_rotation:Vector2

var cam_pivot:Node3D
var camera:Camera3D
var hud:CanvasLayer
var chat_box:LineEdit
var typing_in_chat:bool
@onready var charbody:CharacterBody3D = $".."

func enter_first_person():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	third_person = false
	can_move_cam = true
	#viewmodel_cam.visible = true
	active_sensitivity = FIRSTPRS_SENSITIVITY
	for i in $".."/Smoothing/Playermodel.get_children():
		i.visible = false

func exit_first_person():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	third_person = true
	can_move_cam = false
	#viewmodel_cam.visible = false
	active_sensitivity = THIRDPRS_SENSITIVITY
	for i in $".."/Smoothing/Playermodel.get_children():
		i.visible = true

func _input(_event):
	if typing_in_chat: return
	if Input.is_action_just_pressed("Esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		can_move_cam = false
	if Input.is_action_pressed("Run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED
	if Input.is_action_just_released("FocusChat"):
		chat_box.grab_focus()

func _unhandled_input(event):
	if event is InputEventMouseMotion and can_move_cam:
		#cam rotation keeps track of where the cam should be rotated (changed on mouse move), which is then applied to cam_pivot
		cam_rotation.x += -event.relative.x * active_sensitivity
		cam_rotation.y += -event.relative.y * active_sensitivity
		cam_rotation.y = clamp (cam_rotation.y, -1.5708, 1.5708)
		cam_pivot.transform.basis = Basis()
		cam_pivot.rotate_object_local(Vector3(0,1,0),cam_rotation.x)
		cam_pivot.rotate_object_local(Vector3(1,0,0),cam_rotation.y)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT when event.is_pressed():
				if not third_person and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					can_move_cam = true
				chat_box.release_focus()
				#anim_plr["parameters/conditions/is_swinging"] = true
				#anim_plr_3prs["parameters/conditions/is_swinging"] = true
			MOUSE_BUTTON_LEFT when event.is_released():
				pass
				#anim_plr["parameters/conditions/is_swinging"] = false
				#anim_plr_3prs["parameters/conditions/is_swinging"] = false
			MOUSE_BUTTON_LEFT when event.is_pressed():
				chat_box.release_focus()
			MOUSE_BUTTON_RIGHT when event.is_pressed():
				can_move_cam = true
				cursor_pos = get_viewport().get_mouse_position()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				chat_box.release_focus()
			MOUSE_BUTTON_RIGHT when event.is_released() and third_person:
				can_move_cam = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_viewport().warp_mouse(cursor_pos)
			MOUSE_BUTTON_WHEEL_DOWN when event.is_pressed():
				if camera.position.z == 0:
					exit_first_person()
					camera.position.z = 0.8
				else:
					camera.position.z += 0.2
					camera.position.z = clamp(camera.position.z,0,8)
					print("zooming out " + str(camera.position.z))
			MOUSE_BUTTON_WHEEL_UP when event.is_pressed():
				if camera.position.z <= 0.85: 
					enter_first_person()
					camera.position.z = 0
				else:
					camera.position.z -= 0.2
					camera.position.z = clamp(camera.position.z,0,8)
					print("zooming in " + str(camera.position.z))
		
		if camera.position.z == 0:
			third_person = false
		else:
			third_person = true
			active_sensitivity = THIRDPRS_SENSITIVITY

func _physics_process(delta):
	
	cam_pivot.transform.origin = charbody.transform.origin + Vector3(0, sin(bob_progress * BOB_FREQ) * BOB_AMP+0.5, 0)
	
	if not charbody.is_on_floor():
		charbody.velocity.y -= gravity * delta
	
	# Handle Jump.
	if not typing_in_chat and Input.is_action_just_pressed("Jump") and charbody.is_on_floor():
		charbody.velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Vector2.ZERO
	if not typing_in_chat:
		input_dir = Input.get_vector("Left","Right","Forward","Backward")
	var direction = (charbody.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction or not third_person:
		#charbody.rotation.y = cam_rotation.x
		charbody.rotation.y = lerp_angle(charbody.rotation.y,cam_pivot.rotation.y,25*delta)
		print(charbody.rotation.y - cam_pivot.rotation.y)
	
	if direction:
		if charbody.is_on_floor():
			if direction:
				charbody.velocity.x = move_toward(charbody.velocity.x, direction.x*speed, ACCEL*delta)
				charbody.velocity.z = move_toward(charbody.velocity.z, direction.z*speed, ACCEL*delta)
		else:
				charbody.velocity.x = lerp(charbody.velocity.x, direction.x*speed, ACCEL_AIR*delta)
				charbody.velocity.z = lerp(charbody.velocity.z, direction.z*speed, ACCEL_AIR*delta)
	else:
		if charbody.is_on_floor():
			charbody.velocity.x = move_toward(charbody.velocity.x, 0, DECEL*delta)
			charbody.velocity.z = move_toward(charbody.velocity.z, 0, DECEL*delta)
		else:
			charbody.velocity.x = lerp(charbody.velocity.x, 0.0, DECEL_AIR*delta)
			charbody.velocity.z = lerp(charbody.velocity.z, 0.0, DECEL_AIR*delta)
	
	#print(cam_pivot.rotation.y)
	var vel_clamped = clamp(charbody.velocity.length(), RUN_FOV, RUN_SPEED*2)
	var target_fov = BASE_FOV + RUN_FOV * vel_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8)
	
	bob_progress += delta * charbody.velocity.length() * int(charbody.is_on_floor())
	
	charbody.move_and_slide()

# Called when the node enters the scene tree for the first time.
func _ready():
	#cam_pivot = default_cam.instantiate()
	$".."/Smoothing.add_child(cam_pivot)
	camera = cam_pivot.get_node("Camera3D")
	chat_box.focus_entered.connect(_chat_box_focused)
	chat_box.focus_exited.connect(_chat_box_unfocused)
	#anim_plr["parameters/conditions/idle"] = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _chat_box_focused():
	typing_in_chat = true
func _chat_box_unfocused():
	typing_in_chat = false
