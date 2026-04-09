extends GridContainer

@onready var gold_label: RichTextLabel = $HBoxContainer/GoldLabel
@onready var coal_label: RichTextLabel = $HBoxContainer2/CoalLabel
@onready var amethyst_label: RichTextLabel = $HBoxContainer3/AmethystLabel
@onready var diamond_label: RichTextLabel = $HBoxContainer4/DiamondLabel

func _ready():
	gold_label.text = str(Globals.GOLD_NUM)
	coal_label.text = str(Globals.COAL_NUM)
	amethyst_label.text = str(Globals.AMETHYST_NUM)
	diamond_label.text = str(Globals.DIAMOND_NUM)
