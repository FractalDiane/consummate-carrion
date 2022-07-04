extends Control

export(DynamicFont) var font: DynamicFont = null

const OFFSET := Vector2(18, 56)
const COLOR := Color("#ead692")

var timer := 0.0
var time_value := 0.0

func _process(delta: float) -> void:
	timer += delta
	
	update()
	
	
func _draw() -> void:
	var time_ceil := ceil(time_value)
	var time_string := str(time_ceil)

	var char_spacing := 0
	for i in range(len(time_string)):
		#var s := 2.0 * (timer * 100.0) + i * 30.0
		#var shift := sin(s * PI * (1.0 / 60.0)) * 3.0
		var theta := fmod(timer * 1.4, PI * 2.0) + i
		var compensation := Vector2((3 - len(time_string)) * 18, 0)
		char_spacing += int(draw_char(font, OFFSET + compensation + Vector2(char_spacing + 5.0 * cos(theta), 5.0 * sin(theta)), time_string[i], "", COLOR) + 5)
