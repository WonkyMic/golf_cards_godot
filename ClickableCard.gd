extends TextureRect

signal card_flipped(card_name)

@onready var ap: AnimationPlayer = $AnimationPlayer

var is_face_up = false
var card_name = "Blank"
@export var front_texture: Texture
@export var back_texture: Texture

# Called when the node enters the scene tree for the first time.
func _ready():
	set_card_texture()
	
func set_card_value(c_name):
	card_name = c_name
	front_texture = load("res://assets/cards/" + card_name + ".png")
	set_card_texture()

func set_card_texture(a_texture = null):
	if a_texture == null:
		texture = front_texture if is_face_up else back_texture
	else:
		texture = a_texture

func flip_texture():
	# We only need to reveal the card, not hide
	# is_face_up = !is_face_up
	is_face_up = true
	set_card_texture()

func _on_button_pressed():
#	if get_tree().current_scene.game_status == "DISCARD":
	if get_parent().name != "Deck": # && get_parent().name != "Discard":
		flip_texture()
		ap.play("flip")
		card_flipped.emit(card_name)
