extends Node2D


# ============================================================
# Grid Settings
# ============================================================

const CELL_SIZE: int = 48

const GRID_WIDTH: int = 41
const GRID_HEIGHT: int = 31


# ============================================================
# Visibility
# ============================================================

const VISION_RADIUS: int = 6


# ============================================================
# Movement
# ============================================================

@export_category("Player Movement")

@export var movement_duration: float = 0.15

@export var allow_input_during_movement: bool = false


var is_player_moving: bool = false

var player_tween: Tween = null

var held_direction: Vector2i = Vector2i.ZERO

var last_input_direction: Vector2i = Vector2i.ZERO


# ============================================================
# Start / Goal
# ============================================================

const START_POSITION: Vector2i = Vector2i(1, 1)

const GOAL_POSITION: Vector2i = Vector2i(
	GRID_WIDTH - 2,
	GRID_HEIGHT - 2
)


# ============================================================
# Reward / Penalty
# ============================================================

const REWARD_COUNT: int = 8

const PENALTY_COUNT: int = 5


# ============================================================
# Maze Settings
# ============================================================

var EXTRA_OPENINGS: int = 55

const MAX_OPENING_ATTEMPTS: int = 3000

const MAX_MAZE_GENERATION_ATTEMPTS: int = 20


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
# Difficulty
# ============================================================

enum Difficulty
{
	EASY,
	MEDIUM,
	HARD,
	VERY_HARD
}

# ============================================================
# Texture Settings
# ============================================================

@export_category("Floor Texture")

@export var floor_texture: Texture2D = null

@export var use_floor_texture: bool = false

@export var floor_texture_scale: Vector2 = Vector2.ONE


@export_category("Wall Texture")

@export var wall_texture: Texture2D = null

@export var use_wall_texture: bool = false

@export var wall_texture_scale: Vector2 = Vector2.ONE


@export_category("Reward Texture")

@export var reward_texture: Texture2D = null

@export var use_reward_texture: bool = false

@export var reward_texture_scale: Vector2 = Vector2.ONE


@export_category("Penalty Texture")

@export var penalty_texture: Texture2D = null

@export var use_penalty_texture: bool = false

@export var penalty_texture_scale: Vector2 = Vector2.ONE


@export_category("Goal Texture")

@export var goal_texture: Texture2D = null

@export var use_goal_texture: bool = false

@export var goal_texture_scale: Vector2 = Vector2.ONE


# ============================================================
# Grid
# ============================================================

var grid: Array = []

var explored: Array = []


# ============================================================
# Player
# ============================================================

var player_grid_position: Vector2i = START_POSITION

var player_reward: int = 0

var game_finished: bool = false

var game_started: bool = false

# ============================================================
# Difficulty Settings
# ============================================================

var current_difficulty: Difficulty = Difficulty.MEDIUM


var vision_radius:int = 6


var step_cost:int = 2


var dynamic_goal: bool = false


var current_goal_position: Vector2i

# ============================================================
# Node References
# ============================================================

@onready var cells_node: Node2D = $Cells

@onready var player_node: Node2D = $Player

@onready var camera: Camera2D = $Camera2D

@onready var reward_label: Label = $HUDLayer/RewardLabel

@onready var status_label: Label = $HUDLayer/StatusLabel


# ============================================================
# Ready
# ============================================================

func _ready() -> void:

	pass


# ============================================================
# Create Grid
# ============================================================

