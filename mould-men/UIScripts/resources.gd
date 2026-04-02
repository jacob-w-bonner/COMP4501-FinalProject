extends GridContainer

@onready var gold_label: RichTextLabel = $MarginContainer/MarginContainer/HBoxContainer/GoldLabel
@onready var coal_label: RichTextLabel = $MarginContainer2/MarginContainer/HBoxContainer/CoalLabel
@onready var amethyst_label: RichTextLabel = $MarginContainer3/MarginContainer/HBoxContainer/AmethystLabel
@onready var diamond_label: RichTextLabel = $MarginContainer4/MarginContainer/HBoxContainer/DiamondLabel

func _ready():
	gold_label.text = str(Globals.GOLD_NUM)
	coal_label.text = str(Globals.COAL_NUM)
	amethyst_label.text = str(Globals.AMETHYST_NUM)
	diamond_label.text = str(Globals.DIAMOND_NUM)

func _on_mole_mouse_entered():
	pass # Replace with function body.


func _on_mole_mouse_exited():
	pass # Replace with function body.


func _on_miner_mouse_entered():
	pass # Replace with function body.


func _on_miner_mouse_exited():
	pass # Replace with function body.
