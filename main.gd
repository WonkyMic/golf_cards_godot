extends Node2D

# Game States :: DRAW, DISCARD
@export var game_status = "DRAW"
# TODO :: Dynamic players :: Current: PlayerOne, PlayerTwo
@export var player_turn = "PlayerOne"

var end_game_player = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	print("-- GAME INIT --")
	$DeckAndDiscard.deal_cards()
	$Player1.set_player_name("PlayerOne")
	$Player2.set_player_name("PlayerTwo")
	
	$Info/InfoContainer/TurnContainer/TurnValueLabel.text = "PlayerOne"
	$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Draw"
	
	$Player2/CardContainer/CardRow1/Card1/Button.disabled = true
	$Player2/CardContainer/CardRow1/Card2/Button.disabled = true
	$Player2/CardContainer/CardRow1/Card3/Button.disabled = true
	$Player2/CardContainer/CardRow2/Card4/Button.disabled = true
	$Player2/CardContainer/CardRow2/Card5/Button.disabled = true
	$Player2/CardContainer/CardRow2/Card6/Button.disabled = true

func _draw_action(card):
	if game_status == "DRAW":
		$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Place Card"
		$Info/InfoContainer/CardRect.set_card(card)
		$DeckAndDiscard/DeckDraw.disabled = true
		$DeckAndDiscard/DiscardDraw.disabled = true
		game_status = "DISCARD"
	else:
		print("Invalid Move")

# if the last move is a DRAW and Replace of an unflipped card then
# 	"Status" stays as "Draw" and not the winner announcement
func is_game_over():
	var is_over = false
	# TODO :: Only works with 2 players
	if !end_game_player.is_empty():
		var p1_score = $Player1.calculate_player_score()
		print("PlayerOne Score :: " + str(p1_score))
		var p2_score = $Player2.calculate_player_score()
		print("PlayerTwo Score :: " + str(p2_score))
		
		if p1_score < p2_score:
			$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "P1 Wins!"
		elif p1_score > p2_score:
			$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "P2 Wins!"
		else:
			$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Tie!"
		
		# flip_texture to reveal all cards
		
		$Player1/CardContainer/CardRow1/Card1/Button.disabled = true
		$Player1/CardContainer/CardRow1/Card1.flip_texture()
		$Player1/CardContainer/CardRow1/Card2/Button.disabled = true
		$Player1/CardContainer/CardRow1/Card2.flip_texture()
		$Player1/CardContainer/CardRow1/Card3/Button.disabled = true
		$Player1/CardContainer/CardRow1/Card3.flip_texture()
		$Player1/CardContainer/CardRow2/Card4/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card4.flip_texture()
		$Player1/CardContainer/CardRow2/Card5/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card5.flip_texture()
		$Player1/CardContainer/CardRow2/Card6/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card6.flip_texture()
		
		$Player2/CardContainer/CardRow1/Card1/Button.disabled = true
		$Player2/CardContainer/CardRow1/Card1.flip_texture()
		$Player2/CardContainer/CardRow1/Card2/Button.disabled = true
		$Player2/CardContainer/CardRow1/Card2.flip_texture()
		$Player2/CardContainer/CardRow1/Card3/Button.disabled = true
		$Player2/CardContainer/CardRow1/Card3.flip_texture()
		$Player2/CardContainer/CardRow2/Card4/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card4.flip_texture()
		$Player2/CardContainer/CardRow2/Card5/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card5.flip_texture()
		$Player2/CardContainer/CardRow2/Card6/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card6.flip_texture()
		is_over = true
	return is_over

func _swap_turn():
	$DeckAndDiscard/DeckDraw.disabled = false
	$DeckAndDiscard/DiscardDraw.disabled = false
	if player_turn == "PlayerOne":
		if is_game_over():
			return
		
		if $Player1.check_end_game():
			$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Last Turn"
			end_game_player = "PlayerOne"
		
		player_turn = "PlayerTwo"
		$Info/InfoContainer/TurnContainer/TurnValueLabel.text = player_turn
		
		$Player2/CardContainer/CardRow1/Card1/Button.disabled = false
		$Player2/CardContainer/CardRow1/Card2/Button.disabled = false
		$Player2/CardContainer/CardRow1/Card3/Button.disabled = false
		$Player2/CardContainer/CardRow2/Card4/Button.disabled = false
		$Player2/CardContainer/CardRow2/Card5/Button.disabled = false
		$Player2/CardContainer/CardRow2/Card6/Button.disabled = false
		
		$Player1/CardContainer/CardRow1/Card1/Button.disabled = true
		$Player1/CardContainer/CardRow1/Card2/Button.disabled = true
		$Player1/CardContainer/CardRow1/Card3/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card4/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card5/Button.disabled = true
		$Player1/CardContainer/CardRow2/Card6/Button.disabled = true	
	elif player_turn == "PlayerTwo":
		if is_game_over():
			return
			
		if $Player2.check_end_game():
			$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Last Turn"
			end_game_player = "PlayerTwo"
		
		player_turn = "PlayerOne"
		$Info/InfoContainer/TurnContainer/TurnValueLabel.text = player_turn
		
		$Player2/CardContainer/CardRow1/Card1/Button.disabled = true
		$Player2/CardContainer/CardRow1/Card2/Button.disabled = true
		$Player2/CardContainer/CardRow1/Card3/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card4/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card5/Button.disabled = true
		$Player2/CardContainer/CardRow2/Card6/Button.disabled = true
		
		$Player1/CardContainer/CardRow1/Card1/Button.disabled = false
		$Player1/CardContainer/CardRow1/Card2/Button.disabled = false
		$Player1/CardContainer/CardRow1/Card3/Button.disabled = false
		$Player1/CardContainer/CardRow2/Card4/Button.disabled = false
		$Player1/CardContainer/CardRow2/Card5/Button.disabled = false
		$Player1/CardContainer/CardRow2/Card6/Button.disabled = false

func discard_action(card):
	if game_status == "DISCARD":
		_swap_turn()
		$DeckAndDiscard.discard_card(card)
		$Info/InfoContainer/StatusContainer/StatusValueLabel.text = "Draw"
		$Info/InfoContainer/CardRect.set_card(null)
		game_status = "DRAW"
	else:
		print("Invalid Move")

func _on_draw_from_deck(card_value):
	_draw_action(card_value)

func _on_draw_from_discard(card_value):
	_draw_action(card_value)

func player_card_interacted(card_name):
	if game_status == "DRAW":
		_swap_turn()
		return
	if game_status == "DISCARD":
		discard_action(card_name)

func _on_player_1_card_interacted(card_name):
	player_card_interacted(card_name)

func _on_player_2_card_interacted(card_name):
	player_card_interacted(card_name)

func _on_player_1_end_game(player_name):
	end_game_player = player_name

func _on_player_2_end_game(player_name):
	end_game_player = player_name

func _on_discard_selected():
	# discard if status is DISCARD/Place Card
	print("dicard_selected")
	if game_status == "DISCARD":
		discard_action($Info/InfoContainer/CardRect.card_name)
