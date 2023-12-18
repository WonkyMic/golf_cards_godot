extends Control
class_name Match

@onready var global := get_node("/root/Global")
@onready var chat_panel := $ChatPanel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: WHY TF DOES CHAT SHOW UP AS HIDDEN!?
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


@rpc("authority", "call_remote", "reliable")
func start_game() -> void:
	chat_panel.show()
