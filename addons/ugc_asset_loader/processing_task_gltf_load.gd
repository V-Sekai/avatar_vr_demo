extends "./processing_task.gd"

const vrm_0_extension = preload("res://addons/vrm/vrm_extension.gd")

# FIXME: Godot register_gltf_document_extension is global.
var extensions_by_file_type = {
	"gltf": [],
	"glb": [],
	"vrm": []
}


func _init():
	var extensions_to_add: Array = []
	if DirAccess.open("res://").dir_exists("res://addons/vrm"):
		var VRMC_node_constraint = load("res://addons/vrm/1.0/VRMC_node_constraint.gd")
		var VRMC_springBone = load("res://addons/vrm/1.0/VRMC_springBone.gd")
		var VRMC_materials_mtoon = load("res://addons/vrm/1.0/VRMC_materials_mtoon.gd")
		var VRMC_materials_hdr_emissiveMultiplier = load("res://addons/vrm/1.0/VRMC_materials_hdr_emissiveMultiplier.gd")
		var VRMC_vrm = load("res://addons/vrm/1.0/VRMC_vrm.gd")
		var VRMC_vrm_animation = load("res://addons/vrm/1.0/VRMC_vrm_animation.gd")
		var vrm_0_extensions = load("res://addons/vrm/vrm_extension.gd")
		extensions_to_add = [
			vrm_0_extensions,
			VRMC_vrm,
			VRMC_vrm_animation,
			VRMC_node_constraint,
			VRMC_springBone,
			VRMC_materials_mtoon,
			VRMC_materials_hdr_emissiveMultiplier,
		]
	extensions_to_add.append(GLTFDocumentExtensionConvertImporterMesh) # Do we need this?
	extensions_to_add.reverse()
	# how to avvoid adding duplicate copis of the vrm extensions?
	# the apis here are absurd
	var registered_extensions: Dictionary = OS.get_meta(&"registered_gltf_extensions", {})
	for ext in extensions_to_add:
		if not registered_extensions.has(ext):
			GLTFDocument.register_gltf_document_extension(ext.new(), true)
			registered_extensions[ext] = true
	OS.set_meta(&"registered_gltf_extensions", registered_extensions)

func _perform() -> bool:
	var src_gltf_file: String = input_disk_path
	var extn = src_gltf_file.get_extension().to_lower()
	if not extensions_by_file_type.has(extn):
		return false
	var gltf: GLTFDocument = GLTFDocument.new()
	var flags: int
	flags |= EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS
	#for gltf_document_extension_class in extensions_by_file_type[extn]:
	#	gltf.register_gltf_document_extension(gltf_document_extension_class.new())
	var state: GLTFState = GLTFState.new()
	# HANDLE_BINARY_EMBED_AS_BASISU crashes on some files in 4.0 and 4.1
	state.handle_binary_image = GLTFState.HANDLE_BINARY_EMBED_AS_UNCOMPRESSED  # GLTFState.HANDLE_BINARY_EXTRACT_TEXTURES
	var err: Error = gltf.append_from_file(src_gltf_file, state, flags)
	if err != OK:
		return false
	var generated_scene: Node = gltf.generate_scene(state)
	if generated_scene == null:
		return false
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(generated_scene)
	output_resource = packed_scene
	print("OUTPUT RES " + str(output_res_path))
	if not output_res_path.is_empty():
		err = ResourceSaver.save(packed_scene, output_res_path + ".res", ResourceSaver.FLAG_COMPRESS)
		if err != OK:
			push_error("Failed to save " + str(output_res_path) + ": " + str(err))
			return false
		DirAccess.open("user://").rename_absolute(output_res_path + ".res", output_res_path)
	return true
