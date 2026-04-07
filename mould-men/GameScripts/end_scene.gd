class_name Ending extends Node2D

var main_menu:						String		= "res://Scenes/start_screen.tscn"
@onready var outcome_label:			Label		= $Control/OutcomeLabel
@onready var blurb_label:			Label		= $Control/BlurbLabel
@onready var poster:				Sprite2D	= $Control/MoleSprite


enum OUTCOME_TYPES {
	VICTORY,
	DEFEAT,
	SURRENDER
}
var outcome = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if outcome != null:
		set_stage()

func set_outcome(out: OUTCOME_TYPES)->void:
	outcome = out

func set_stage()->void:
	if outcome == OUTCOME_TYPES.VICTORY:
		outcome_label.text = "VICTORY"
		outcome_label.set("theme_override_colors/font_color",Color(0.141, 0.859, 0.0))
		
		blurb_label.text = "Hazah! The Hill-en is captured! The land and gems you've secured here today are proof to the rest of Molekind that resistance is possible, the war is far from over, but  for today that is victory enough. It’s a good day, for once it is the Arkaick’s faces in the dirt, and the claws of the Mole in the sky."
		
		poster.texture = load("res://Assets/UIAssets/mole_chains.png")
		poster.scale = Vector2(0.5, 0.5)
	elif outcome == OUTCOME_TYPES.DEFEAT:
		outcome_label.text = "DEFEAT"
		outcome_label.set("theme_override_colors/font_color",Color(1.0, 0.145, 0.051))
		
		blurb_label.text = "Unfortunately their onslaught of robots was too much to bear. We’ve escaped with our lives, though many of our brothers cannot say the same. For now we retreat and lick our wounds, hold those we care for tightly. Perhaps the next offensive will be different, if there is a next one."
		
		poster.texture = load("res://Assets/UIAssets/Oliver_enlist.png")
		poster.scale = Vector2(0.545, 0.515)
	elif outcome == OUTCOME_TYPES.SURRENDER:
		outcome_label.text = "SURRENDER"
		outcome_label.set("theme_override_colors/font_color",Color(0, 0, 1))
		
		blurb_label.text = "Sometimes the wisest thing a leader can do is admit when they are beaten. You've saved a great many lives today by conceding early, though by doing it so late you've condemned many more to a pointless nonexistence. Wisdom or cowardice? I wonder what the history books will say."
		
		poster.texture = load("res://Assets/UIAssets/Oliver_enlist.png")
		poster.scale = Vector2(0.545, 0.515)
	outcome = null

func _on_quit_button_pressed() -> void:
	get_tree().quit()
