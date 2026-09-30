extends Node2D

# ============================================================
# PLAYER VISUAL SETTINGS
# ============================================================

@export_category("Player Visual")

@export var player_color: Color = Color(0.2, 0.65, 1.0)
@export var outline_color: Color = Color.WHITE

# ارتفاع تقریبی نمایش کاراکتر روی صفحه
@export var character_height: float = 42.0

# سرعت انیمیشن بر حسب فریم در ثانیه
@export var animation_fps: float = 10.0

# ============================================================
# COLOR EFFECT
# ============================================================

var effect_color: Color = Color.WHITE

var effect_timer: float = 0.0

@export var effect_duration: float = 0.5

# ============================================================
# SPRITE SHEETS
# ============================================================

@export_category("Player Sprite Sheets")

@export var left_texture: Texture2D = null
@export var right_texture: Texture2D = null
@export var up_texture: Texture2D = null
@export var down_texture: Texture2D = null


# ============================================================
# DIRECTION
# ============================================================

enum Direction
{
	DOWN,
	UP,
	LEFT,
	RIGHT
}

var current_direction: Direction = Direction.DOWN


# ============================================================
# ANIMATION
# ============================================================

var current_frame: int = 0
var animation_time: float = 0.0
var is_moving: bool = false


# ============================================================
# MOVEMENT DETECTION
# ============================================================

var previous_position: Vector2


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	previous_position = global_position
	queue_redraw()


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:
	if effect_timer > 0.0:

		effect_timer -= delta

		if effect_timer <= 0.0:

			effect_color = Color.WHITE

			queue_redraw()
	var movement: Vector2 = global_position - previous_position

	if movement.length() > 0.001:
		is_moving = true

		update_direction_from_movement(movement)

		animation_time += delta

		var frame_duration: float = 1.0 / max(animation_fps, 1.0)

		if animation_time >= frame_duration:
			animation_time -= frame_duration
			current_frame = (current_frame + 1) % 4
	else:
		is_moving = false
		animation_time = 0.0

		# هنگام توقف، فریم وسط را نمایش می‌دهیم
		current_frame = 2

	previous_position = global_position
	
	# ========================================================
	# COLOR EFFECT TIMER
	# ========================================================

	if effect_timer > 0.0:

		effect_timer -= delta

		if effect_timer <= 0.0:

			effect_color = Color.WHITE

			queue_redraw()

	queue_redraw()


# ============================================================
# DETECT DIRECTION
# ============================================================

func update_direction_from_movement(movement: Vector2) -> void:
	if abs(movement.x) > abs(movement.y):
		if movement.x > 0.0:
			current_direction = Direction.RIGHT
		else:
			current_direction = Direction.LEFT
	else:
		if movement.y > 0.0:
			current_direction = Direction.DOWN
		else:
			current_direction = Direction.UP

# ============================================================
# EXTERNAL MOVEMENT DIRECTION
# ============================================================

func set_move_direction(direction: Vector2) -> void:
	print("PLAYER DIRECTION:", direction)
	update_direction_from_movement(direction)
	animation_time = 0.0
	queue_redraw()

# ============================================================
# GET CURRENT TEXTURE
# ============================================================

func get_current_texture() -> Texture2D:
	match current_direction:
		Direction.LEFT:
			return left_texture

		Direction.RIGHT:
			return right_texture

		Direction.UP:
			return up_texture

		Direction.DOWN:
			return down_texture

	return null


# ============================================================
# GET FRAME RECT
# ============================================================

func get_frame_rect() -> Rect2:
	match current_direction:
		Direction.LEFT:
			return get_left_frame_rect(current_frame)

		Direction.RIGHT:
			return get_right_frame_rect(current_frame)

		Direction.UP:
			return get_up_frame_rect(current_frame)

		Direction.DOWN:
			return get_down_frame_rect(current_frame)

	return Rect2()


# ============================================================
# LEFT FRAME POSITIONS
# ============================================================

func get_left_frame_rect(frame: int) -> Rect2:
	var x_positions: Array[int] = [13, 67, 122, 175, 230]

	var x: int = x_positions[frame]

	return Rect2(
		x,
		0,
		32,
		64
	)


# ============================================================
# RIGHT FRAME POSITIONS
# ============================================================

func get_right_frame_rect(frame: int) -> Rect2:
	var x_positions: Array[int] = [13, 67, 122, 175, 230]

	var x: int = x_positions[frame]

	return Rect2(
		x,
		0,
		32,
		64
	)


# ============================================================
# UP FRAME POSITIONS
# ============================================================

func get_up_frame_rect(frame: int) -> Rect2:
	var x_positions: Array[int] = [16, 71, 127, 182, 238]

	var x: int = x_positions[frame]

	return Rect2(
		x,
		0,
		32,
		64
	)


# ============================================================
# DOWN FRAME POSITIONS
# ============================================================

func get_down_frame_rect(frame: int) -> Rect2:
	var x_positions: Array[int] = [15, 73, 121, 178, 228]

	var x: int = x_positions[frame]

	return Rect2(
		x,
		0,
		32,
		64
	)

# ============================================================
# PLAYER EFFECT
# ============================================================

func play_effect(color: Color) -> void:

	print("EFFECT:", color)

	effect_color = color

	effect_timer = effect_duration

	queue_redraw()
	
# ============================================================
# DRAW
# ============================================================

func _draw() -> void:
	var texture: Texture2D = get_current_texture()

	if texture != null:
		var source_rect: Rect2 = get_frame_rect()

		var source_size: Vector2 = source_rect.size

		if source_size.x > 0.0 and source_size.y > 0.0:
			var scale_factor: float = character_height / source_size.y

			var destination_size: Vector2 = source_size * scale_factor

			var destination_rect: Rect2 = Rect2(
				-destination_size / 2.0,
				destination_size
			)

			draw_texture_rect_region(
				texture,
				destination_rect,
				source_rect,
				effect_color
			)

			return

	# ========================================================
	# FALLBACK
	# ========================================================

	var radius: float = character_height * 0.35

	draw_circle(
		Vector2.ZERO,
		radius,
		player_color * effect_color
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		outline_color * effect_color,
		false,
		2.0
	)
