extends CharacterBody3D

var default_cam = load("res://scenes/camera/default_camera.tscn")

var typing_in_chat:bool

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

#const BASE_FOV = 90.0
#const RUN_FOV = 2
#const FIRSTPRS_SENSITIVITY = .002
#const THIRDPRS_SENSITIVITY = .0035
#var active_sensitivity = THIRDPRS_SENSITIVITY
#var cursor_pos:Vector2
#var can_move_cam:bool = false
#var third_person:bool = true

var cam_pivot:Node3D
var camera:Camera3D
var viewmodel_cam:Camera3D
var hud:CanvasLayer
var chat_box:LineEdit
#var item:Node3D
#var anim_plr:AnimationTree
#@onready var anim_plr_3prs:AnimationTree = $Smoothing/MeshInstance3D/Pickaxe/AnimationTree

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func enter_first_person():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	third_person = false
	can_move_cam = true
	#viewmodel_cam.visible = true
	active_sensitivity = FIRSTPRS_SENSITIVITY
	for i in $Smoothing/Playermodel.get_children():
		i.visible = false

func exit_first_person():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	third_person = true
	can_move_cam = false
	#viewmodel_cam.visible = false
	active_sensitivity = THIRDPRS_SENSITIVITY
	for i in $Smoothing/Playermodel.get_children():
		i.visible = true

func swung_peak():
	var raycast:RayCast3D = camera.get_node("RayCast3D") as RayCast3D
	if not raycast.is_colliding(): return
	#item.get_node("AudioStreamPlayer").play()
	var decal = load("res://scenes/hit_decal.tscn").instantiate() as Decal
	get_tree().root.add_child(decal)
	decal.global_position = raycast.get_collision_point()
	if raycast.get_collision_normal() == Vector3.DOWN:
		decal.rotation_degrees.x = 90
	elif raycast.get_collision_normal() != Vector3.UP:
		decal.look_at(raycast.get_collision_point() - raycast.get_collision_normal(), Vector3.UP)
		decal.rotation_degrees.x += 90

func _ready():
	cam_pivot = default_cam.instantiate()
	$Smoothing.add_child(cam_pivot)
	camera = cam_pivot.get_node("Camera3D")
	viewmodel_cam = camera.get_node("ViewmodelViewport/SubViewport/ViewmodelCam")
	#item = viewmodel_cam.get_child(0)
	#anim_plr = item.get_node("AnimationTree") as AnimationTree
	chat_box.focus_entered.connect(_chat_box_focused)
	chat_box.focus_exited.connect(_chat_box_unfocused)
	#anim_plr["parameters/conditions/idle"] = true
	#item.swung.connect(swung_peak)

func _unhandled_input(event):
	if event is InputEventMouseMotion and can_move_cam:
		rotate_y(-event.relative.x * active_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * active_sensitivity)
		cam_pivot.rotation.x = clamp (cam_pivot.rotation.x, -1.5708, 1.5708)
	
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

#func _process(_delta):
	#viewmodel_cam.global_transform = camera.global_transform

func _physics_process(delta):
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if not typing_in_chat and Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Vector2.ZERO
	if not typing_in_chat:
		input_dir = Input.get_vector("Left","Right","Forward","Backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = move_toward(velocity.x, direction.x*speed, ACCEL*delta)
			velocity.z = move_toward(velocity.z, direction.z*speed, ACCEL*delta)
		else:
			velocity.x = move_toward(velocity.x, 0, DECEL*delta)
			velocity.z = move_toward(velocity.z, 0, DECEL*delta)
	else:
		if direction:
			velocity.x = lerp(velocity.x, direction.x*speed, ACCEL_AIR*delta)
			velocity.z = lerp(velocity.z, direction.z*speed, ACCEL_AIR*delta)
		else:
			velocity.x = lerp(velocity.x, 0.0, DECEL_AIR*delta)
			velocity.z = lerp(velocity.z, 0.0, DECEL_AIR*delta)
	
	var vel_clamped = clamp(velocity.length(), RUN_FOV, RUN_SPEED*2)
	var target_fov = BASE_FOV + RUN_FOV * vel_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8)
	
	bob_progress += delta * velocity.length() * int(is_on_floor())
	cam_pivot.transform.origin = Vector3(0, sin(bob_progress * BOB_FREQ) * BOB_AMP+0.5, 0)

	move_and_slide()

func _chat_box_focused():
	typing_in_chat = true
func _chat_box_unfocused():
	typing_in_chat = false
