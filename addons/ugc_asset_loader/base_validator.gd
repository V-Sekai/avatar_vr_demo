# Copyright (c) 2018-present. This file is part of V-Sekai https://v-sekai.org/.
# SaracenOne & K. S. Ernest (Fire) Lee & Lyuma & MMMaellon & Contributors
# vsk_map_validator.gd
# SPDX-License-Identifier: MIT

@tool
extends RefCounted

# FIXME: dictionary cannot be const????
var valid_node_whitelist: Dictionary = {
	"Node3D": Node3D,
	"Node": Node,
	"SubViewport": SubViewport,
	"StaticBody3D": StaticBody3D,
	"AnimatableBody3D": AnimatableBody3D,
	"CharacterBody3D": CharacterBody3D,
	"PhysicalBone3D": PhysicalBone3D,
	"RigidBody3D": RigidBody3D,
	"VehicleBody3D": VehicleBody3D,
	"Area3D": Area3D,
	"AnimatedSprite3D": AnimatedSprite3D,
	"Sprite3D": Sprite3D,
	"CSGBox3D": CSGBox3D,
	"CSGCylinder3D": CSGCylinder3D,
	"CSGMesh3D": CSGMesh3D,
	"CSGPolygon3D": CSGPolygon3D,
	"CSGSphere3D": CSGSphere3D,
	"CSGTorus3D": CSGTorus3D,
	"CSGCombiner3D": CSGCombiner3D,
	"GPUParticles3D": GPUParticles3D,
	"Label3D": Label3D,
	"MeshInstance3D": MeshInstance3D,
	"SoftBody3D": SoftBody3D,
	"MultiMeshInstance3D": MultiMeshInstance3D,
	"Decal": Decal,
	"DirectionalLight3D": DirectionalLight3D,
	"OmniLight3D": OmniLight3D,
	"SpotLight3D": SpotLight3D,
	"FogVolume": FogVolume,
	"GPUParticlesAttractorBox3D": GPUParticlesAttractorBox3D,
	"GPUParticlesAttractorSphere3D": GPUParticlesAttractorSphere3D,
	"GPUParticlesAttractorVectorField3D": GPUParticlesAttractorVectorField3D,
	"GPUParticlesCollisionBox3D": GPUParticlesCollisionBox3D,
	"GPUParticlesCollisionHeightField3D": GPUParticlesCollisionHeightField3D,
	"GPUParticlesCollisionSDF3D": GPUParticlesCollisionSDF3D,
	"GPUParticlesCollisionSphere3D": GPUParticlesCollisionSphere3D,
	"LightmapGI": LightmapGI,
	"ReflectionProbe": ReflectionProbe,
	"VoxelGI": VoxelGI,
	"AudioListener3D": AudioListener3D,
	"AudioStreamPlayer3D": AudioStreamPlayer3D,
	"BoneAttachment3D": BoneAttachment3D,
	"Camera3D": Camera3D,
	"CollisionPolygon3D": CollisionPolygon3D,
	"CollisionShape3D": CollisionShape3D,
	"ConeTwistJoint3D": ConeTwistJoint3D,
	"Generic6DOFJoint3D": Generic6DOFJoint3D,
	"HingeJoint3D": HingeJoint3D,
	"PinJoint3D": PinJoint3D,
	"SliderJoint3D": SliderJoint3D,
	"GridMap": GridMap,
	"LightmapProbe": LightmapProbe,
	"Marker3D": Marker3D,
	"OccluderInstance3D": OccluderInstance3D,
	"Path3D": Path3D,
	"PathFollow3D": PathFollow3D,
	"RayCast3D": RayCast3D,
	"RemoteTransform3D": RemoteTransform3D,
	"ShapeCast3D": ShapeCast3D,
	"Skeleton3D": Skeleton3D,
	"SpringArm3D": SpringArm3D,
	"VehicleWheel3D": VehicleWheel3D,
	"WorldEnvironment": WorldEnvironment,
	"SkeletonIK3D": SkeletonIK3D,
	"ShaderGlobalsOverride": ShaderGlobalsOverride,
	"ResourcePreloader": ResourcePreloader,
	"AudioStreamPlayer": AudioStreamPlayer,
	"AnimationTree": AnimationTree,
	"AnimationPlayer": AnimationPlayer,
}

