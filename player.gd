extends Node2D

# Represents a card to be sent to discard
signal card_interacted(card_name)
signal end_game(player_name)

var player_name = "WonkyMic"
var hand_of_cards = []

#var card_points = {
#	"C2": 2, "C3": 3, "C4": 4, "C5": 5, "C6": 6, "C7": 7, "C8": 8, "C9": 9, "C10": 10, "CJ": 10, "CQ": 10, "CK": 0, "CA": 1,
#	"D2": 2, "D3": 3, "D4": 4, "D5": 5, "D6": 6, "D7": 7, "D8": 8, "D9": 9, "D10": 10, "DJ": 10, "DQ": 10, "DK": 0, "DA": 1,
#	"H2": 2, "H3": 3, "H4": 4, "H5": 5, "H6": 6, "H7": 7, "H8": 8, "H9": 9, "H10": 10, "HJ": 10, "HQ": 10, "HK": 0, "HA": 1,
#	"S2": 2, "S3": 3, "S4": 4, "S5": 5, "S6": 6, "S7": 7, "S8": 8, "S9": 9, "S10": 10, "SJ": 10, "SQ": 10, "SK": 0, "SA": 1,
#	"BJO": -10, "RJO": -10
#}

var card_points = {
	"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
	"10": 10, "J": 10, "Q": 10, "K": 0, "A": 1,	"JO": -10
}

func _is_joker(card):
	if card == -10:
		return true
	return false

func _score_column(first_card, second_card):
#	print("first_card :: " + str(card_points[first_card]) + " // second_card :: " + str(card_points[second_card]))
	var score = 0
	if first_card == "JO" or second_card == "JO":
		score += card_points[first_card] + card_points[second_card]
	elif first_card == second_card:
		pass # do nothing
	else:
		score += card_points[first_card] + card_points[second_card]
#	print("Column Score :: " + str(score))
	return score

func calculate_player_score():
	var score = 0
	var card1 = $CardContainer/CardRow1/Card1.card_name.right(-1)
	var card2 = $CardContainer/CardRow1/Card2.card_name.right(-1)
	var card3 = $CardContainer/CardRow1/Card3.card_name.right(-1)
	var card4 = $CardContainer/CardRow2/Card4.card_name.right(-1)
	var card5 = $CardContainer/CardRow2/Card5.card_name.right(-1)
	var card6 = $CardContainer/CardRow2/Card6.card_name.right(-1)

	# First Column
#	print("-- First Column --")
#	print("Card1 :: " + card1 + " // Card4 :: " + card4)
	score += _score_column(card1, card4)
	# Second Column
#	print("-- Second Column --")
#	print("Card2 :: " + card2 + " // Card5 :: " + card5)
	score += _score_column(card2, card5)
	# Third Column
#	print("-- Third Column --")
#	print("Card3 :: " + card3 + " // Card6 :: " + card6)
	score += _score_column(card3, card6)
	return score

func set_player_name(p_name: String):
	player_name = p_name
	$CardContainer/PlayerName.text = player_name


func set_starting_hand(player_cards):
	hand_of_cards = player_cards
	print(hand_of_cards)
	
	$CardContainer/CardRow1/Card1.set_card_value(hand_of_cards[0])
	$CardContainer/CardRow1/Card2.set_card_value(hand_of_cards[1])
	$CardContainer/CardRow1/Card3.set_card_value(hand_of_cards[2])
	$CardContainer/CardRow2/Card4.set_card_value(hand_of_cards[3])
	$CardContainer/CardRow2/Card5.set_card_value(hand_of_cards[4])
	$CardContainer/CardRow2/Card6.set_card_value(hand_of_cards[5])

func bool_to_string(boo):
	return "true" if boo else "false"
		
	
# TODO :: is_face_up appears to have a race condition when checking here
func check_end_game():
	var is_end_game = false
	
	if $CardContainer/CardRow1/Card1.is_face_up && $CardContainer/CardRow1/Card2.is_face_up && $CardContainer/CardRow1/Card3.is_face_up && $CardContainer/CardRow2/Card4.is_face_up && $CardContainer/CardRow2/Card5.is_face_up && $CardContainer/CardRow2/Card6.is_face_up:
		is_end_game = true

	return is_end_game

func card_interaction(current_card):
	if (get_tree().current_scene.game_status == "DISCARD"):
		var old_name = current_card.card_name
		current_card.set_card_value(get_tree().current_scene.get_node("Info/InfoContainer/CardRect").card_name)
		card_interacted.emit(old_name)
	else:
		card_interacted.emit(current_card.card_name)

func _on_card_1_card_flipped(card_name):
	card_interaction($CardContainer/CardRow1/Card1)

func _on_card_2_card_flipped(card_name):
	card_interaction($CardContainer/CardRow1/Card2)

func _on_card_3_card_flipped(card_name):
	card_interaction($CardContainer/CardRow1/Card3)

func _on_card_4_card_flipped(card_name):
	card_interaction($CardContainer/CardRow2/Card4)

func _on_card_5_card_flipped(card_name):
	card_interaction($CardContainer/CardRow2/Card5)

func _on_card_6_card_flipped(card_name):
	card_interaction($CardContainer/CardRow2/Card6)
