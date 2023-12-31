GDPC                 �                                                                         T   res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn  �`      �      欙��rp�J%1��eA    P   res://.godot/exported/133200997/export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn�4      �      fj�X�ry�g2qq    \   res://.godot/exported/133200997/export-9dd0d80496426189d5c914f2baa5c033-multiplayer_menu.scn�T      K      QQ�3�1��)s��6    ,   res://.godot/global_script_class_cache.cfg  �             ��Р�8���8~$}P�    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex�j      �      �̛�*$q�*�́     L   res://.godot/imported/smoothing.png-6b454a779e636eaa20b6c6ac618bf82a.ctex   p      >      ���7�A�fj�yF��6    L   res://.godot/imported/smoothing_2d.png-4942c58db397caab18506104d957cac1.ctex+      \      ��< ����^ȖJn�       res://.godot/uid_cache.bin  Й      �       #���6�?^f����%       res://GameManager.gd�i            g���3S�"]y�Z��Wu        res://MultiplayerController.gd  Px      �      �R%��I�n������       res://Player.gd  �      ~      ���K;s�T!ح}A�    $   res://addons/smoothing/smoothing.gd         m      �o/�c7���eH�B�    ,   res://addons/smoothing/smoothing.png.import �      �       u�-Za��O�]�2�5�    (   res://addons/smoothing/smoothing_2d.gd  �      �      CI��:��
�s1���    0   res://addons/smoothing/smoothing_2d.png.import  p,      �       ����r=���4��k    ,   res://addons/smoothing/smoothing_plugin.gd  @-      %      ���*����ݪ�J*��       res://icon.svg  �      �      C��=U���^Qu��U3       res://icon.svg.import   �w      �       �fXi�Z�Ya]j�X       res://project.binaryК      l      G!^��A��ʓY5�R       res://scenes/main.gdp/      }      ��~�:;V.^�Kf#W       res://scenes/main.tscn.remap��      a       
��������S8z�s    (   res://scenes/multiplayer_menu.tscn.remap�      m       ��sS�!�?��.^���        res://scenes/player.tscn.remap  ��      c       2�A�Z͈�BJbB        #	Copyright (c) 2019 Lawnjelly
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

extends Node3D

@export
var target: NodePath:
	get:
		return target
	set(v):
		target = v
		set_target()


var _m_Target: Node3D

var _m_trCurr: Transform3D
var _m_trPrev: Transform3D

const SF_ENABLED = 1 << 0
const SF_TRANSLATE = 1 << 1
const SF_BASIS = 1 << 2
const SF_SLERP = 1 << 3
const SF_INVISIBLE = 1 << 4

@export_flags("enabled", "translate", "basis", "slerp") var flags: int = SF_ENABLED | SF_TRANSLATE | SF_BASIS:
	set(v):
		flags = v
		# we may have enabled or disabled
		_SetProcessing()
	get:
		return flags


##########################################################################################
# USER FUNCS


# call this checked e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport():
	var temp_flags = flags
	_SetFlags(SF_TRANSLATE | SF_BASIS)

	_RefreshTransform()
	_m_trPrev = _m_trCurr

	# do one frame update to make sure all components are updated
	_process(0)

	# resume old flags
	flags = temp_flags


func set_enabled(bEnable: bool):
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()


func is_enabled():
	return _TestFlags(SF_ENABLED)


##########################################################################################


func _ready():
	_m_trCurr = Transform3D()
	_m_trPrev = Transform3D()
	set_process_priority(100)
	set_as_top_level(true)
	Engine.set_physics_jitter_fix(0.0)


func set_target():
	if is_inside_tree():
		_FindTarget()


func _set_flags(new_value):
	flags = new_value
	# we may have enabled or disabled
	_SetProcessing()


func _get_flags():
	return flags


func _SetProcessing():
	var bEnable = _TestFlags(SF_ENABLED)
	if _TestFlags(SF_INVISIBLE):
		bEnable = false

	set_process(bEnable)
	set_physics_process(bEnable)
	pass


func _enter_tree():
	# might have been moved
	_FindTarget()
	pass


func _notification(what):
	match what:
		# invisible turns unchecked processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()


func _RefreshTransform():
	if _HasTarget() == false:
		return

	_m_trPrev = _m_trCurr
	_m_trCurr = _m_Target.global_transform

func _FindTarget():
	_m_Target = null
	
	# If no target has been assigned in the property,
	# default to using the parent as the target.
	if target.is_empty():
		var parent = get_parent_node_3d()
		if parent:
			_m_Target = parent
		return
		
	var targ = get_node(target)

	if ! targ:
		printerr("ERROR SmoothingNode : Target " + str(target) + " not found")
		return

	if not targ is Node3D:
		printerr("ERROR SmoothingNode : Target " + str(target) + " is not node 3D")
		target = ""
		return

	# if we got to here targ is a spatial
	_m_Target = targ

	# certain targets are disallowed
	if _m_Target == self:
		var msg = str(_m_Target.get_name()) + " assigned to " + str(self.get_name()) + "]"
		printerr("ERROR SmoothingNode : Target should not be self [", msg)

		# error message
		#OS.alert("Target cannot be a parent or grandparent in the scene tree.", "SmoothingNode")
		_m_Target = null
		target = ""
		return


func _HasTarget() -> bool:
	if _m_Target == null:
		return false

	# has not been deleted?
	if is_instance_valid(_m_Target):
		return true

	_m_Target = null
	return false


func _process(_delta):

	var f = Engine.get_physics_interpolation_fraction()
	var tr: Transform3D = Transform3D()

	# translate
	if _TestFlags(SF_TRANSLATE):
		var ptDiff = _m_trCurr.origin - _m_trPrev.origin
		tr.origin = _m_trPrev.origin + (ptDiff * f)

	# rotate
	if _TestFlags(SF_BASIS):
		if _TestFlags(SF_SLERP):
			tr.basis = _m_trPrev.basis.slerp(_m_trCurr.basis, f)
		else:
			tr.basis = _LerpBasis(_m_trPrev.basis, _m_trCurr.basis, f)

	transform = tr


func _physics_process(_delta):
	_RefreshTransform()


func _LerpBasis(from: Basis, to: Basis, f: float) -> Basis:
	var res: Basis = Basis()
	res.x = from.x.lerp(to.x, f)
	res.y = from.y.lerp(to.y, f)
	res.z = from.z.lerp(to.z, f)
	return res


func _SetFlags(f):
	flags |= f


func _ClearFlags(f):
	flags &= ~f


func _TestFlags(f):
	return (flags & f) == f


func _ChangeFlags(f, bSet):
	if bSet:
		_SetFlags(f)
	else:
		_ClearFlags(f)
   GST2            ����                          RIFF�   WEBPVP8L�   /��öm����c)������m$I����	'�m��������w<.s�yCS}:���v��]�ܶm��c���h�1Da��Gc������.����sX$I,bNņ��f�D�}��/�N4�I`�P�|$n�wQ���L���HLVq�چ^�$�E���d�Eo�eo���del����/�Bk�p����Ț���E��M��$�$ė�ۋ���,�gYE7���>&������s    [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://bm44ebnxqc82"
path="res://.godot/imported/smoothing.png-6b454a779e636eaa20b6c6ac618bf82a.ctex"
metadata={
"vram_texture": false
}
            #	Copyright (c) 2019 Lawnjelly
#
#	Permission is hereby granted, free of charge, to any person obtaining a copy
#	of this software and associated documentation files (the "Software"), to deal
#	in the Software without restriction, including without limitation the rights
#	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#	copies of the Software, and to permit persons to whom the Software is
#	furnished to do so, subject to the following conditions:
#
#	The above copyright notice and this permission notice shall be included in all
#	copies or substantial portions of the Software.
#
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#	SOFTWARE.

extends Node2D


@export
var target: NodePath:
	get:
		return target
	set(v):
		target = v
		if is_inside_tree():
			_FindTarget()

var _m_Target: Node2D
var _m_Flip:bool = false

var _m_Trans_curr: Transform2D = Transform2D()
var _m_Trans_prev: Transform2D = Transform2D()

const SF_ENABLED = 1 << 0
const SF_GLOBAL_IN = 1 << 1
const SF_GLOBAL_OUT = 1 << 2
const SF_TOP_LEVEL = 1 << 3
const SF_INVISIBLE = 1 << 4

@export_flags("enabled", "global in", "global out", "top level") var flags: int = SF_ENABLED | SF_GLOBAL_IN | SF_GLOBAL_OUT:
	set(v):
		flags = v
		# we may have enabled or disabled
		_SetProcessing()
	get:
		return flags

##########################################################################################
# USER FUNCS


# call this checked e.g. starting a level, AFTER moving the target
# so we can update both the previous and current values
func teleport():
	_RefreshTransform()
	_m_Trans_prev = _m_Trans_curr

	# call frame upate to make sure all components of the node are set
	_process(0)


func set_enabled(bEnable: bool):
	_ChangeFlags(SF_ENABLED, bEnable)
	_SetProcessing()


func is_enabled():
	return _TestFlags(SF_ENABLED)


##########################################################################################


func _ready():
	set_process_priority(100)
	Engine.set_physics_jitter_fix(0.0)
	set_as_top_level(_TestFlags(SF_TOP_LEVEL))


func _SetProcessing():
	var bEnable = _TestFlags(SF_ENABLED)
	if _TestFlags(SF_INVISIBLE):
		bEnable = false

	set_process(bEnable)
	set_physics_process(bEnable)
	set_as_top_level(_TestFlags(SF_TOP_LEVEL))


func _enter_tree():
	# might have been moved
	_FindTarget()


func _notification(what):
	match what:
		# invisible turns unchecked processing
		NOTIFICATION_VISIBILITY_CHANGED:
			_ChangeFlags(SF_INVISIBLE, is_visible_in_tree() == false)
			_SetProcessing()


func _RefreshTransform():

	if _HasTarget() == false:
		return

	_m_Trans_prev = _m_Trans_curr

	if _TestFlags(SF_GLOBAL_IN):
		_m_Trans_curr = _m_Target.get_global_transform()
	else:
		_m_Trans_curr = _m_Target.get_transform()

	_m_Flip = false
	# Ideally we would use determinant core function, as in commented line below, but we
	# need to workaround for backward compat.
	# if (_m_Trans_prev.determinant() < 0) != (_m_Trans_curr.determinant() < 0):
	
	if (_Determinant_Sign(_m_Trans_prev) != _Determinant_Sign(_m_Trans_curr)):
		_m_Flip = true

func _Determinant_Sign(t:Transform2D)->bool:
	# Workaround Transform2D determinant function not being available
	# until 3.6 / 4.1.
	# We calculate determinant manually, slower but compatible to lower
	# godot versions.
	var d = (t.x.x * t.y.y) - (t.x.y * t.y.x)
	return d >= 0.0
	

func _FindTarget():
	_m_Target = null

	# If no target has been assigned in the property,
	# default to using the parent as the target.
	if target.is_empty():
		var parent = get_parent()
		if parent and (parent is Node2D):
			_m_Target = parent
		return
		
	var targ = get_node(target)

	if ! targ:
		printerr("ERROR SmoothingNode2D : Target " + str(target) + " not found")
		return

	if not targ is Node2D:
		printerr("ERROR SmoothingNode2D : Target " + str(target) + " is not Node2D")
		target = ""
		return

	# if we got to here targ is correct type
	_m_Target = targ

func _HasTarget() -> bool:
	if _m_Target == null:
		return false

	# has not been deleted?
	if is_instance_valid(_m_Target):
		return true

	_m_Target = null
	return false


func _process(_delta):
	var f = Engine.get_physics_interpolation_fraction()

	var tr = Transform2D()
	tr.origin = lerp(_m_Trans_prev.origin, _m_Trans_curr.origin, f)
	tr.x = lerp(_m_Trans_prev.x, _m_Trans_curr.x, f)
	tr.y = lerp(_m_Trans_prev.y, _m_Trans_curr.y, f)

	# When a sprite flip is detected, turn off interpolation for that tick.
	if _m_Flip:
		tr = _m_Trans_curr

	if _TestFlags(SF_GLOBAL_OUT) and not _TestFlags(SF_TOP_LEVEL):
		set_global_transform(tr)
	else:
		set_transform(tr)


func _physics_process(_delta):
	_RefreshTransform()


func _SetFlags(f):
	flags |= f


func _ClearFlags(f):
	flags &= ~f


func _TestFlags(f):
	return (flags & f) == f


func _ChangeFlags(f, bSet):
	if bSet:
		_SetFlags(f)
	else:
		_ClearFlags(f)
          GST2            ����                        $  RIFF  WEBPVP8L  /�`ضm�����Y.}nDm����ث��dܶm���K��9�mkYN�+��;��X�1X��@�����ݠ�mۆ�=����"��c����5|{:ڷ��o/��aJ�����+"V&3hF2;���@؁�ڰM��h�y�Ն�h|�%L�L����ţ)6�A���0u֦;_��6�<�a����ƺ�����3� XC��B���n�VVQ��b[,S��V<!H����]�s�~0�Ѝ�( ��>�%��z    [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://i3h8ng5fyd1m"
path="res://.godot/imported/smoothing_2d.png-4942c58db397caab18506104d957cac1.ctex"
metadata={
"vram_texture": false
}
         @tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
	add_custom_type("Smoothing", "Node3D", preload("smoothing.gd"), preload("smoothing.png"))
	add_custom_type("Smoothing2D", "Node2D", preload("smoothing_2d.gd"), preload("smoothing_2d.png"))
	pass


func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove_at it from the engine when deactivated
	remove_custom_type("Smoothing")
	remove_custom_type("Smoothing2D")
           extends Node3D

@export var player_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameManager.players.size() == 0:
		instantiate_player("1")
	var spawn_location = 1
	for i in GameManager.players:
		print(str(spawn_location))
		instantiate_player(str(spawn_location%4), GameManager.players[i].name, GameManager.players[i].id)
		spawn_location += 1

func instantiate_player(spawn_location_number:String, player_name:String="", multiplayer_id = null):
	var player_instance = player_scene.instantiate() as CharacterBody3D
	if multiplayer_id:
		player_instance.multiplayer_id = multiplayer_id
		var id_label = str(multiplayer_id)
		if multiplayer_id == 1: 
			id_label = "1 (HOST)"
			player_instance.is_host = true
		player_instance.get_node("Smoothing/IdLabel").text = id_label
	if not multiplayer_id or multiplayer_id == GameManager.multiplayer_unique_id:
		player_instance.get_node("Smoothing/CamPivot/Camera3D").current = true
		player_instance.main_character = true
	player_instance.get_node("Smoothing/NameLabel").text = player_name
	add_child(player_instance)
	print(str(GameManager.multiplayer_unique_id)+" spawning at "+spawn_location_number)
	player_instance.global_position = get_node("SpawnLocations/"+spawn_location_number).position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
   RSRC                    PackedScene            ��������                                            �      resource_local_to_scene    resource_name    sky_top_color    sky_horizon_color 
   sky_curve    sky_energy_multiplier 
   sky_cover    sky_cover_modulate    ground_bottom_color    ground_horizon_color    ground_curve    ground_energy_multiplier    sun_angle_max 
   sun_curve    use_debanding    script    sky_material    process_mode    radiance_size    background_mode    background_color    background_energy_multiplier    background_intensity    background_canvas_max_layer    background_camera_feed_id    sky    sky_custom_fov    sky_rotation    ambient_light_source    ambient_light_color    ambient_light_sky_contribution    ambient_light_energy    reflected_light_source    tonemap_mode    tonemap_exposure    tonemap_white    ssr_enabled    ssr_max_steps    ssr_fade_in    ssr_fade_out    ssr_depth_tolerance    ssao_enabled    ssao_radius    ssao_intensity    ssao_power    ssao_detail    ssao_horizon    ssao_sharpness    ssao_light_affect    ssao_ao_channel_affect    ssil_enabled    ssil_radius    ssil_intensity    ssil_sharpness    ssil_normal_rejection    sdfgi_enabled    sdfgi_use_occlusion    sdfgi_read_sky_light    sdfgi_bounce_feedback    sdfgi_cascades    sdfgi_min_cell_size    sdfgi_cascade0_distance    sdfgi_max_distance    sdfgi_y_scale    sdfgi_energy    sdfgi_normal_bias    sdfgi_probe_bias    glow_enabled    glow_levels/1    glow_levels/2    glow_levels/3    glow_levels/4    glow_levels/5    glow_levels/6    glow_levels/7    glow_normalized    glow_intensity    glow_strength 	   glow_mix    glow_bloom    glow_blend_mode    glow_hdr_threshold    glow_hdr_scale    glow_hdr_luminance_cap    glow_map_strength 	   glow_map    fog_enabled    fog_light_color    fog_light_energy    fog_sun_scatter    fog_density    fog_aerial_perspective    fog_sky_affect    fog_height    fog_height_density    volumetric_fog_enabled    volumetric_fog_density    volumetric_fog_albedo    volumetric_fog_emission    volumetric_fog_emission_energy    volumetric_fog_gi_inject    volumetric_fog_anisotropy    volumetric_fog_length    volumetric_fog_detail_spread    volumetric_fog_ambient_inject    volumetric_fog_sky_affect -   volumetric_fog_temporal_reprojection_enabled ,   volumetric_fog_temporal_reprojection_amount    adjustment_enabled    adjustment_brightness    adjustment_contrast    adjustment_saturation    adjustment_color_correction    render_priority 
   next_pass    transparency    blend_mode 
   cull_mode    depth_draw_mode    no_depth_test    shading_mode    diffuse_mode    specular_mode    disable_ambient_light    disable_fog    vertex_color_use_as_albedo    vertex_color_is_srgb    albedo_color    albedo_texture    albedo_texture_force_srgb    albedo_texture_msdf 	   metallic    metallic_specular    metallic_texture    metallic_texture_channel 
   roughness    roughness_texture    roughness_texture_channel    emission_enabled 	   emission    emission_energy_multiplier    emission_operator    emission_on_uv2    emission_texture    normal_enabled    normal_scale    normal_texture    rim_enabled    rim 	   rim_tint    rim_texture    clearcoat_enabled 
   clearcoat    clearcoat_roughness    clearcoat_texture    anisotropy_enabled    anisotropy    anisotropy_flowmap    ao_enabled    ao_light_affect    ao_texture 
   ao_on_uv2    ao_texture_channel    heightmap_enabled    heightmap_scale    heightmap_deep_parallax    heightmap_flip_tangent    heightmap_flip_binormal    heightmap_texture    heightmap_flip_texture    subsurf_scatter_enabled    subsurf_scatter_strength    subsurf_scatter_skin_mode    subsurf_scatter_texture &   subsurf_scatter_transmittance_enabled $   subsurf_scatter_transmittance_color &   subsurf_scatter_transmittance_texture $   subsurf_scatter_transmittance_depth $   subsurf_scatter_transmittance_boost    backlight_enabled 
   backlight    backlight_texture    refraction_enabled    refraction_scale    refraction_texture    refraction_texture_channel    detail_enabled    detail_mask    detail_blend_mode    detail_uv_layer    detail_albedo    detail_normal 
   uv1_scale    uv1_offset    uv1_triplanar    uv1_triplanar_sharpness    uv1_world_triplanar 
   uv2_scale    uv2_offset    uv2_triplanar    uv2_triplanar_sharpness    uv2_world_triplanar    texture_filter    texture_repeat    disable_receive_shadows    shadow_to_opacity    billboard_mode    billboard_keep_scale    grow    grow_amount    fixed_size    use_point_size    point_size    use_particle_trails    proximity_fade_enabled    proximity_fade_distance    msdf_pixel_range    msdf_outline_size    distance_fade_mode    distance_fade_min_distance    distance_fade_max_distance 	   _bundled       Script    res://scenes/main.gd ��������   PackedScene    res://scenes/player.tscn ��W$Y�js   $   local://ProceduralSkyMaterial_yae5s          local://Sky_45uhc Y         local://Environment_6e3uy }      !   local://StandardMaterial3D_1lu63 �      !   local://StandardMaterial3D_luvdc       !   local://StandardMaterial3D_4ux54 C      !   local://StandardMaterial3D_4cpoq ~         local://PackedScene_cp2y2 �         ProceduralSkyMaterial          �p%?;�'?F�+?  �?	      �p%?;�'?F�+?  �?         Sky                          Environment                         !         C                  StandardMaterial3D          ���>���>���>  �?         StandardMaterial3D          s� >��?��@=  �?         StandardMaterial3D          ��?��@=��@=  �?         StandardMaterial3D          ���=��@=��?  �?         PackedScene    �      	         names "         Node3D    script    player_scene    DirectionalLight3D 
   transform    shadow_enabled    WorldEnvironment    environment    EnvironmentObjects 	   CSGBox3D    use_collision    size 
   CSGBox3D2 	   material 
   CSGBox3D3 
   CSGBox3D4 
   CSGBox3D5 
   CSGBox3D6 
   CSGBox3D7 
   CSGBox3D8    SpawnLocations    1    2    3    4    	   variants                             г]��ݾ  �>       ?г]?   �  @?�ݾ                              �@            ��̽              �@                  A       A   ff�?              �?              �?  �A             �?  `A  B            ff�?              �?              �?  ��           ���      ��      �?    ff�?    1�;�yG�      �A   ���      ��      �?    ff�?    1�;�yG5      ��     �?              �?              �?  �@      �@     �@   @  �@              �?              �?              �?  �@             �@  �@  �@              �?              �?              �?  �@  �?  ��              �?              �?              �?  ��ff�?         �?              �?              �?  ��ff�?   �     �?              �?              �?  @�ff�?   @     �?              �?              �?   �ff�?  @�      node_count             nodes     �   ��������        ����                                  ����                                 ����                            ����               	   	   ����         
                       	      ����         
               	              	      ����      
   
               	              	      ����         
               	              	      ����         
               	              	      ����         
                             	      ����         
                             	      ����         
                                     ����                      ����                           ����                           ����                           ����                   conn_count              conns               node_paths              editable_instances              version             RSRC           RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       Script    res://MultiplayerController.gd ��������      local://PackedScene_dnu8x          PackedScene          	         names "   *      MultiplayerMenu    layout_mode    anchors_preset    anchor_right    anchor_bottom    grow_horizontal    grow_vertical    script    Control    HostButton    offset_left    offset_top    offset_right    offset_bottom    text    Button    JoinButton    StartButton    TitleLabel $   theme_override_font_sizes/font_size    Label    UsernameLabel    IpLabel 
   PortLabel    WaitingForHostLabel    visible 	   ErrorLog !   theme_override_colors/font_color    horizontal_alignment    autowrap_mode    UsernameTextbox    placeholder_text 	   LineEdit 
   IpTextbox    PortTextbox    _on_host_pressed    pressed    _on_join_pressed    _on_start_game_pressed    _on_ip_textbox_text_changed    text_changed    _on_port_textbox_text_changed    	   variants    =                    �?                            �B     �C    ��C     �C   
   host game      CD     �D   
   join game     ��C    ��C    @6D    ��C      start game in singleplayer
       B     �A   2         multiplayer of all time      �B     iC     �C   	   username      �C     mC    �D     �C      ip address
      DD     kC    �nD     �C      port
             nC    ��C    �oD     �C      waiting for host to start game      �B     �C    ��D     D     �?          �?                ��C    ��C     �C      robert      �C    �3D   
   127.0.0.1     �CD    @�D    ��C      12345       node_count             nodes       ��������       ����                                                             	   ����         
                     	      
                     ����         
                     	                           ����         
                                                ����                                                   ����         
                                                ����         
                                                ����         
          !      "      #      $                     ����      %         
   &      '      (      )            *                     ����	         
   +      ,      -      .      /      0      1                             ����         
         2      3      4      5                   !   ����         
   6      2      7      4      8                   "   ����         
   9            :      ;      <             conn_count             conns     #          $   #                     $   %                     $   &                     (   '                     (   )                    node_paths              editable_instances              version             RSRC     RSRC                    PackedScene            ��������                                                  ..    . 	   position    resource_local_to_scene    resource_name    lightmap_size_hint 	   material    custom_aabb    flip_faces    add_uv2    uv2_padding    radius    height    radial_segments    rings    script    custom_solver_bias    margin    properties/0/path    properties/0/spawn    properties/0/replication_mode 	   _bundled       Script    res://Player.gd ��������   Script $   res://addons/smoothing/smoothing.gd ��������      local://CapsuleMesh_ptfmv �         local://CylinderShape3D_fj8ky �      %   local://SceneReplicationConfig_r0gdr          local://PackedScene_2p7s0 p         CapsuleMesh             CylinderShape3D             SceneReplicationConfig                                             PackedScene          	         names "         Player    script    CharacterBody3D 
   Smoothing    Node3D 	   CamPivot 
   transform    metadata/_edit_group_ 	   Camera3D    fov    MeshInstance3D    mesh 	   skeleton 
   NameLabel 
   billboard    text    Label3D    IdLabel 
   font_size    CollisionShape3D    shape    MultiplayerSynchronizer    replication_config    	   variants                               �?              �?              �?       ?               �?              �?              �?          @@     �B                             �?              �?              �?    ff�?                the opps catch you lackin      �?              �?              �?    ף�?                                  node_count    	         nodes     _   ��������       ����                            ����                          ����                                ����         	                 
   
   ����                                ����            	      
                    ����            	                           ����                           ����                   conn_count              conns               node_paths              editable_instances              version             RSRCextends Node

var players = {}
var multiplayer_unique_id

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
        GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�H�$�n윦���z�x����դ�<����q����F��Z��?&,
ScI_L �;����In#Y��0�p~��Z��m[��N����R,��#"� )���d��mG�������ڶ�$�ʹ���۶�=���mϬm۶mc�9��z��T��7�m+�}�����v��ح�m�m������$$P�����එ#���=�]��SnA�VhE��*JG�
&����^x��&�+���2ε�L2�@��		��S�2A�/E���d"?���Dh�+Z�@:�Gk�FbWd�\�C�Ӷg�g�k��Vo��<c{��4�;M�,5��ٜ2�Ζ�yO�S����qZ0��s���r?I��ѷE{�4�Ζ�i� xK�U��F�Z�y�SL�)���旵�V[�-�1Z�-�1���z�Q�>�tH�0��:[RGň6�=KVv�X�6�L;�N\���J���/0u���_��U��]���ǫ)�9��������!�&�?W�VfY�2���༏��2kSi����1!��z+�F�j=�R�O�{�
ۇ�P-�������\����y;�[ ���lm�F2K�ޱ|��S��d)é�r�BTZ)e�� ��֩A�2�����X�X'�e1߬���p��-�-f�E�ˊU	^�����T�ZT�m�*a|	׫�:V���G�r+�/�T��@U�N׼�h�+	*�*sN1e�,e���nbJL<����"g=O��AL�WO!��߈Q���,ɉ'���lzJ���Q����t��9�F���A��g�B-����G�f|��x��5�'+��O��y��������F��2�����R�q�):VtI���/ʎ�UfěĲr'�g�g����5�t�ۛ�F���S�j1p�)�JD̻�ZR���Pq�r/jt�/sO�C�u����i�y�K�(Q��7őA�2���R�ͥ+lgzJ~��,eA��.���k�eQ�,l'Ɨ�2�,eaS��S�ԟe)��x��ood�d)����h��ZZ��`z�պ��;�Cr�rpi&��՜�Pf��+���:w��b�DUeZ��ڡ��iA>IN>���܋�b�O<�A���)�R�4��8+��k�Jpey��.���7ryc�!��M�a���v_��/�����'��t5`=��~	`�����p\�u����*>:|ٻ@�G�����wƝ�����K5�NZal������LH�]I'�^���+@q(�q2q+�g�}�o�����S߈:�R�݉C������?�1�.��
�ڈL�Fb%ħA ����Q���2�͍J]_�� A��Fb�����ݏ�4o��'2��F�  ڹ���W�L |����YK5�-�E�n�K�|�ɭvD=��p!V3gS��`�p|r�l	F�4�1{�V'&����|pj� ߫'ş�pdT�7`&�
�1g�����@D�˅ �x?)~83+	p �3W�w��j"�� '�J��CM�+ �Ĝ��"���4� ����nΟ	�0C���q'�&5.��z@�S1l5Z��]�~L�L"�"�VS��8w.����H�B|���K(�}
r%Vk$f�����8�ڹ���R�dϝx/@�_�k'�8���E���r��D���K�z3�^���Vw��ZEl%~�Vc���R� �Xk[�3��B��Ğ�Y��A`_��fa��D{������ @ ��dg�������Mƚ�R�`���s����>x=�����	`��s���H���/ū�R�U�g�r���/����n�;�SSup`�S��6��u���⟦;Z�AN3�|�oh�9f�Pg�����^��g�t����x��)Oq�Q�My55jF����t9����,�z�Z�����2��#�)���"�u���}'�*�>�����ǯ[����82һ�n���0�<v�ݑa}.+n��'����W:4TY�����P�ר���Cȫۿ�Ϗ��?����Ӣ�K�|y�@suyo�<�����{��x}~�����~�AN]�q�9ޝ�GG�����[�L}~�`�f%4�R!1�no���������v!�G����Qw��m���"F!9�vٿü�|j�����*��{Ew[Á��������u.+�<���awͮ�ӓ�Q �:�Vd�5*��p�ioaE��,�LjP��	a�/�˰!{g:���3`=`]�2��y`�"��N�N�p���� ��3�Z��䏔��9"�ʞ l�zP�G�ߙj��V�>���n�/��׷�G��[���\��T��Ͷh���ag?1��O��6{s{����!�1�Y�����91Qry��=����y=�ٮh;�����[�tDV5�chȃ��v�G ��T/'XX���~Q�7��+[�e��Ti@j��)��9��J�hJV�#�jk�A�1�^6���=<ԧg�B�*o�߯.��/�>W[M���I�o?V���s��|yu�xt��]�].��Yyx�w���`��C���pH��tu�w�J��#Ef�Y݆v�f5�e��8��=�٢�e��W��M9J�u�}]釧7k���:�o�����Ç����ս�r3W���7k���e�������ϛk��Ϳ�_��lu�۹�g�w��~�ߗ�/��ݩ�-�->�I�͒���A�	���ߥζ,�}�3�UbY?�Ӓ�7q�Db����>~8�]
� ^n׹�[�o���Z-�ǫ�N;U���E4=eȢ�vk��Z�Y�j���k�j1�/eȢK��J�9|�,UX65]W����lQ-�"`�C�.~8ek�{Xy���d��<��Gf�ō�E�Ӗ�T� �g��Y�*��.͊e��"�]�d������h��ڠ����c�qV�ǷN��6�z���kD�6�L;�N\���Y�����
�O�ʨ1*]a�SN�=	fH�JN�9%'�S<C:��:`�s��~��jKEU�#i����$�K�TQD���G0H�=�� �d�-Q�H�4�5��L�r?����}��B+��,Q�yO�H�jD�4d�����0*�]�	~�ӎ�.�"����%
��d$"5zxA:�U��H���H%jس{���kW��)�	8J��v�}�rK�F�@�t)FXu����G'.X�8�KH;���[             [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://crqr365fyi5b4"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
                extends Control