#NavigationAgent3D
#NavigationAgent2D
#NavigationLink3D
#NavigationObstacle3D
#NavigationRegion3D
#LinkButton
#TextureButton
#CodeEdit
#GraphEdit

var valid_canvas_node_whitelist: Dictionary = {
	"Node2D": Node2D,
	"StaticBody2D": StaticBody2D,
	"AnimatableBody2D": AnimatableBody2D,
	"CharacterBody2D": CharacterBody2D,
	"RigidBody2D": RigidBody2D,
	"PhysicalBone2D": PhysicalBone2D,
	"Area2D": Area2D,
	"AnimatedSprite2D": AnimatedSprite2D,
	"AudioListener2D": AudioListener2D,
	"AudioStreamPlayer2D": AudioStreamPlayer2D,
	"BackBufferCopy": BackBufferCopy,
	"Bone2D": Bone2D,
	"CPUParticles2D": CPUParticles2D,
	"Camera2D": Camera2D,
	"CanvasGroup": CanvasGroup,
	"CanvasModulate": CanvasModulate,
	"CollisionPolygon2D": CollisionPolygon2D,
	"CollisionShape2D": CollisionShape2D,
	"DampedSpringJoint2D": DampedSpringJoint2D,
	"GrooveJoint2D": GrooveJoint2D,
	"PinJoint2D": PinJoint2D,
	"DirectionalLight2D": DirectionalLight2D,
	"PointLight2D": PointLight2D,
	"GPUParticles2D": GPUParticles2D,
	"LightOccluder2D": LightOccluder2D,
	"Line2D": Line2D,
	"Marker2D": Marker2D,
	"MeshInstance2D": MeshInstance2D,
	"MultiMeshInstance2D": MultiMeshInstance2D,
	"NavigationLink2D": NavigationLink2D,
	"NavigationObstacle2D": NavigationObstacle2D,
	"NavigationRegion2D": NavigationRegion2D,
	"ParallaxLayer": ParallaxLayer,
	"Path2D": Path2D,
	"PathFollow2D": PathFollow2D,
	"Polygon2D": Polygon2D,
	"RayCast2D": RayCast2D,
	"RemoteTransform2D": RemoteTransform2D,
	"ShapeCast2D": ShapeCast2D,
	"Skeleton2D": Skeleton2D,
	"Sprite2D": Sprite2D,
	"TileMap": TileMap,
	"Control": Control,
	"Container": Container,
	"AspectRatioContainer": AspectRatioContainer,
	"BoxContainer": BoxContainer,
	"VBoxContainer": VBoxContainer,
	"ColorPicker": ColorPicker,
	"HBoxContainer": HBoxContainer,
	"CenterContainer": CenterContainer,
	"FlowContainer": FlowContainer,
	"HFlowContainer": HFlowContainer,
	"VFlowContainer": VFlowContainer,
	"GridContainer": GridContainer,
	"SplitContainer": SplitContainer,
	"HSplitContainer": HSplitContainer,
	"VSplitContainer": VSplitContainer,
	"MarginContainer": MarginContainer,
	"PanelContainer": PanelContainer,
	"ScrollContainer": ScrollContainer,
	"SubViewportContainer": SubViewportContainer,
	"TabContainer": TabContainer,
	"Button": Button,
	"CheckBox": CheckBox,
	"CheckButton": CheckButton,
	"MenuButton": MenuButton,
	"OptionButton": OptionButton,
	"TextEdit": TextEdit,
	"HScrollBar": HScrollBar,
	"VScrollBar": VScrollBar,
	"HSlider": HSlider,
	"VSlider": VSlider,
	"ItemList": ItemList,
	"Label": Label,
	"LineEdit": LineEdit,
	"NinePatchRect": NinePatchRect,
	"Panel": Panel,
	"ReferenceRect": ReferenceRect,
	"RichTextLabel": RichTextLabel,
	"TabBar": TabBar,
	"TextureRect": TextureRect,
	"Tree": Tree,
	"VideoStreamPlayer": VideoStreamPlayer,
}

