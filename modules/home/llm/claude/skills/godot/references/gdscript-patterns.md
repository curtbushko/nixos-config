# GDScript Patterns and Idioms Reference

## Type System

### Always Use Type Hints

```gdscript
# Variables
var health: int = 100
var velocity: Vector2 = Vector2.ZERO
var enemies: Array[Enemy] = []
var inventory: Dictionary = {}

# Constants
const MAX_SPEED: float = 300.0
const GRAVITY: float = 980.0

# Function parameters and return types
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

func get_enemies_in_range(center: Vector2, radius: float) -> Array[Enemy]:
    var result: Array[Enemy] = []
    # ...
    return result

# Signals with types
signal health_changed(new_health: int, max_health: int)
signal item_picked_up(item: Item)
```

### Custom Types with class_name

```gdscript
# weapon_data.gd
class_name WeaponData
extends Resource

@export var weapon_name: String
@export var damage: int
@export var attack_speed: float

# Now can use WeaponData as a type
var equipped_weapon: WeaponData
```

### Enums

```gdscript
# Define enum
enum State { IDLE, RUNNING, JUMPING, FALLING, ATTACKING }
enum DamageType { PHYSICAL, FIRE, ICE, LIGHTNING }

# Use enum
var current_state: State = State.IDLE

func take_damage(amount: int, type: DamageType) -> void:
    match type:
        DamageType.FIRE:
            amount = int(amount * fire_resistance)
        DamageType.ICE:
            amount = int(amount * ice_resistance)
    health -= amount
```

---

## Signals

### Signal Declaration

```gdscript
# Simple signal
signal died

# Signal with parameters (always type them)
signal health_changed(new_health: int, max_health: int)
signal damage_taken(amount: int, source: Node, damage_type: DamageType)

# Signal with complex types
signal inventory_updated(items: Array[Item])
```

### Signal Connection

```gdscript
# Modern callable syntax (preferred)
button.pressed.connect(_on_button_pressed)
health_component.died.connect(_on_player_died)

# With additional arguments
enemy.died.connect(_on_enemy_died.bind(enemy.id))

# One-shot connection (auto-disconnects after first emit)
animation_player.animation_finished.connect(
    _on_attack_finished,
    CONNECT_ONE_SHOT
)

# Deferred connection (called at end of frame)
timer.timeout.connect(_on_timeout, CONNECT_DEFERRED)
```

### Signal Emission

```gdscript
# Emit without arguments
died.emit()

# Emit with arguments
health_changed.emit(health, max_health)
damage_taken.emit(amount, attacker, DamageType.PHYSICAL)
```

### Disconnecting Signals

```gdscript
func _exit_tree() -> void:
    # Check if connected before disconnecting
    if health_component.died.is_connected(_on_died):
        health_component.died.disconnect(_on_died)

# Or disconnect all from a specific signal
func cleanup() -> void:
    for connection in died.get_connections():
        died.disconnect(connection.callable)
```

---

## Properties (Setters/Getters)

### Basic Property

```gdscript
var health: int = 100:
    set(value):
        health = clampi(value, 0, max_health)
        health_changed.emit(health, max_health)
        if health <= 0:
            died.emit()
    get:
        return health
```

### Computed Property

```gdscript
var is_dead: bool:
    get:
        return health <= 0

var health_percent: float:
    get:
        return float(health) / float(max_health) if max_health > 0 else 0.0
```

### Property with Validation

```gdscript
var move_speed: float = 100.0:
    set(value):
        move_speed = maxf(value, 0.0)  # Never negative

var level: int = 1:
    set(value):
        level = clampi(value, 1, MAX_LEVEL)
        _recalculate_stats()
```

---

## Node References

### @onready for Child Nodes

```gdscript
# Evaluated after _ready runs
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

# Unique name access (set "Access as Unique Name" in editor)
@onready var player := %Player
@onready var game_ui := %GameUI
```

### @export for External References