var ip_addr:String = "127.0.0.1"
var port:int = 12345
var peer:ENetMultiplayerPeer

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func player_connected(id): #Server and Client
	print("Player Connected: "+str(id))
	$ErrorLog.text = "player connected: "+str(id)

func player_disconnected(id): #Server and Client
	print("Player Disconnected: "+str(id))

func connected_to_server(): #Clients
	print("Connected to server")
	send_player_info.rpc_id(1, $UsernameTextbox.text, multiplayer.get_unique_id())

func connection_failed(): #Clients
	push_warning("Failed to connect: "+str(self))

@rpc("any_peer")
func send_player_info(playername:String, id:int):
	if not GameManager.players.has(id):
		GameManager.players[id] = {
			"name": playername,
			"id": id,
		}
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i)

@rpc("any_peer","call_local")
func start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(delta):
	pass

func check_username():
	$ErrorLog.text = ""
	if $UsernameTextbox.text == "":
		$ErrorLog.text = "no username entered"
		return false
	peer = ENetMultiplayerPeer.new()
	return true

func connection_procedure():
	$StartButton.text = "start multiplayer game"
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	GameManager.multiplayer_unique_id = multiplayer.get_unique_id()
	$HostButton.visible = false
	$JoinButton.visible = false
	

func _on_host_pressed():
	print("--Hosting Game--")
	if not port:
		$ErrorLog.text = "no port entered"
		return
	
	if not check_username(): return
	var error = peer.create_server(port)
	var error_name:String
	match error:
		0:
			error_name = "OK (hosting was successful)"
		20:
			error_name = "ERR_CANT_CREATE (can't create a host for whatever reason)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you're already hosting)"
	$ErrorLog.text = "hosting status: "+error_name
	if error != OK: return
	connection_procedure()
	send_player_info($UsernameTextbox.text, multiplayer.get_unique_id())
	print("Waiting for Players...")


