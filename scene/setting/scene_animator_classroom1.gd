extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

	for i in [$ClassRow_FirstRow/character_classmate1, $ClassRow_FirstRow/character_classmate3, $ClassRow_FirstRow/character_classmate2, $ClassRow_SecondRow/character_classmate3, $ClassRow_SecondRow/character_classmate5, $ClassRow_SecondRow/character_classmate4, $ClassRow_SecondRow2/character_classmate3, $ClassRow_SecondRow2/character_classmate5, $ClassRow_SecondRow2/character_classmate4]:
		i.set_textures_backfacing()
		
	for i in [$ClassRow_FirstRow/character_kyosai_hd, $ClassRow_FirstRow/character_kyosai_hd2, $ClassRow_SecondRow/character_kyosai_hd3, $ClassRow_SecondRow/character_kyosai_hd4, $ClassRow_SecondRow2/character_kyosai_hd3, $ClassRow_SecondRow2/character_kyosai_hd4]:
		i.set_textures_backfacing()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
