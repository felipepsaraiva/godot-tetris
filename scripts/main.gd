extends Node2D


const i_tetromino: Array = [
    [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)], # 0 degrees
    [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)], # 90 degrees
    [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)], # 180 degrees
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)]  # 270 degrees
]

const t_tetromino: Array = [
    [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], # 0 degrees
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)], # 90 degrees
    [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)], # 180 degrees
    [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]  # 270 degrees
]

const o_tetromino: Array = [
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # All rotations are the same
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # All rotations are the same
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], # All rotations are the same
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]  # All rotations are the same
]

const z_tetromino: Array = [
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)], # 0 degrees
    [Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)], # 90 degrees
    [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)], # 180 degrees
    [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]  # 270 degrees
]

const s_tetromino: Array = [
    [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)], # 0 degrees
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)], # 90 degrees
    [Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)], # 180 degrees
    [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)]  # 270 degrees
]

const l_tetromino: Array = [
    [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], # 0 degrees
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)], # 90 degrees
    [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)], # 180 degrees
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)]  # 270 degrees
]

const j_tetromino: Array = [
    [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)], # 0 degrees
    [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)], # 90 degrees
    [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)], # 180 degrees
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)]  # 270 degrees
]

const all_tetrominos: Array = [i_tetromino, t_tetromino, o_tetromino, z_tetromino, l_tetromino, j_tetromino]
var tetrominos: Array = all_tetrominos.duplicate()

const COLS: int = 10
const ROWS: int = 20

const movement_directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const START_POSITION: Vector2i = Vector2i(4, 1)
var current_position: Vector2i
var fall_timer: float = 0
var fall_interval: float = 1.0
var fast_fall_multiplier: float = 15.0

var current_tetromino_type: Array
var next_tetromino_type: Array
var rotation_index: int = 0
var active_tetromino: Array = []

const tileset_id: int = 0
var piece_atlas: Vector2i
var next_piece_atlas: Vector2i

const CLEAR_REWARD: int = 1
var score: int = 0
var is_game_running: bool = false

@onready var board_layer: TileMapLayer = $Board
@onready var active_layer: TileMapLayer = $Active


func _ready() -> void:
    start_game()
    $GameHUD/StartButton.pressed.connect(start_game)

func _physics_process(delta: float) -> void:
    if not is_game_running:
        return

    var move_direction: Vector2i = Vector2i.ZERO

    if Input.is_action_just_pressed('ui_left'):
        move_direction = Vector2i.LEFT
    elif Input.is_action_just_pressed('ui_right'):
        move_direction = Vector2i.RIGHT

    if move_direction != Vector2i.ZERO:
        move_tetromino(move_direction)

    if Input.is_action_just_pressed('ui_up'):
        rotate_tetromino()

    var current_fall_interval = fall_interval
    if Input.is_action_pressed('ui_down'):
        current_fall_interval /= fast_fall_multiplier

    fall_timer += delta
    if fall_timer >= current_fall_interval:
        move_tetromino(Vector2i.DOWN)
        fall_timer = 0

func start_game() -> void:
    clear_active_tetromino()
    clear_next_tetromino_preview()
    clear_board()
    score = 0
    $GameHUD/ScoreLabel.text = 'Score: ' + str(score)
    $GameHUD/GameOverLabel.visible = false

    current_tetromino_type = choose_tetromino()
    piece_atlas = Vector2i(all_tetrominos.find(current_tetromino_type), 0)
    next_tetromino_type = choose_tetromino()
    next_piece_atlas = Vector2i(all_tetrominos.find(next_tetromino_type), 0)
    initialize_tetromino()
    is_game_running = true

func choose_tetromino() -> Array:
    if tetrominos.is_empty():
        tetrominos = all_tetrominos.duplicate()
    tetrominos.shuffle()
    return tetrominos.pop_front()

func initialize_tetromino() -> void:
    current_position = START_POSITION
    active_tetromino = current_tetromino_type[rotation_index]
    render_tetromino(active_tetromino, current_position, piece_atlas)
    render_tetromino(next_tetromino_type[0], Vector2i(13, 4), next_piece_atlas)

func render_tetromino(tetromino: Array, position: Vector2i, atlas: Vector2i) -> void:
    for block in tetromino:
        active_layer.set_cell(position + block, tileset_id, atlas)

func clear_active_tetromino() -> void:
    for block in active_tetromino:
        active_layer.erase_cell(current_position + block)

func clear_next_tetromino_preview() -> void:
    if len(next_tetromino_type) > 0:
        for block in next_tetromino_type[0]:
            active_layer.erase_cell(Vector2i(13, 4) + block)

func clear_board() -> void:
    for row in range(1, ROWS + 1):
        for col in range(1, COLS + 1):
            board_layer.erase_cell(Vector2i(col, row))

func move_tetromino(direction: Vector2i) -> void:
    if is_valid_move(direction):
        clear_active_tetromino()
        current_position += direction
        render_tetromino(active_tetromino, current_position, piece_atlas)
    elif direction == Vector2i.DOWN:
        land_tetromino()
        check_rows()
        current_tetromino_type = next_tetromino_type
        piece_atlas = next_piece_atlas
        clear_next_tetromino_preview()
        next_tetromino_type = choose_tetromino()
        next_piece_atlas = Vector2i(all_tetrominos.find(next_tetromino_type), 0)
        initialize_tetromino()
        check_game_over()

func rotate_tetromino() -> void:
    var next_rotation = (rotation_index + 1) % 4
    if not is_valid_rotation(next_rotation):
        return

    clear_active_tetromino()
    rotation_index = next_rotation
    active_tetromino = current_tetromino_type[rotation_index]
    render_tetromino(active_tetromino, current_position, piece_atlas)

func land_tetromino() -> void:
    for block in active_tetromino:
        active_layer.erase_cell(current_position + block)
        board_layer.set_cell(current_position + block, tileset_id, piece_atlas)

func is_valid_move(direction: Vector2i) -> bool:
    for block in active_tetromino:
        if not is_within_bounds(current_position + block + direction):
            return false
    return true

func is_valid_rotation(rotation_index: int) -> bool:
    var rotated_tetromino = current_tetromino_type[rotation_index]
    for block in rotated_tetromino:
        if not is_within_bounds(current_position + block):
            return false
    return true

func is_within_bounds(position: Vector2i) -> bool:
    var valid_rect = Rect2i(Vector2i(1, 1), Vector2i(COLS, ROWS))
    if not valid_rect.has_point(position):
        return false

    var tile_id = board_layer.get_cell_source_id(position)
    return tile_id == -1

func check_rows() -> void:
    var row: int = ROWS
    while row > 0:
        var is_full: bool = true
        for col in range(1, COLS + 1):
            if is_within_bounds(Vector2i(col, row)):
                is_full = false
                break

        if is_full:
            print('Row %d is full.' % row)
            shift_row(row)
            score += CLEAR_REWARD
            $GameHUD/ScoreLabel.text = 'Score: ' + str(score)
        else:
            row -= 1

func shift_row(row: int) -> void:
    var atlas: Vector2i
    for r in range(row, 1, -1):
        for c in range(1, COLS + 1):
            atlas = board_layer.get_cell_atlas_coords(Vector2i(c, r - 1))
            if atlas == Vector2i(-1, -1):
                board_layer.erase_cell(Vector2i(c, r))
            else:
                board_layer.set_cell(Vector2i(c, r), tileset_id, atlas)

func check_game_over() -> void:
    for block in active_tetromino:
        if not is_within_bounds(current_position + block):
            land_tetromino()
            is_game_running = false
            $GameHUD/GameOverLabel.visible = true
            return