#NavigationMesh
#NavigationPolygon

var valid_resource_whitelist: Dictionary= {
	"Resource": Resource,
	"AnimatedTexture": AnimatedTexture,
	"AtlasTexture": AtlasTexture,
	"CanvasTexture": CanvasTexture,
	"CompressedTexture2D": CompressedTexture2D,
	"CurveTexture": CurveTexture,
	"CurveXYZTexture": CurveXYZTexture,
	"GradientTexture1D": GradientTexture1D,
	"GradientTexture2D": GradientTexture2D,
	"ImageTexture": ImageTexture,
	"MeshTexture": MeshTexture,
	"NoiseTexture2D": NoiseTexture2D,
	"PlaceholderTexture2D": PlaceholderTexture2D,
	"PortableCompressedTexture2D": PortableCompressedTexture2D,
	"ViewportTexture": ViewportTexture,
	"CompressedCubemap": CompressedCubemap,
	"CompressedCubemapArray": CompressedCubemapArray,
	"CompressedTexture2DArray": CompressedTexture2DArray,
	"Cubemap": Cubemap,
	"CubemapArray": CubemapArray,
	"Texture2DArray": Texture2DArray,
	"PlaceholderCubemap": PlaceholderCubemap,
	"PlaceholderCubemapArray": PlaceholderCubemapArray,
	"PlaceholderTexture2DArray": PlaceholderTexture2DArray,
	"CompressedTexture3D": CompressedTexture3D,
	"ImageTexture3D": ImageTexture3D,
	"NoiseTexture3D": NoiseTexture3D,
	"PlaceholderTexture3D": PlaceholderTexture3D,
	"Animation": Animation,
	"AnimationLibrary": AnimationLibrary,
	"AnimationNode": AnimationNode,
	"AnimationNodeSync": AnimationNodeSync,
	"AnimationNodeAdd2": AnimationNodeAdd2,
	"AnimationNodeAdd3": AnimationNodeAdd3,
	"AnimationNodeBlend2": AnimationNodeBlend2,
	"AnimationNodeBlend3": AnimationNodeBlend3,
	"AnimationNodeOneShot": AnimationNodeOneShot,
	"AnimationNodeSub2": AnimationNodeSub2,
	"AnimationNodeTransition": AnimationNodeTransition,
	"AnimationRootNode": AnimationRootNode,
	"AnimationNodeAnimation": AnimationNodeAnimation,
	"AnimationNodeBlendSpace1D": AnimationNodeBlendSpace1D,
	"AnimationNodeBlendSpace2D": AnimationNodeBlendSpace2D,
	"AnimationNodeBlendTree": AnimationNodeBlendTree,
	"AnimationNodeStateMachine": AnimationNodeStateMachine,
	"AnimationNodeOutput": AnimationNodeOutput,
	"AnimationNodeTimeScale": AnimationNodeTimeScale,
	"AnimationNodeTimeSeek": AnimationNodeTimeSeek,
	"AnimationNodeStateMachineTransition": AnimationNodeStateMachineTransition,
	"ArrayMesh": ArrayMesh,
	"BoxMesh": BoxMesh,
	"CapsuleMesh": CapsuleMesh,
	"PlaneMesh": PlaneMesh,
	"QuadMesh": QuadMesh,
	"PointMesh": PointMesh,
	"PrismMesh": PrismMesh,
	"RibbonTrailMesh": RibbonTrailMesh,
	"SphereMesh": SphereMesh,
	"TextMesh": TextMesh,
	"TorusMesh": TorusMesh,
	"TubeTrailMesh": TubeTrailMesh,
	"ImmediateMesh": ImmediateMesh,
	"PlaceholderMesh": PlaceholderMesh,
	"ArrayOccluder3D": ArrayOccluder3D,
	"BoxOccluder3D": BoxOccluder3D,
	"PolygonOccluder3D": PolygonOccluder3D,
	"QuadOccluder3D": QuadOccluder3D,
	"SphereOccluder3D": SphereOccluder3D,
	"AudioBusLayout": AudioBusLayout,
	"AudioEffectAmplify": AudioEffectAmplify,
	"AudioEffectFilter": AudioEffectFilter,
	"AudioEffectBandLimitFilter": AudioEffectBandLimitFilter,
	"AudioEffectBandPassFilter": AudioEffectBandPassFilter,
	"AudioEffectHighPassFilter": AudioEffectHighPassFilter,
	"AudioEffectHighShelfFilter": AudioEffectHighShelfFilter,
	"AudioEffectLowPassFilter": AudioEffectLowPassFilter,
	"AudioEffectLowShelfFilter": AudioEffectLowShelfFilter,
	"AudioEffectNotchFilter": AudioEffectNotchFilter,
	"AudioEffectCapture": AudioEffectCapture,
	"AudioEffectChorus": AudioEffectChorus,
	"AudioEffectCompressor": AudioEffectCompressor,
	"AudioEffectDelay": AudioEffectDelay,
	"AudioEffectDistortion": AudioEffectDistortion,
	"AudioEffectEQ": AudioEffectEQ,
	"AudioEffectEQ10": AudioEffectEQ10,
	"AudioEffectEQ21": AudioEffectEQ21,
	"AudioEffectEQ6": AudioEffectEQ6,
	"AudioEffectLimiter": AudioEffectLimiter,
	"AudioEffectPanner": AudioEffectPanner,
	"AudioEffectPhaser": AudioEffectPhaser,
	"AudioEffectPitchShift": AudioEffectPitchShift,
	"AudioEffectReverb": AudioEffectReverb,
	"AudioEffectSpectrumAnalyzer": AudioEffectSpectrumAnalyzer,
	"AudioEffectStereoEnhance": AudioEffectStereoEnhance,
	"AudioStream": AudioStream,
	"AudioStreamMP3": AudioStreamMP3,
	"AudioStreamOggVorbis": AudioStreamOggVorbis,
	"AudioStreamPolyphonic": AudioStreamPolyphonic,
	"AudioStreamRandomizer": AudioStreamRandomizer,
	"AudioStreamWAV": AudioStreamWAV,
	"BitMap": BitMap,
	"BoneMap": BoneMap,
	"BoxShape3D": BoxShape3D,
	"CapsuleShape3D": CapsuleShape3D,
	"ConcavePolygonShape3D": ConcavePolygonShape3D,
	"ConvexPolygonShape3D": ConvexPolygonShape3D,
	"CylinderShape3D": CylinderShape3D,
	"HeightMapShape3D": HeightMapShape3D,
	"SeparationRayShape3D": SeparationRayShape3D,
	"SphereShape3D": SphereShape3D,
	"WorldBoundaryShape3D": WorldBoundaryShape3D,
	"ButtonGroup": ButtonGroup,
	"CameraAttributesPhysical": CameraAttributesPhysical,
	"CameraAttributesPractical": CameraAttributesPractical,
	"CanvasItemMaterial": CanvasItemMaterial,
	"FogMaterial": FogMaterial,
	"ORMMaterial3D": ORMMaterial3D,
	"StandardMaterial3D": StandardMaterial3D,
	"PanoramaSkyMaterial": PanoramaSkyMaterial,
	"ParticleProcessMaterial": ParticleProcessMaterial,
	"PhysicalSkyMaterial": PhysicalSkyMaterial,
	"ProceduralSkyMaterial": ProceduralSkyMaterial,
	"PlaceholderMaterial": PlaceholderMaterial,
	"ShaderMaterial": ShaderMaterial,
	"CapsuleShape2D": CapsuleShape2D,
	"CircleShape2D": CircleShape2D,
	"ConcavePolygonShape2D": ConcavePolygonShape2D,
	"ConvexPolygonShape2D": ConvexPolygonShape2D,
	"RectangleShape2D": RectangleShape2D,
	"SegmentShape2D": SegmentShape2D,
	"SeparationRayShape2D": SeparationRayShape2D,
	"WorldBoundaryShape2D": WorldBoundaryShape2D,
	"Curve": Curve,
	"Curve2D": Curve2D,
	"Curve3D": Curve3D,
	"Environment": Environment,
	"FastNoiseLite": FastNoiseLite,
	"FontFile": FontFile,
	"FontVariation": FontVariation,
	"Gradient": Gradient,
	"Image": Image,
	"JSON": JSON,
	"LabelSettings": LabelSettings,
	"LightmapGIData": LightmapGIData,
	"MeshLibrary": MeshLibrary,
	"MultiMesh": MultiMesh,
	"OccluderPolygon2D": OccluderPolygon2D,
	"OggPacketSequence": OggPacketSequence,
	"PackedDataContainer": PackedDataContainer,
	"PackedScene": PackedScene,
	"PhysicsMaterial": PhysicsMaterial,
	"Shader": Shader,
	"ShaderInclude": ShaderInclude,
	"SkeletonProfile": SkeletonProfile,
	"SkeletonProfileHumanoid": SkeletonProfileHumanoid,
	"Skin": Skin,
	"Sky": Sky,
	"SpriteFrames": SpriteFrames,
	"StyleBoxEmpty": StyleBoxEmpty,
	"StyleBoxFlat": StyleBoxFlat,
	"StyleBoxLine": StyleBoxLine,
	"StyleBoxTexture": StyleBoxTexture,
	"Theme": Theme,
	"TileMapPattern": TileMapPattern,
	"TileSet": TileSet,
	"TileSetAtlasSource": TileSetAtlasSource,
	"VideoStreamTheora": VideoStreamTheora,
	"VoxelGIData": VoxelGIData,
	"World2D": World2D,
	"World3D": World3D,
}