func _on_join_pressed():
	if not port:
		$ErrorLog.text = "no port entered"
		return
	if ip_addr == "":
		$ErrorLog.text = "no ip entered"
		return
	if not check_username(): return
	print("--Joining Game--")
	var error = peer.create_client(ip_addr, port)
	var error_name:String
	match error:
		0:
			error_name = "OK (joining was successful)"
		20:
			error_name = "ERR_CANT_CREATE (server with that IP probably doesnt exist/isnt reachable)"
		22:
			error_name = "ERR_ALREADY_IN_USE (you probably already joined)"
	$ErrorLog.text = "joining status: "+error_name
	connection_procedure()
	$StartButton.visible = false
	$WaitingForHostLabel.visible = true
	if error != OK: return


func _on_start_game_pressed():
	start_game.rpc()


func _on_ip_textbox_text_changed(new_text):
	ip_addr = new_text

func _on_port_textbox_text_changed(new_text):
	port = int(new_text)
         extends CharacterBody3D

var multiplayer_id:int
var main_character:bool
var is_host:bool

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

@onready var cam_pivot = $Smoothing/CamPivot
@onready var camera = $Smoothing/CamPivot/Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$MultiplayerSynchronizer.set_multiplayer_authority(multiplayer_id)

func _unhandled_input(event):
	if not main_character: return
	if event is InputEventMouseMotion and can_move_cam:
		rotate_y(-event.relative.x * active_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * active_sensitivity)
		cam_pivot.rotation.x = clamp (cam_pivot.rotation.x, -1.5708, 1.5708)
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT when not third_person:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				can_move_cam = true
			MOUSE_BUTTON_RIGHT when event.is_pressed():
				can_move_cam = true
				cursor_pos = get_viewport().get_mouse_position()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			MOUSE_BUTTON_RIGHT when event.is_released() and third_person:
				can_move_cam = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				get_viewport().warp_mouse(cursor_pos)
			MOUSE_BUTTON_WHEEL_DOWN:
				if camera.position.z == 0:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					can_move_cam = false
				camera.position.z += 0.2
				camera.position.z = clamp(camera.position.z,0,8)
			MOUSE_BUTTON_WHEEL_UP:
				camera.position.z -= 0.2
				camera.position.z = clamp(camera.position.z,0,8)
				if camera.position.z == 0:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
					can_move_cam = true
		
		if camera.position.z == 0:
			third_person = false
			active_sensitivity = FIRSTPRS_SENSITIVITY
		else:
			third_person = true
			active_sensitivity = THIRDPRS_SENSITIVITY
		