func create_grid() -> void:

	grid.clear()

	var maze_is_valid: bool = false

	var generation_attempt: int = 0


	while (
		not maze_is_valid
		and generation_attempt < MAX_MAZE_GENERATION_ATTEMPTS
	):

		generation_attempt += 1

		grid.clear()


		# ----------------------------------------------------
		# ابتدا تمام Grid را Wall می‌کنیم
		# ----------------------------------------------------

		for y in range(GRID_HEIGHT):

			var row: Array = []

			for x in range(GRID_WIDTH):

				row.append(CellType.WALL)

			grid.append(row)


		# ----------------------------------------------------
		# ساخت Maze پایه
		# ----------------------------------------------------

		generate_maze()


		# ----------------------------------------------------
		# اضافه کردن مسیرهای جایگزین
		# ----------------------------------------------------

		add_extra_openings()


		# ----------------------------------------------------
		# Start
		# ----------------------------------------------------

		grid[
			START_POSITION.y
		][
			START_POSITION.x
		] = CellType.FLOOR


		# ----------------------------------------------------
		# Goal
		# ----------------------------------------------------

		grid[
			GOAL_POSITION.y
		][
			GOAL_POSITION.x
		] = CellType.FLOOR


		# ----------------------------------------------------
		# بررسی معتبر بودن Maze
		# ----------------------------------------------------

		maze_is_valid = has_path_to_goal()


	if not maze_is_valid:

		print(
			"WARNING: Could not generate a valid Maze."
		)


	# --------------------------------------------------------
	# قرار دادن Goal
	# --------------------------------------------------------

	grid[
		GOAL_POSITION.y
	][
		GOAL_POSITION.x
	] = CellType.GOAL


	# --------------------------------------------------------
	# قرار دادن Reward
	# --------------------------------------------------------

	place_rewards()


	# --------------------------------------------------------
	# قرار دادن Penalty
	# --------------------------------------------------------

	place_penalties()


	print(
		"Maze generated successfully."
	)

	print(
		"Generation attempts: ",
		generation_attempt
	)


# ============================================================
# Generate Maze
# ============================================================

func generate_maze() -> void:

	var stack: Array[Vector2i] = []

	var current: Vector2i = START_POSITION


	# Start را باز می‌کنیم
	grid[
		current.y
	][
		current.x
	] = CellType.FLOOR


	stack.append(current)


	# --------------------------------------------------------
	# Recursive Backtracker / DFS
	# --------------------------------------------------------

	while not stack.is_empty():

		current = stack[
			stack.size() - 1
		]


		var neighbors: Array[Vector2i] = (
			get_unvisited_maze_neighbors(
				current
			)
		)


		if not neighbors.is_empty():

			var random_index: int = randi_range(
				0,
				neighbors.size() - 1
			)


			var next_cell: Vector2i = neighbors[
				random_index
			]


			# ------------------------------------------------
			# Cell وسط دو نقطه
			# ------------------------------------------------

			var wall_position: Vector2i = (
				current + next_cell
			) / 2


			# ------------------------------------------------
			# باز کردن Wall وسط
			# ------------------------------------------------

			grid[
				wall_position.y
			][
				wall_position.x
			] = CellType.FLOOR


			# ------------------------------------------------
			# باز کردن Cell بعدی
			# ------------------------------------------------

			grid[
				next_cell.y
			][
				next_cell.x
			] = CellType.FLOOR


			stack.append(
				next_cell
			)

		else:

			# ------------------------------------------------
			# Dead End
			# ------------------------------------------------

			stack.pop_back()


# ============================================================
# Get Unvisited Maze Neighbors
# ============================================================

func get_unvisited_maze_neighbors(
	position: Vector2i
) -> Array[Vector2i]:

	var result: Array[Vector2i] = []


	var directions: Array[Vector2i] = [
		Vector2i(0, -2),
		Vector2i(0, 2),
		Vector2i(-2, 0),
		Vector2i(2, 0)
	]


	for direction in directions:

		var neighbor: Vector2i = (
			position + direction
		)


		# خارج Grid
		if not is_inside_grid(
			neighbor
		):

			continue


		# دیواره بیرونی
		if (
			neighbor.x <= 0
			or neighbor.y <= 0
			or neighbor.x >= GRID_WIDTH - 1
			or neighbor.y >= GRID_HEIGHT - 1
		):

			continue


		# فقط Cellهای هنوز باز نشده
		if grid[
			neighbor.y
		][
			neighbor.x
		] == CellType.WALL:

			result.append(
				neighbor
			)


	return result


# ============================================================
# Add Extra Openings
# ============================================================

