extends Control

onready var connect_cont = $Panel/CenterContainer/ConnectCont
onready var ip_input = $Panel/CenterContainer/ConnectCont/GridContainer/IPInput
onready var port_input = $Panel/CenterContainer/ConnectCont/GridContainer/PInput

onready var main_cont = $Panel/CenterContainer/MainCont
onready var file_dialog = $FileDialog
onready var image_accept_dialog = $ImageAcceptDialog
onready var img_rect_texture = $Panel/CenterContainer/MainCont/Image

const MAX_PLAYERS = 25

var peer = null

var ip: String
var port: int

var file_path: String

var img_bytes_queue: Array = []

func _ready():
	main_cont.visible = false
	connect_cont.visible = true

func init_network_peer():
	peer = NetworkedMultiplayerENet.new()
	peer.connect("peer_connected", self, "_network_peer_connected")
	peer.connect("peer_disconnected", self, "_network_peer_disconnected")
	peer.connect("connection_succeeded", self, "_connected_to_server")
	peer.connect("connection_failed", self, "_connection_failed")
	peer.connect("server_disconnected", self, "_server_disconnected")

func exit_network_peer():
	peer.disconnect("peer_connected", self, "_peer_connected")
	peer.disconnect("peer_disconnected", self, "_peer_disconnected")
	# Client
	peer.disconnect("connection_succeeded", self, "_connection_succeeded")
	peer.disconnect("connection_failed", self, "_connection_failed")
	peer.disconnect("server_disconnected", self, "_server_disconnected")
	peer = null

func _on_ConnectBTN_pressed():
	if (ip_input.text.replace(" ", "") == "" || port_input.text.replace(" ", "") == ""):
		return
	connect_cont.visible = false
	ip = ip_input.text
	port = int(port_input.text)
	init_network_peer()
	peer.create_client(ip, port)
	get_tree().network_peer = peer

func _on_HostBTN_pressed():
	if (port_input.text.replace(" ", "") == ""):
		return
	connect_cont.visible = false
	port = int(port_input.text)
	init_network_peer()
	peer.create_server(port, MAX_PLAYERS)
	get_tree().network_peer = peer
	main_cont.visible = true

func _on_FileDialog_file_selected(path: String):
	file_path = path

func _on_SelectImageBTN_pressed():
	file_dialog.popup_centered()

func _on_SendBTN_pressed():
	if (file_path == ""):
		return
	var file = File.new()
	file.open(file_path, File.READ)
	var bytes = file.get_buffer(file.get_len())
	file.close()
	
	rpc("transfer_image", bytes)

func _on_IA_Dialog_CancelBTN_pressed():
	image_accept_dialog.visible = false
	img_bytes_queue.pop_front()

func _on_IA_Dialog_OKBTN_pressed():
	image_accept_dialog.visible = false
	var bytes = img_bytes_queue.pop_front()
	if (bytes == null):
		return
		
	var img = Image.new()
	img.load_png_from_buffer(bytes)
	var t = ImageTexture.new()
	t.create_from_image(img)
	
	img_rect_texture.texture = t

# Networking

func _network_peer_connected(id: int): # Server and Client
	print("Peer Connected ", id)

func _network_peer_disconnected(id: int): # Server and Client
	print("Peer Disconnected ", id)

func _connected_to_server(): # Client
	main_cont.visible = true

func _connection_failed(): # Client
	exit_network_peer()
	connect_cont.visible = true

func _server_disconnected(): # Client
	main_cont.visible = false
	exit_network_peer()
	connect_cont.visible = true

remotesync func transfer_image(bytes: PoolByteArray):
	img_bytes_queue.append(bytes)
	image_accept_dialog.popup_centered()