func _input(event):
	if not main_character: return
	if Input.is_action_just_pressed("Esc"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_pressed("Run"):
		speed = RUN_SPEED
	else:
		speed = WALK_SPEED

func _physics_process(delta):
	if not main_character: return
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left","Right","Forward","Backward")
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
  [remap]

path="res://.godot/exported/133200997/export-3ad5c15c4f3250da0cc7c1af1770d85f-main.scn"
               [remap]

path="res://.godot/exported/133200997/export-9dd0d80496426189d5c914f2baa5c033-multiplayer_menu.scn"
   [remap]

path="res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn"
             list=Array[Dictionary]([])
     <svg height="128" width="128" xmlns="http://www.w3.org/2000/svg"><rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#212532" stroke-width="4"/><g transform="scale(.101) translate(122 122)"><g fill="#fff"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 813 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H447l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c3 34 55 34 58 0v-86c-3-34-55-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></g></svg>
             UP<��W$   res://addons/smoothing/smoothing.png���>���'   res://addons/smoothing/smoothing_2d.png���\�v   res://scenes/main.tscn�'��xX�"   res://scenes/multiplayer_menu.tscn��W$Y�js   res://scenes/player.tscn��'��DS   res://icon.svg           ECFG      application/config/name         3d tutorial    application/run/main_scene,      "   res://scenes/multiplayer_menu.tscn     application/config/features   "         4.2    Mobile     application/config/icon         res://icon.svg     autoload/GameManager          *res://GameManager.gd      dotnet/project/assembly_name         3d tutorial    editor_plugins/enabled0   "      "   res://addons/smoothing/plugin.cfg      input/Forward�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   W   	   key_label             unicode    w      echo          script         input/Backward�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   S   	   key_label             unicode    s      echo          script      
   input/Left�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   A   	   key_label             unicode    a      echo          script         input/Right�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode   D   	   key_label             unicode    d      echo          script      
   input/Jump�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode       	   key_label             unicode           echo          script      	   input/Esc�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script      	   input/Run�              deadzone      ?      events              InputEventKey         resource_local_to_scene           resource_name             device     ����	   window_id             alt_pressed           shift_pressed             ctrl_pressed          meta_pressed          pressed           keycode           physical_keycode    @ 	   key_label             unicode           echo          script      #   rendering/renderer/rendering_method         mobile      