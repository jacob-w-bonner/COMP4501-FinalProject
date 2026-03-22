extends GridContainer

func _ready():
	$CoalLabel.text = str(Globals.COAL_NUM)
	$GoldLabel.text = str(Globals.GOLD_NUM)
	$AmethystLabel.text = str(Globals.AMETHYST_NUM)
	$DiamondLabel.text = str(Globals.DIAMOND_NUM)

func _on_mole_mouse_entered():
	pass # Replace with function body.


func _on_mole_mouse_exited():
	pass # Replace with function body.


func _on_miner_mouse_entered():
	pass # Replace with function body.


func _on_miner_mouse_exited():
	pass # Replace with function body.
