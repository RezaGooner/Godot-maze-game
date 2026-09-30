extends Node2D
class_name GridCell


# ============================================================
# Cell Types
# ============================================================

enum CellType
{
	FLOOR,
	WALL,
	REWARD,
	PENALTY,
	GOAL
}


# ============================================================
# Cell Settings
# ============================================================

var cell_type: CellType = CellType.FLOOR

var cell_size: int = 48


# ============================================================
# Visibility
# ============================================================

var is_visible: bool = false

var is_explored: bool = false


# ============================================================
# Colors
# ============================================================

var floor_color := Color(
	0.12,
	0.12,
	0.14
)

var wall_color := Color(
	0.04,
	0.04,
	0.05
)

var reward_color := Color(
	0.1,
	0.45,
	0.15
)

var penalty_color := Color(
	0.55,
	0.08,
	0.08
)

var goal_color := Color(
	0.8,
	0.65,
	0.05
)

var grid_line_color := Color(
	0.25,
	0.25,
	0.28
)


# ============================================================
# Fog of War
# ============================================================

var unexplored_color := Color(
	0.005,
	0.005,
	0.008
)

var explored_darkness := 0.55


# ============================================================
# FLOOR TEXTURE
# ============================================================

@export_category("Floor Texture")

@export var floor_texture: Texture2D = null

@export var use_floor_texture: bool = false

@export var floor_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# WALL TEXTURE
# ============================================================

@export_category("Wall Texture")

@export var wall_texture: Texture2D = null

@export var use_wall_texture: bool = false

@export var wall_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# REWARD TEXTURE
# ============================================================

@export_category("Reward Texture")

@export var reward_texture: Texture2D = null

@export var use_reward_texture: bool = false

@export var reward_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# PENALTY TEXTURE
# ============================================================

@export_category("Penalty Texture")

@export var penalty_texture: Texture2D = null

@export var use_penalty_texture: bool = false

@export var penalty_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# GOAL TEXTURE
# ============================================================

@export_category("Goal Texture")

@export var goal_texture: Texture2D = null

@export var use_goal_texture: bool = false

@export var goal_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# Setup
# ============================================================

func setup(
	new_type: CellType,
	new_size: int
) -> void:

	cell_type = new_type

	cell_size = new_size

	queue_redraw()


# ============================================================
# Visibility
# ============================================================

func set_visibility(
	visible_now: bool,
	explored: bool
) -> void:

	is_visible = visible_now

	is_explored = explored

	queue_redraw()


# ============================================================
# انتخاب Texture مربوط به Cell
# ============================================================

func get_current_texture() -> Texture2D:

	match cell_type:

		CellType.FLOOR:

			return floor_texture


		CellType.WALL:

			return wall_texture


		CellType.REWARD:

			return reward_texture


		CellType.PENALTY:

			return penalty_texture


		CellType.GOAL:

			return goal_texture


	return null


# ============================================================
# آیا Texture مربوط به Cell فعال است؟
# ============================================================

func is_current_texture_enabled() -> bool:

	match cell_type:

		CellType.FLOOR:

			return use_floor_texture


		CellType.WALL:

			return use_wall_texture


		CellType.REWARD:

			return use_reward_texture


		CellType.PENALTY:

			return use_penalty_texture


		CellType.GOAL:

			return use_goal_texture


	return false


# ============================================================
# Scale مربوط به Texture
# ============================================================

func get_current_texture_scale() -> Vector2:

	match cell_type:

		CellType.FLOOR:

			return floor_texture_scale


		CellType.WALL:

			return wall_texture_scale


		CellType.REWARD:

			return reward_texture_scale


		CellType.PENALTY:

			return penalty_texture_scale


		CellType.GOAL:

			return goal_texture_scale


	return Vector2.ONE


# ============================================================
# Draw
# ============================================================

func _draw() -> void:

	var rect := Rect2(
		Vector2.ZERO,
		Vector2(
			cell_size,
			cell_size
		)
	)


	# ========================================================
	# هنوز کشف نشده
	# ========================================================

	if not is_explored:

		draw_rect(
			rect,
			unexplored_color
		)

		return


	# ========================================================
	# Texture
	# ========================================================

	var current_texture: Texture2D = (
		get_current_texture()
	)


	var texture_enabled: bool = (
		is_current_texture_enabled()
	)


	if (
		texture_enabled
		and current_texture != null
	):

		var texture_size: Vector2 = (
			current_texture.get_size()
		)


		if (
			texture_size.x > 0.0
			and texture_size.y > 0.0
		):

			var scale_value: Vector2 = (
				get_current_texture_scale()
			)


			var scaled_size: Vector2 = (
				texture_size * scale_value
			)


			var texture_rect := Rect2(
				Vector2(
					(cell_size - scaled_size.x) / 2.0,
					(cell_size - scaled_size.y) / 2.0
				),
				scaled_size
			)


			draw_texture_rect(
				current_texture,
				texture_rect,
				false
			)

	else:

		# ====================================================
		# اگر Texture خاموش باشد
		# از Color استفاده می‌شود.
		# ====================================================

		var cell_color: Color = (
			get_cell_color()
		)


		draw_rect(
			rect,
			cell_color
		)


	# ========================================================
	# Fog of War
	# ========================================================

	if not is_visible:

		draw_rect(
			rect,
			Color(
				0.0,
				0.0,
				0.0,
				explored_darkness
			)
		)


	# ========================================================
	# Grid Line
	# ========================================================

	draw_rect(
		rect,
		grid_line_color,
		false,
		1.0
	)


# ============================================================
# Cell Color
# ============================================================

func get_cell_color() -> Color:

	match cell_type:

		CellType.FLOOR:

			return floor_color


		CellType.WALL:

			return wall_color


		CellType.REWARD:

			return reward_color


		CellType.PENALTY:

			return penalty_color


		CellType.GOAL:

			return goal_color


	return Color.WHITE