const valid_external_path_whitelist: Dictionary = {
	"res://addons/entity_manager/entity.gd": true,
	"res://addons/vsk_entities/vsk_interactable_prop.tscn": true,
	"res://addons/network_manager/network_spawn.gd": true,
	"res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd": true,
	"res://addons/vsk_importer_exporter/vsk_pipeline.gd": true,
	"res://addons/vsk_map/vsk_map_definition.gd": true,
	"res://addons/vsk_map/vsk_map_definition_runtime.gd": true,
	"res://vsk_default/audio/sfx/basketball_drop.wav": true,
	"res://vsk_default/import/beachball/Scene_-_Root.tres": true,
	"res://vsk_default/import/basketball_reexport/Scene_-_Root.tres": true,
	"res://addons/vsk_map/vsk_map_entity_instance_record.gd": true,
	"res://addons/network_manager/network_identity.gd": true,
	"res://addons/vsk_entities/extensions/test_entity_rpc_table.gd": true,
	"res://addons/network_manager/network_logic.gd": true,
	"res://addons/vsk_entities/extensions/test_entity_simulation_logic.gd": true,
	"res://addons/entity_manager/transform_notification.gd": true,
	"res://addons/entity_manager/hierarchy_component.gd": true,
	"res://addons/vsk_entities/extensions/prop_simulation_logic.gd": true,
	"res://addons/network_manager/network_hierarchy.gd": true,
	"res://addons/network_manager/network_transform.gd": true,
	"res://addons/network_manager/network_model.gd": true,
	"res://addons/network_manager/network_physics.gd": true,
	"res://addons/smoothing/smoothing.gd": true,
	"res://addons/mirror/mirror.gd": true,
}

