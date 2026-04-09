extends Button

@export var base: Base = null
@onready var value: Label = $Counter/HBoxContainer/Value

func _ready() -> void:
	value.text = str(Globals.get_current_level(self.name))
	disabled = !Globals.can_afford_upgrade(self.name)

func _process(_delta: float) -> void:
	disabled = !Globals.can_afford_upgrade(self.name)

func _on_pressed() -> void:
	# Do the actual upgrade
	var temp
	
	if self.name == "Mole":
		temp = Mole.new()
	elif self.name == "MinerMole":
		temp = MinerMole.new()
	elif self.name == "DoctorMole":
		temp = DoctorMole.new()
	elif self.name == "MusicMole":
		temp = MusicMole.new()
	elif self.name == "Armadillo":
		temp = Armadillo.new()
	elif self.name == "Base":
		temp = Base.new()
	elif self.name == "Cannon":
		temp = Cannon.new()
	
	print(base.trigger_upgrade(temp))
	temp.queue_free()
	
	value.text = str(Globals.get_current_level(self.name))
	var flav = Globals.get_next_upgrade_description(self.name)
	$"../../../../../../../FlavourText/FlavourText".text = flav

func _on_mouse_entered() -> void:
	# Update upgrade costs for UI
	var dict = Globals.get_upgrade_costs(self.name)
	%GoldCost.text = str(dict.get(1))
	%CoalCost.text = str(dict.get(0))
	%AmethystCost.text = str(dict.get(2))
	%DiamondCost.text = str(dict.get(3))
	%Costs.show()
	
	var flav = Globals.get_next_upgrade_description(self.name)
	$"../../../../../../../FlavourText/FlavourText".text = flav
	%FlavourText.show()

func _on_mouse_exited() -> void:
	%Costs.hide()
	%FlavourText.hide()
