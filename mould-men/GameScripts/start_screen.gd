extends Node2D

var main_level:		String	= "res://Scenes/cave_level.tscn"
var credits_page:	String	= "res://Scenes/credits_scene.tscn"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(main_level)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file(credits_page)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
