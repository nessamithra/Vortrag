extends Control

var player = load("res://player/Player.tscn")

onready var multiplayer_config_ui = $Multiplayer_configure
onready var server_ip_adress = $Multiplayer_configure/Server_ip_adress

onready var device_ip_adress = $CanvasLayer/Device_ip_adress

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	
	device_ip_adress.text = Network.ip_adress

func _player_connected(id) -> void:
	print("Player " + str(id) + " has connected")
	
	instance_player(id)

func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free() 

func _on_Create_server_pressed():
	multiplayer_config_ui.hide()
	Network.create_server()
	
	instance_player(get_tree().get_network_unique_id())


func _on_Join_server_pressed():
	if server_ip_adress.text != "":
		multiplayer_config_ui.hide()
		Network.ip_adress = server_ip_adress.text
		Network.join_server()

func _connected_to_server() -> void:
	yield(get_tree().create_timer(0.1), "timeout")
	instance_player(get_tree().get_network_unique_id())

func instance_player(id) -> void:
	var player_instance = Global.instance_node_at_location(player, Players, 
	Vector2(rand_range(0,1024), rand_range(0,600)))
	player_instance.name = str(id)
	player_instance.set_network_master(id)