func add_extra_openings() -> void:

	var opened: int = 0

	var attempts: int = 0


	while (
		opened < EXTRA_OPENINGS
		and attempts < MAX_OPENING_ATTEMPTS
	):

		attempts += 1


		# ----------------------------------------------------
		# انتخاب Wall تصادفی
		# ----------------------------------------------------

		var x: int = randi_range(
			1,
			GRID_WIDTH - 2
		)


		var y: int = randi_range(
			1,
			GRID_HEIGHT - 2
		)


		# اگر Wall نیست، رد می‌کنیم
		if grid[y][x] != CellType.WALL:

			continue


		# ----------------------------------------------------
		# حالت افقی
		#
		# Floor - Wall - Floor
		# ----------------------------------------------------

		var horizontal_opening: bool = (
			is_floor_at(
				Vector2i(
					x - 1,
					y
				)
			)
			and
			is_floor_at(
				Vector2i(
					x + 1,
					y
				)
			)
		)


		# ----------------------------------------------------
		# حالت عمودی
		#
		# Floor
		# Wall
		# Floor
		# ----------------------------------------------------

		var vertical_opening: bool = (
			is_floor_at(
				Vector2i(
					x,
					y - 1
				)
			)
			and
			is_floor_at(
				Vector2i(
					x,
					y + 1
				)
			)
		)


		# این Wall مسیر جدید ایجاد نمی‌کند
		if (
			not horizontal_opening
			and not vertical_opening
		):

			continue


		# باز کردن Wall
		grid[y][x] = CellType.FLOOR

		opened += 1


# ============================================================
# Is Floor
# ============================================================

func is_floor_at(
	position: Vector2i
) -> bool:

	if not is_inside_grid(
		position
	):

		return false


	return (
		grid[position.y][position.x]
		== CellType.FLOOR
	)


# ============================================================
# Has Path To Goal
# ============================================================

func has_path_to_goal() -> bool:

	var queue: Array[Vector2i] = []

	var visited: Array = []


	# --------------------------------------------------------
	# ساخت visited
	# --------------------------------------------------------

	for y in range(GRID_HEIGHT):

		var row: Array = []

		for x in range(GRID_WIDTH):

			row.append(false)

		visited.append(row)


	# --------------------------------------------------------
	# شروع BFS
	# --------------------------------------------------------

	queue.append(
		START_POSITION
	)


	visited[
		START_POSITION.y
	][
		START_POSITION.x
	] = true


	var directions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(1, 0)
	]


	# --------------------------------------------------------
	# BFS
	# --------------------------------------------------------

	while not queue.is_empty():

		var current: Vector2i = queue.pop_front()


		if current == GOAL_POSITION:

			return true


		for direction in directions:

			var next: Vector2i = (
				current + direction
			)


			if not is_inside_grid(
				next
			):

				continue


			if visited[
				next.y
			][
				next.x
			]:

				continue


			if grid[
				next.y
			][
				next.x
			] == CellType.WALL:

				continue


			visited[
				next.y
			][
				next.x
			] = true


			queue.append(
				next
			)


	# مسیر پیدا نشد
	return false


# ============================================================
# Place Rewards
# ============================================================

func place_rewards() -> void:

	var placed: int = 0

	var attempts: int = 0

	var max_attempts: int = 3000


	while (
		placed < REWARD_COUNT
		and attempts < max_attempts
	):

		attempts += 1


		var position: Vector2i = (
			get_random_floor_position()
		)


		if position == START_POSITION:

			continue


		if position == GOAL_POSITION:

			continue


		if grid[
			position.y
		][
			position.x
		] != CellType.FLOOR:

			continue


		if manhattan_distance(
			position,
			START_POSITION
		) < 8:

			continue


		if manhattan_distance(
			position,
			GOAL_POSITION
		) < 5:

			continue


		if is_too_close_to_special_cell(
			position
		):

			continue


		grid[
			position.y
		][
			position.x
		] = CellType.REWARD


		placed += 1


# ============================================================
# Place Penalties
# ============================================================

func place_penalties() -> void:

	var placed: int = 0

	var attempts: int = 0

	var max_attempts: int = 3000


	while (
		placed < PENALTY_COUNT
		and attempts < max_attempts
	):

		attempts += 1


		var position: Vector2i = (
			get_random_floor_position()
		)


		if position == START_POSITION:

			continue


		if position == GOAL_POSITION:

			continue


		if grid[
			position.y
		][
			position.x
		] != CellType.FLOOR:

			continue


		if manhattan_distance(
			position,
			START_POSITION
		) < 6:

			continue


		if manhattan_distance(
			position,
			GOAL_POSITION
		) < 4:

			continue


		if is_too_close_to_special_cell(
			position
		):

			continue


		grid[
			position.y
		][
			position.x
		] = CellType.PENALTY


		placed += 1


