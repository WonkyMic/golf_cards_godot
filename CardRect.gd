extends TextureRect

@export var card_name = ""

func set_card(card = null):
	if card == null:
		card_name = ""
		texture = null
		return
	
	card_name = card
	texture = load("res://assets/cards/" + card_name + ".png")