```gdscript
# Assigned in editor
@export var target: Node2D
@export var health_component: HealthComponent
@export var projectile_scene: PackedScene

# Export with hints
@export_range(0, 100) var starting_health: int = 100
@export_file("*.tscn") var next_level: String
@export_enum("Sword", "Axe", "Bow") var weapon_type: int
@export_flags("Fire", "Water", "Earth", "Wind") var elements: int
```

### Safe Node Access

```gdscript
# May return null
var optional := get_node_or_null("OptionalChild") as OptionalType

# With null check
if optional:
    optional.do_something()

# Or use if var pattern
if var player := get_node_or_null("Player") as Player:
    player.notify()
```

---

## Resource Pattern

### Custom Resource Definition

```gdscript
# item_data.gd
class_name ItemData
extends Resource

@export var item_name: String
@export var description: String
@export var icon: Texture2D
@export var stack_size: int = 1
@export var value: int = 0

# Resources can have methods
func get_display_name() -> String:
    return item_name if item_name else "Unknown Item"
```

### Creating Resources

```gdscript
# In code
var sword := WeaponData.new()
sword.weapon_name = "Iron Sword"
sword.damage = 25

# Save to file
ResourceSaver.save(sword, "res://resources/weapons/iron_sword.tres")

# Or create .tres files in editor
```

### Using Resources

```gdscript
# Load resource
var weapon_data: WeaponData = load("res://resources/weapons/iron_sword.tres")

# Or preload
const SwordData := preload("res://resources/weapons/iron_sword.tres")

# Use in export
@export var item_data: ItemData

func _ready() -> void:
    $Label.text = item_data.get_display_name()
    $Icon.texture = item_data.icon
```

---

## Coroutines and Async

### Basic Await

```gdscript
func attack() -> void:
    # Play animation and wait
    animation_player.play("attack")
    await animation_player.animation_finished

    # Then deal damage
    deal_damage()
```

### Await with Timer

```gdscript
func spawn_enemies_with_delay() -> void:
    for i in 5:
        spawn_enemy()
        await get_tree().create_timer(0.5).timeout
```

### Await Custom Signal

```gdscript
func wait_for_player_input() -> void:
    show_prompt()
    var choice: int = await player_chose  # Custom signal
    process_choice(choice)
```

### Async Operations Pattern

```gdscript
signal operation_completed(result: Variant)

func do_async_operation() -> Variant:
    # Start async work
    _start_background_task()

    # Wait for completion
    var result := await operation_completed
    return result
```

---

## Error Handling

### Assertions (Debug Only)

```gdscript
func set_health(value: int) -> void:
    assert(value >= 0, "Health cannot be negative")
    assert(value <= max_health, "Health cannot exceed max_health")
    health = value
```

### Push Errors/Warnings

```gdscript
func get_item(index: int) -> Item:
    if index < 0 or index >= items.size():
        push_error("Item index out of bounds: %d" % index)
        return null
    return items[index]

func load_level(name: String) -> void:
    var path := "res://levels/%s.tscn" % name
    if not ResourceLoader.exists(path):
        push_warning("Level not found: %s" % name)
        return
    # Load level...
```

### Result Pattern

```gdscript
# For operations that can fail
class_name Result
extends RefCounted

var success: bool
var value: Variant
var error: String

static func ok(val: Variant) -> Result:
    var r := Result.new()
    r.success = true
    r.value = val
    return r

static func err(message: String) -> Result:
    var r := Result.new()
    r.success = false
    r.error = message
    return r
```

```gdscript
func load_save_file(path: String) -> Result:
    if not FileAccess.file_exists(path):
        return Result.err("Save file not found")

    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return Result.err("Could not open file")

    var data := file.get_var()
    return Result.ok(data)

# Usage
var result := load_save_file("user://save.dat")
if result.success:
    apply_save_data(result.value)
else:
    show_error(result.error)
```

---

## Common Idioms

### Null Coalescing