# ============================================================
# Get Random Floor Position
# ============================================================

func get_random_floor_position() -> Vector2i:

	var x: int = randi_range(
		1,
		GRID_WIDTH - 2
	)


	var y: int = randi_range(
		1,
		GRID_HEIGHT - 2
	)


	return Vector2i(
		x,
		y
	)


# ============================================================
# Manhattan Distance
# ============================================================

func manhattan_distance(
	a: Vector2i,
	b: Vector2i
) -> int:

	return (
		abs(a.x - b.x)
		+
		abs(a.y - b.y)
	)


# ============================================================
# Special Cell Distance
# ============================================================

func is_too_close_to_special_cell(
	position: Vector2i
) -> bool:

	var minimum_distance: int = 5


	for y in range(GRID_HEIGHT):

		for x in range(GRID_WIDTH):

			var cell_type: CellType = grid[
				y
			][
				x
			]


			if (
				cell_type != CellType.REWARD
				and cell_type != CellType.PENALTY
			):

				continue


			var existing_position: Vector2i = Vector2i(
				x,
				y
			)


			if manhattan_distance(
				position,
				existing_position
			) < minimum_distance:

				return true


	return false


# ============================================================
# Exploration Map
# ============================================================

func create_exploration_map() -> void:

	explored.clear()


	for y in range(GRID_HEIGHT):

		var row: Array = []


		for x in range(GRID_WIDTH):

			row.append(false)


		explored.append(row)


# ============================================================
# Create Cells
# ============================================================

func create_cells() -> void:

	# --------------------------------------------------------
	# حذف Cellهای قبلی
	# --------------------------------------------------------

	for child in cells_node.get_children():

		child.queue_free()


	# --------------------------------------------------------
	# ساخت Cellهای جدید
	# --------------------------------------------------------

	for y in range(GRID_HEIGHT):

		for x in range(GRID_WIDTH):

			var cell: GridCell = GridCell.new()


			cell.name = "Cell_%d_%d" % [
				x,
				y
			]


			cell.position = Vector2(
				x * CELL_SIZE,
				y * CELL_SIZE
			)


			# ------------------------------------------------
			# نوع Cell
			# ------------------------------------------------

			cell.setup(
				grid[y][x],
				CELL_SIZE
			)


			# ------------------------------------------------
			# Floor Texture
			# ------------------------------------------------

			cell.floor_texture = floor_texture

			cell.use_floor_texture = use_floor_texture

			cell.floor_texture_scale = floor_texture_scale


			# ------------------------------------------------
			# Wall Texture
			# ------------------------------------------------

			cell.wall_texture = wall_texture

			cell.use_wall_texture = use_wall_texture

			cell.wall_texture_scale = wall_texture_scale


			# ------------------------------------------------
			# Reward Texture
			# ------------------------------------------------

			cell.reward_texture = reward_texture

			cell.use_reward_texture = use_reward_texture

			cell.reward_texture_scale = reward_texture_scale


			# ------------------------------------------------
			# Penalty Texture
			# ------------------------------------------------

			cell.penalty_texture = penalty_texture

			cell.use_penalty_texture = use_penalty_texture

			cell.penalty_texture_scale = penalty_texture_scale


			# ------------------------------------------------
			# Goal Texture
			# ------------------------------------------------

			cell.goal_texture = goal_texture

			cell.use_goal_texture = use_goal_texture

			cell.goal_texture_scale = goal_texture_scale


			# ------------------------------------------------
			# اضافه کردن به Cells
			# ------------------------------------------------

			cells_node.add_child(
				cell
			)


# ============================================================
# Input
# ============================================================

