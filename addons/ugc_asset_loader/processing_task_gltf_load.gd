extends "./processing_task.gd"

var extensions_by_file_type = {
	"gltf": [GLTFDocumentExtensionConvertImporterMesh],
	"glb": [GLTFDocumentExtensionConvertImporterMesh],
}

func _perform() -> bool:
	var src_gltf_file: String = input_disk_path
	var extn = src_gltf_file.get_extension().to_lower()
	if not extensions_by_file_type.has(extn):
		return false
	var gltf: GLTFDocument = GLTFDocument.new()
	var flags: int
	flags |= EditorSceneFormatImporter.IMPORT_USE_NAMED_SKIN_BINDS
	for gltf_document_extension_class in extensions_by_file_type[extn]:
		gltf.register_gltf_document_extension(gltf_document_extension_class.new())
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
	if not output_res_path.is_empty():
		ResourceSaver.save(packed_scene, output_res_path, ResourceSaver.FLAG_COMPRESS)
	return true