```gdscript
# GDScript doesn't have ?? operator, use ternary
var name: String = player.custom_name if player.custom_name else "Player"

# Or for node references
var target: Node2D = explicit_target if explicit_target else _find_nearest_enemy()
```

### Safe Navigation

```gdscript
# Check before accessing
if target and is_instance_valid(target):
    target.take_damage(damage)

# Or use is_instance_valid for nodes that might be freed
func _process(_delta: float) -> void:
    if not is_instance_valid(chase_target):
        chase_target = null
        return
    move_toward(chase_target.position)
```

### Dictionary with Default

```gdscript
# get() with default value
var damage: int = damage_modifiers.get(element, 1.0)

# Or use has() check
if inventory.has(item_id):
    inventory[item_id] += 1
else:
    inventory[item_id] = 1
```

### Array Operations

```gdscript
# Filter
var alive_enemies := enemies.filter(func(e): return e.is_alive)

# Map
var enemy_positions := enemies.map(func(e): return e.position)

# Any/All
var any_alive := enemies.any(func(e): return e.is_alive)
var all_dead := enemies.all(func(e): return not e.is_alive)

# Reduce
var total_damage := hits.reduce(func(acc, hit): return acc + hit.damage, 0)

# Find
var nearest := enemies.reduce(func(a, b):
    return a if position.distance_to(a.position) < position.distance_to(b.position) else b
)
```

### String Formatting

```gdscript
# Format strings (preferred)
var message := "Player %s dealt %d damage" % [player_name, damage]
var path := "res://levels/level_%02d.tscn" % level_number

# String interpolation (GDScript doesn't have this, use format)
```

---

## Autoload Patterns

### Event Bus

```gdscript
# autoloads/events.gd
extends Node

signal player_died
signal enemy_killed(enemy: Enemy)
signal level_completed(level_name: String)
signal coins_changed(new_amount: int)
```

### Service Locator

```gdscript
# autoloads/services.gd
extends Node

var audio: AudioManager
var save: SaveManager
var input: InputManager

func _ready() -> void:
    audio = AudioManager.new()
    save = SaveManager.new()
    input = InputManager.new()
```

### Game State

```gdscript
# autoloads/game_state.gd
extends Node

signal state_changed(old_state: State, new_state: State)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU:
    set(value):
        var old := current_state
        current_state = value
        state_changed.emit(old, current_state)
        _handle_state_change(old, current_state)

func _handle_state_change(old: State, new: State) -> void:
    match new:
        State.PAUSED:
            get_tree().paused = true
        State.PLAYING:
            get_tree().paused = false
```

---

## Anti-Patterns to Avoid

### Avoid get_node with Long Paths

```gdscript
# BAD
var player = get_node("/root/Main/World/Entities/Player")

# GOOD
var player = get_tree().get_first_node_in_group("player")
# or
@export var player: Player
```

### Avoid Untyped Variables

```gdscript
# BAD
var health = 100
var enemies = []

# GOOD
var health: int = 100
var enemies: Array[Enemy] = []
```

### Avoid Anonymous Functions in Hot Paths

```gdscript
# BAD - Creates closure every frame
func _process(_delta: float) -> void:
    var filtered := enemies.filter(func(e): return e.is_alive)

# GOOD - Use named function
func _process(_delta: float) -> void:
    var filtered := enemies.filter(_is_alive)

func _is_alive(enemy: Enemy) -> bool:
    return enemy.is_alive
```

### Avoid Deep Inheritance

```gdscript
# BAD
Entity -> Character -> Enemy -> FlyingEnemy -> Dragon

# GOOD - Use composition
Dragon:
  - HealthComponent
  - MovementComponent (configured for flying)
  - AIComponent (dragon behavior)
```

### Avoid Magic Numbers

```gdscript
# BAD
if health < 20:
    play_warning()
velocity.y += 980 * delta

# GOOD
const LOW_HEALTH_THRESHOLD: int = 20
const GRAVITY: float = 980.0

if health < LOW_HEALTH_THRESHOLD:
    play_warning()
velocity.y += GRAVITY * delta
```