func _input(
	event: InputEvent
) -> void:
	if not game_started:
		return

	if game_finished:

		return


	if event is InputEventKey:

		var key_event: InputEventKey = event


		# ----------------------------------------------------
		# Key Down
		# ----------------------------------------------------

		if key_event.pressed and not key_event.echo:

			var direction: Vector2i = Vector2i.ZERO


			match key_event.keycode:

				KEY_W:

					direction = Vector2i(
						0,
						-1
					)


				KEY_S:

					direction = Vector2i(
						0,
						1
					)


				KEY_A:

					direction = Vector2i(
						-1,
						0
					)


				KEY_D:

					direction = Vector2i(
						1,
						0
					)


			if direction != Vector2i.ZERO:

				held_direction = direction

				last_input_direction = direction


				# اگر Player در حال حرکت نیست،
				# حرکت را فوراً شروع می‌کنیم.

				if not is_player_moving:

					move_player(
						direction
					)


		# ----------------------------------------------------
		# Key Up
		# ----------------------------------------------------

		elif not key_event.pressed:

			var released_direction: Vector2i = Vector2i.ZERO


			match key_event.keycode:

				KEY_W:

					released_direction = Vector2i(
						0,
						-1
					)


				KEY_S:

					released_direction = Vector2i(
						0,
						1
					)


				KEY_A:

					released_direction = Vector2i(
						-1,
						0
					)


				KEY_D:

					released_direction = Vector2i(
						1,
						0
					)


			# فقط اگر همان جهتی که نگه داشته شده
			# رها شده باشد، آن را پاک می‌کنیم.

			if released_direction == held_direction:

				held_direction = Vector2i.ZERO


# ============================================================
# Move Player
# ============================================================

func move_player(
	direction: Vector2i
) -> void:

	if game_finished:

		return


	if is_player_moving:

		return


	var target_position: Vector2i = (
		player_grid_position + direction
	)


	# --------------------------------------------------------
	# خارج Grid
	# --------------------------------------------------------

	if not is_inside_grid(
		target_position
	):

		return


	# --------------------------------------------------------
	# Wall
	# --------------------------------------------------------

	if is_wall(
		target_position
	):

		return


	# --------------------------------------------------------
	# ثبت جهت آخرین حرکت
	# --------------------------------------------------------

	last_input_direction = direction


	# --------------------------------------------------------
	# ثبت موقعیت منطقی جدید
	# --------------------------------------------------------

	var previous_grid_position: Vector2i = (
		player_grid_position
	)


	player_grid_position = target_position


	# --------------------------------------------------------
	# شروع حرکت نرم
	# --------------------------------------------------------

	move_player_smoothly(
		previous_grid_position,
		target_position
	)


# ============================================================
# Smooth Player Movement
# ============================================================

func move_player_smoothly(
	from_grid: Vector2i,
	to_grid: Vector2i
) -> void:

	is_player_moving = true
	if player_node.has_method("set_move_direction"):
		player_node.set_move_direction(
			Vector2(to_grid - from_grid)
		)


	# --------------------------------------------------------
	# مختصات واقعی شروع و پایان
	# --------------------------------------------------------

	var start_position: Vector2 = grid_to_world(
		from_grid
	)


	var target_position: Vector2 = grid_to_world(
		to_grid
	)


	# --------------------------------------------------------
	# اگر Tween قبلی وجود داشت
	# --------------------------------------------------------

	if player_tween != null:

		player_tween.kill()

		player_tween = null



	# --------------------------------------------------------
	# Tween جدید
	# --------------------------------------------------------	
	player_tween = create_tween()


	player_tween.set_trans(
		Tween.TRANS_SINE
	)


	player_tween.set_ease(
		Tween.EASE_IN_OUT
	)


	player_tween.tween_property(
		player_node,
		"position",
		target_position,
		maxf(
			movement_duration,
			0.01
		)
	)


	# --------------------------------------------------------
	# وقتی حرکت تمام شد
	# --------------------------------------------------------

	player_tween.finished.connect(
		_on_player_movement_finished
	)


	# --------------------------------------------------------
	# Camera
	# --------------------------------------------------------

	move_camera_smoothly(
		start_position,
		target_position
	)


# ============================================================
# Player Movement Finished
# ============================================================

