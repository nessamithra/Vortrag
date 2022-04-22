extends KinematicBody2D

enum STATE{
	IDLE,
	WALK
}

const speed = 300
var velocity = Vector2(0,0)

var current_state = STATE.IDLE setget set_current_state

puppet var puppet_position = Vector2(0,0) setget puppet_position_set
puppet var puppet_state = STATE.IDLE setget puppet_state_set
puppet var puppet_direction = Vector2(0,0) setget puppet_direction_set

onready var tween = $Tween
onready var animation_tree = $AnimationTree
onready var state_machine = animation_tree.get("parameters/playback")


func _physics_process(delta: float) -> void:
	if is_network_master():
		velocity = get_movement_input()
		move_and_slide(velocity * speed)
		
		if(velocity != Vector2.ZERO):
			update_animation_parameters(velocity)
			self.current_state = STATE.WALK
		else:
			self.current_state = STATE.IDLE
	else:
		var direction = puppet_direction
		
		if(tween.is_processing()):
			direction = Vector2()
			direction.x = get_direction(global_position.x, puppet_position.x)
			direction.y = get_direction(global_position.y, puppet_position.y)
		
		if(direction != Vector2.ZERO):
			update_animation_parameters(direction)
			self.current_state = STATE.WALK
		else:	
			if(global_position.distance_to(puppet_position) > 0.1 && tween.is_processing()):
				self.current_state = STATE.WALK
			else:
				self.current_state = STATE.IDLE

func get_direction(pos1, pos2) -> int:
	if(pos1 - pos2 > 0):
		return 1
	elif(pos1 - pos2 < 0):
		return -1
	else:
		return 0

func update_animation_parameters(velocity: Vector2) -> void:
	animation_tree.set("parameters/idle/blend_position", velocity)
	animation_tree.set("parameters/walk/blend_position", velocity)

func set_current_state(new_state) -> void:
	if new_state == current_state:
		return
	match(new_state):
		STATE.IDLE:
			state_machine.travel("idle")
		STATE.WALK:
			state_machine.travel("walk")
	current_state = new_state

func get_movement_input() -> Vector2:
	var x_input = int(Input.get_action_strength("right")) - int(Input.get_action_strength("left"))
	var y_input = int(Input.get_action_strength("down")) - int(Input.get_action_strength("up"))
	return Vector2(x_input, y_input).normalized()

func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	tween.start()

func puppet_state_set(new_value) -> void:
	self.current_state = new_value

func puppet_direction_set(new_value) -> void:
	update_animation_parameters(new_value)

func _on_Network_tick_rate_timeout():
	if is_network_master():
		rset_unreliable("puppet_position", global_position)
		if(velocity != Vector2.ZERO):
			rset_unreliable("puppet_direction", velocity)
		rset_unreliable("puppet_state", current_state)