################
# Map Entities #
################

#var entity_script: Script = load("res://addons/entity_manager/entity.gd")
#const valid_entity_whitelist: Array[String] = ["res://addons/vsk_entities/vsk_interactable_prop.tscn"]


func get_external_path_whitelist() -> Dictionary:
	return valid_external_path_whitelist

func get_resource_class_whitelist() -> Dictionary:
	return valid_resource_whitelist

static func is_script_valid(p_script: Script, p_node_class: String) -> bool:
	var network_spawn_const = load("res://addons/network_manager/network_spawn.gd")

	var map_definition_runtime = load("res://addons/vsk_map/vsk_map_definition_runtime.gd")
	var map_definition = load("res://addons/vsk_map/vsk_map_definition.gd")
	var vsk_uro_pipeline = load("res://addons/vsk_importer_exporter/vsk_uro_pipeline.gd")

	var entity_identity = load("res://addons/network_manager/network_identity.gd")
	var entity_network_logic = load("res://addons/network_manager/network_logic.gd")
	var entity_transform_notification = load("res://addons/entity_manager/transform_notification.gd")
	var entity_entity = load("res://addons/entity_manager/entity.gd")

	var hierarchy_component = load("res://addons/entity_manager/hierarchy_component.gd")
	var network_hierarchy = load("res://addons/network_manager/network_hierarchy.gd")
	var network_transform = load("res://addons/network_manager/network_transform.gd")
	var network_model = load("res://addons/network_manager/network_model.gd")
	var network_physics = load("res://addons/network_manager/network_physics.gd")
	var smoothing = load("res://addons/smoothing/smoothing.gd")
	var mirror = load("res://addons/mirror/mirror.gd")
	
	if valid_external_path_whitelist.has(p_script.resource_path):
		if p_script is GDScript:
			if p_node_class == p_script.get_instance_base_type() or ClassDB.is_parent_class(p_node_class, p_script.get_instance_base_type()):
				return true

	push_warning("Validator: Script failed check " + str(p_script) + "/" + str(p_script.resource_path) + " node_class " + p_node_class)
	return false


