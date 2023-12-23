extends Control

func set_crosshair_highlighted(p_is_highlight: bool) -> void:
	$CenterContainer/Crosshair.color = Color.RED if p_is_highlight else Color.WHITE

func _update_menu_visibility() -> void:
	# Can't call GameManager singleton directly yet due to circular dependency.
	if get_node("/root/GameManager").ingame_menu_visible:
		$ToggleMenu.show()
	else:
		$ToggleMenu.hide()

func assign_peer_color(p_color: Color) -> void:
	$PeerBoxContainer/PeerColorID.color = p_color

func _physics_process(_delta) -> void:
	if Input.is_action_pressed("interact"):
		$InfoContainer/InteractInfo.set("theme_override_colors/font_color", Color.RED)
	else:
		$InfoContainer/InteractInfo.set("theme_override_colors/font_color", Color.WHITE)
	
	if Input.is_action_pressed("block_physics_send"):
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.RED)
	else:
		$InfoContainer/BlockPhysicsUpdatesInfo.set("theme_override_colors/font_color", Color.WHITE)

func _ready():
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: %s" % str(multiplayer.get_unique_id()))
	else:
		$PeerBoxContainer/PeerIDLabel.set_text("Peer ID: UNASSIGNED")

func _on_disconnect_button_pressed():
	get_node("/root/GameManager").close_connection()