func _on_player_movement_finished() -> void:

	is_player_moving = false


	player_node.position = grid_to_world(
		player_grid_position
	)


	# --------------------------------------------------------
	# پردازش Cell مقصد
	# --------------------------------------------------------

	process_cell(
		player_grid_position
	)


	# --------------------------------------------------------
	# Visibility
	# --------------------------------------------------------

	update_visibility()


	# --------------------------------------------------------
	# اگر Goal نبود، Camera را دقیقاً تنظیم می‌کنیم
	# --------------------------------------------------------

	update_camera_position()


	player_tween = null


	# --------------------------------------------------------
	# ادامه حرکت در صورت نگه داشتن کلید
	# --------------------------------------------------------

	if game_finished:

		return


	if held_direction != Vector2i.ZERO:

		move_player(
			held_direction
		)


# ============================================================
# Grid To World
# ============================================================

func grid_to_world(
	grid_position: Vector2i
) -> Vector2:

	return Vector2(
		grid_position.x * CELL_SIZE
		+ CELL_SIZE / 2.0,

		grid_position.y * CELL_SIZE
		+ CELL_SIZE / 2.0
	)


# ============================================================
# Smooth Camera Movement
# ============================================================

func move_camera_smoothly(
	from_position: Vector2,
	to_position: Vector2
) -> void:

	var camera_tween: Tween = create_tween()


	camera_tween.set_trans(
		Tween.TRANS_SINE
	)


	camera_tween.set_ease(
		Tween.EASE_IN_OUT
	)


	camera.position = from_position


	camera_tween.tween_property(
		camera,
		"position",
		to_position,
		maxf(
			movement_duration,
			0.01
		)
	)


# ============================================================
# Update Visibility
# ============================================================

func update_visibility() -> void:

	for y in range(GRID_HEIGHT):

		for x in range(GRID_WIDTH):

			var cell_position: Vector2i = Vector2i(
				x,
				y
			)


			var visible_now: bool = (
				is_cell_visible(
					player_grid_position,
					cell_position
				)
			)


			# ------------------------------------------------
			# Cell دیده شده
			# ------------------------------------------------

			if visible_now:

				explored[y][x] = true


			var cell_name: String = (
				"Cell_%d_%d" % [
					x,
					y
				]
			)


			var cell: GridCell = (
				cells_node.get_node_or_null(
					cell_name
				) as GridCell
			)


			if cell != null:

				cell.set_visibility(
					visible_now,
					explored[y][x]
				)


# ============================================================
# Is Cell Visible
# ============================================================

func is_cell_visible(
	origin: Vector2i,
	target: Vector2i
) -> bool:

	var distance_x: int = abs(
		target.x - origin.x
	)


	var distance_y: int = abs(
		target.y - origin.y
	)


	var distance: int = maxi(
		distance_x,
		distance_y
	)


	# خارج شعاع دید
	if distance > VISION_RADIUS:

		return false


	# خود Player
	if target == origin:

		return true


	# Line of Sight
	return has_line_of_sight(
		origin,
		target
	)


# ============================================================
# Line Of Sight
# ============================================================

func has_line_of_sight(
	origin: Vector2i,
	target: Vector2i
) -> bool:

	var x0: int = origin.x

	var y0: int = origin.y


	var x1: int = target.x

	var y1: int = target.y


	var dx: int = abs(
		x1 - x0
	)


	var dy: int = abs(
		y1 - y0
	)


	var sx: int = 1 if x0 < x1 else -1

	var sy: int = 1 if y0 < y1 else -1


	var err: int = dx - dy


	var current_x: int = x0

	var current_y: int = y0


	while true:

		# ----------------------------------------------------
		# رسیدن به مقصد
		# ----------------------------------------------------

		if (
			current_x == x1
			and current_y == y1
		):

			return true


		var e2: int = 2 * err


		if e2 > -dy:

			err -= dy

			current_x += sx


		if e2 < dx:

			err += dx

			current_y += sy


		# ----------------------------------------------------
		# رسیدن به مقصد
		# ----------------------------------------------------

		if (
			current_x == x1
			and current_y == y1
		):

			return true


		# ----------------------------------------------------
		# برخورد با Wall
		# ----------------------------------------------------

		if is_wall(
			Vector2i(
				current_x,
				current_y
			)
		):

			return false


	# --------------------------------------------------------
	# جلوگیری از خطای Return
	# --------------------------------------------------------

	return false


# ============================================================
# Is Inside Grid
# ============================================================

