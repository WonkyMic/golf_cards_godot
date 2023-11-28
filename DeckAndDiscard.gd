extends HBoxContainer

signal draw_from_deck(card_value)
signal draw_from_discard(card_value)
signal discard_selected()

var full_deck = [
	"C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "CJ", "CQ", "CK", "CA",
	"D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "DJ", "DQ", "DK", "DA",
	"H2", "H3", "H4", "H5", "H6", "H7", "H8", "H9", "H10", "HJ", "HQ", "HK", "HA",
	"S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10", "SJ", "SQ", "SK", "SA",
	"BJO", "RJO"
]

var current_deck = []
var discard_deck = []

@onready var player1 = $"../Player1"
@onready var player2 = $"../Player2"

func deal_cards():
	current_deck = full_deck.duplicate()
	
	var player1_cards = [_new_card(), _new_card(), _new_card(), _new_card(), _new_card(), _new_card()]
	var player2_cards = [_new_card(), _new_card(), _new_card(), _new_card(), _new_card(), _new_card()]
	
	# assign cards
	print("-- setting player1 --")
	player1.set_starting_hand(player1_cards)
	print("-- setting player2 --")
	player2.set_starting_hand(player2_cards)
	
	discard_card(_new_card())
	
func discard_card(card):
	discard_deck.append(card)

	$Discard/ClickableCard.set_card_value(card)
	$Discard/ClickableCard.is_face_up = true
	$Discard/ClickableCard.set_card_texture()

func _new_card():
	var card = current_deck[randi() % current_deck.size()]
	current_deck.erase(card)
	return card
	
func _new_from_discard():
	var card = discard_deck[-1]
	discard_deck.erase(card)
	
	if discard_deck.size() == 0:
		$Discard/ClickableCard.set_card_value("card_back")
	else:
		$Discard/ClickableCard.set_card_value(discard_deck[-1])
	$Discard/ClickableCard.set_card_texture()
	
	return card

func _on_deck_draw_pressed():
	draw_from_deck.emit(_new_card())

func _on_discard_draw_pressed():
	draw_from_discard.emit(_new_from_discard())

func _on_discard_card_flipped(card_name):
	discard_selected.emit()