func is_node_type_string_valid(p_class_str: String, p_child_of_canvas: bool) -> bool:
	if p_child_of_canvas:
		return valid_canvas_node_whitelist.has(p_class_str) or valid_node_whitelist.has(p_class_str)
	else:
		return valid_node_whitelist.has(p_class_str)

	push_warning("Validator: Unknown node type string " + p_class_str + " (canvas " + str(p_child_of_canvas) + ")")
	return false


#func is_path_an_entity(p_packed_scene_path: String) -> bool:
#	if valid_entity_whitelist.find(p_packed_scene_path) != -1:
#		return true
#	else:
#		return false
#
#
#func is_valid_entity_script(p_script: Script) -> bool:
#	if p_script == entity_script:
#		return true
#
#	push_warning("Validator: Unknown entity script " + str(p_script) + "/" + str(p_script.resource_path) + " not " + str(entity_script) + "/" + str(entity_script.resource_path))
#	return false


func validate_value_track(p_subnames: String, p_node_class: String) -> bool:
	match p_node_class:
		"MeshInstance3D":
			return check_basic_node_3d_value_targets(p_subnames)
		"Node3D":
			return check_basic_node_3d_value_targets(p_subnames)
		"DirectionalLight":
			return check_basic_node_3d_value_targets(p_subnames)
		"OmniLight":
			return check_basic_node_3d_value_targets(p_subnames)
		"SpotLight":
			return check_basic_node_3d_value_targets(p_subnames)
		"Camera3D":
			return check_basic_node_3d_value_targets(p_subnames)
		"GPUParticles3D":
			return check_basic_node_3d_value_targets(p_subnames)
		"CPUParticles":
			return check_basic_node_3d_value_targets(p_subnames)
		_:
			return false


static func check_basic_node_3d_value_targets(p_subnames: String) -> bool:
	match p_subnames:
		"position":
			return true
		"rotation":
			return true
		"scale":
			return true
		"transform":
			return true
		"visibility":
			return true

	return false

func is_scene_valid_for_root(p_script: Script) -> bool:
	if p_script == null:
		return true
	else:
		return false


func is_valid_canvas_3d(_script: Script, node_class: String) -> bool:
	return node_class == "SubViewport"


func is_valid_canvas_3d_anchor(_script: Script, _node_class: String) -> bool:
	return false

func get_name() -> String:
	return "BaseValidator"