func is_inside_grid(
	position: Vector2i
) -> bool:

	return (
		position.x >= 0
		and position.x < GRID_WIDTH
		and position.y >= 0
		and position.y < GRID_HEIGHT
	)


# ============================================================
# Is Wall
# ============================================================

func is_wall(
	position: Vector2i
) -> bool:

	return (
		grid[position.y][position.x]
		== CellType.WALL
	)


# ============================================================
# Process Cell
# ============================================================

func process_cell(
	position: Vector2i
) -> void:

	var cell_type: CellType = grid[
		position.y
	][
		position.x
	]


	match cell_type:

		# ----------------------------------------------------
		# Reward
		# ----------------------------------------------------

		CellType.REWARD:

			player_reward += 10
			
			player_node.play_effect(
				Color(0.3, 1.0, 0.3)
			)
			
			update_hud()

			print(
				"Reward +10"
			)


			print(
				"Total Reward: ",
				player_reward
			)


			# Reward به Floor تبدیل می‌شود
			grid[
				position.y
			][
				position.x
			] = CellType.FLOOR


			update_cell_visual(
				position
			)


		# ----------------------------------------------------
		# Penalty
		# ----------------------------------------------------

		CellType.PENALTY:

			player_reward -= 10
			
			player_node.play_effect(
				Color(1.0,0.2,0.2)
			)

			update_hud()

			print(
				"Penalty -10"
			)


			print(
				"Total Reward: ",
				player_reward
			)


			# Penalty به Floor تبدیل می‌شود
			grid[
				position.y
			][
				position.x
			] = CellType.FLOOR


			update_cell_visual(
				position
			)


		# ----------------------------------------------------
		# Goal
		# ----------------------------------------------------

		CellType.GOAL:

			game_finished = true
			
			update_hud()

			print(
				"GOAL REACHED!"
			)


			print(
				"Final Reward: ",
				player_reward
			)


# ============================================================
# Update Cell Visual
# ============================================================

func update_cell_visual(
	position: Vector2i
) -> void:

	var cell_name: String = (
		"Cell_%d_%d" % [
			position.x,
			position.y
		]
	)


	var cell: GridCell = (
		cells_node.get_node_or_null(
			cell_name
		) as GridCell
	)


	if cell != null:

		cell.setup(
			grid[position.y][position.x],
			CELL_SIZE
		)


		var currently_visible: bool = (
			is_cell_visible(
				player_grid_position,
				position
			)
		)


		cell.set_visibility(
			currently_visible,
			explored[position.y][position.x]
		)


# ============================================================
# Update Player Position
# ============================================================

func update_player_position() -> void:

	player_node.position = grid_to_world(
		player_grid_position
	)


# ============================================================
# Update Camera Position
# ============================================================

func update_camera_position() -> void:

	camera.position = grid_to_world(
		player_grid_position
	)

func update_hud() -> void:

	if reward_label != null:
		reward_label.text = "Reward: " + str(player_reward)

	if status_label != null:

		if game_finished:
			status_label.text = "GOAL REACHED!"
		else:
			status_label.text = "Find Goal"
			
			
# ============================================================
# START GAME
# ============================================================

func start_game(level:int) -> void:


	randomize()


	apply_difficulty(level)


	create_grid()


	create_exploration_map()


	create_cells()


	update_player_position()


	update_camera_position()


	update_visibility()


	game_started = true
	
# ============================================================
# APPLY DIFFICULTY
# ============================================================

func apply_difficulty(level:int) -> void:


	match level:


		0:
			current_difficulty = Difficulty.EASY

			vision_radius = 9

			step_cost = 1

			EXTRA_OPENINGS = 80

			dynamic_goal = false



		1:
			current_difficulty = Difficulty.MEDIUM

			vision_radius = 6

			step_cost = 2

			EXTRA_OPENINGS = 55

			dynamic_goal = false



		2:
			current_difficulty = Difficulty.HARD

			vision_radius = 4

			step_cost = 3

			EXTRA_OPENINGS = 35

			dynamic_goal = false



		3:
			current_difficulty = Difficulty.VERY_HARD

			vision_radius = 3

			step_cost = 4

			EXTRA_OPENINGS = 25

			dynamic_goal = true
