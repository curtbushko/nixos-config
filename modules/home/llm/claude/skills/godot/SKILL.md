---
name: godot
description: Comprehensive Godot game development skill with TDD practices using GUT framework, game design patterns (State Machine, Component, Observer), scene organization, GDScript best practices, and performance optimization. Use this skill when building Godot games or game systems.
---

# Godot Game Development Skill

You are an expert Godot game developer who follows Test-Driven Development (TDD) principles and game programming best practices.

## Critical Requirements

### Build Quality (NON-NEGOTIABLE)
- **Project MUST run without errors or warnings**
- Before completing any task, verify:
  - Project runs in editor without errors
  - No script errors in Output panel
  - GUT tests pass (`gut -gexit` or run from editor)
- If any of these fail, fix the issues before marking the task complete
- NEVER leave code in a broken state

### Output and Documentation Standards
- **NEVER use emojis in code, comments, documentation, or any output**
- Keep all communication professional and text-based
- Use clear, descriptive text instead of visual symbols

### Test-Driven Development (TDD)
**ALWAYS follow the TDD cycle when implementing new functionality:**

1. **RED**: Write a failing test first
   - Write the test that describes the desired behavior
   - Run GUT and confirm it fails for the right reason
   - This validates that the test can actually detect failures

2. **GREEN**: Write minimal code to make the test pass
   - Implement just enough code to make the test pass
   - Don't add extra features or over-engineer
   - Run GUT and confirm it passes

3. **REFACTOR**: Improve the code while keeping tests green
   - Clean up the implementation
   - Remove duplication
   - Improve naming and structure
   - Run tests after each refactoring to ensure they still pass

## Project Structure

### Recommended Directory Layout
```
project/
├── addons/               # Third-party addons (GUT, etc.)
├── assets/               # Raw assets (art, audio, fonts)
│   ├── sprites/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── shaders/
├── resources/            # .tres resource files
│   ├── themes/
│   ├── materials/
│   └── data/             # Game data resources
├── scenes/               # .tscn scene files
│   ├── actors/           # Player, enemies, NPCs
│   ├── levels/           # Game levels/maps
│   ├── ui/               # UI scenes
│   └── components/       # Reusable scene components
├── scripts/              # GDScript files
│   ├── autoloads/        # Singleton scripts
│   ├── classes/          # Base classes and utilities
│   ├── components/       # Component scripts
│   ├── resources/        # Custom Resource scripts
│   └── states/           # State machine states
├── tests/                # GUT test scripts
│   ├── unit/             # Unit tests
│   ├── integration/      # Integration tests
│   └── fixtures/         # Test fixtures and mocks
├── project.godot
└── .gutconfig.json       # GUT configuration
```

### File Naming Conventions
- Scenes: `snake_case.tscn` (e.g., `player_character.tscn`)
- Scripts: `snake_case.gd` (e.g., `player_controller.gd`)
- Resources: `snake_case.tres` (e.g., `player_stats.tres`)
- Tests: `test_<script_name>.gd` (e.g., `test_player_controller.gd`)
- Classes: Match script name to class_name in `PascalCase`

## GUT Testing Framework

### Setup
Install GUT addon and configure `.gutconfig.json`:
```json
{
  "dirs": ["res://tests/unit/", "res://tests/integration/"],
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true,
  "log_level": 2,
  "include_subdirs": true
}
```

### Test Structure
```gdscript
# tests/unit/test_player_health.gd
extends GutTest

var _player: Player

func before_each() -> void:
    _player = Player.new()
    add_child_autofree(_player)

func after_each() -> void:
    # Cleanup handled by autofree
    pass

func test_initial_health_equals_max_health() -> void:
    # Arrange
    var expected_health := 100

    # Act
    var actual_health := _player.health

    # Assert
    assert_eq(actual_health, expected_health, "Initial health should equal max health")

func test_take_damage_reduces_health() -> void:
    # Arrange
    var damage := 25
    var expected_health := 75

    # Act
    _player.take_damage(damage)

    # Assert
    assert_eq(_player.health, expected_health, "Health should be reduced by damage amount")

func test_take_damage_emits_health_changed_signal() -> void:
    # Arrange
    watch_signals(_player)

    # Act
    _player.take_damage(10)

    # Assert
    assert_signal_emitted(_player, "health_changed")

func test_health_cannot_go_below_zero() -> void:
    # Arrange
    var excessive_damage := 9999

    # Act
    _player.take_damage(excessive_damage)

    # Assert
    assert_eq(_player.health, 0, "Health should not go below zero")
    assert_true(_player.is_dead, "Player should be marked as dead")
```

### Testing Async Operations
```gdscript
func test_attack_cooldown() -> void:
    # Arrange
    _player.attack()

    # Act - wait for cooldown
    await wait_seconds(0.5)

    # Assert
    assert_true(_player.can_attack, "Should be able to attack after cooldown")

func test_animation_completes() -> void:
    # Arrange
    var animation_player := _player.get_node("AnimationPlayer")
    watch_signals(animation_player)

    # Act
    _player.play_attack_animation()
    await wait_for_signal(animation_player.animation_finished, 2.0)

    # Assert
    assert_signal_emitted(animation_player, "animation_finished")
```

### Mocking and Doubles
```gdscript
func test_enemy_uses_pathfinding() -> void:
    # Arrange - create a mock navigation agent
    var mock_nav := double(NavigationAgent2D).new()
    stub(mock_nav, "get_next_path_position").to_return(Vector2(100, 100))

    var enemy := Enemy.new()
    enemy.navigation_agent = mock_nav
    add_child_autofree(enemy)

    # Act
    enemy.move_toward_player()

    # Assert
    assert_called(mock_nav, "get_next_path_position")
```

### Running Tests
```bash
# Run all tests from command line
godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test file
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_player.gd

# Run tests matching pattern
godot --headless -s addons/gut/gut_cmdln.gd -ginclude_subdirs -gprefix=test_ -gdir=res://tests/
```

## Game Design Patterns

### State Machine Pattern
**Use for: Player states, enemy AI, game states, UI states**

```gdscript
# scripts/classes/state_machine.gd
class_name StateMachine
extends Node

signal state_changed(old_state: State, new_state: State)

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.state_machine = self

    if initial_state:
        current_state = initial_state
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(state_name: String) -> void:
    var new_state: State = states.get(state_name.to_lower())
    if new_state == null:
        push_error("State '%s' not found" % state_name)
        return

    if current_state:
        current_state.exit()

    var old_state := current_state
    current_state = new_state
    current_state.enter()
    state_changed.emit(old_state, new_state)
```

```gdscript
# scripts/classes/state.gd
class_name State
extends Node

var state_machine: StateMachine

func enter() -> void:
    pass

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func physics_update(_delta: float) -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass
```

```gdscript
# scripts/states/player_idle_state.gd
class_name PlayerIdleState
extends State

@export var actor: CharacterBody2D
@export var animated_sprite: AnimatedSprite2D

func enter() -> void:
    animated_sprite.play("idle")

func physics_update(_delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0:
        state_machine.transition_to("run")

    if Input.is_action_just_pressed("jump"):
        state_machine.transition_to("jump")
```

### Component Pattern
**Use for: Reusable behaviors across different actors**

```gdscript
# scripts/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(new_health: int, max_health: int)
signal damaged(amount: int, source: Node)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var invincibility_duration: float = 0.0

var health: int:
    set(value):
        var old_health := health
        health = clampi(value, 0, max_health)
        if health != old_health:
            health_changed.emit(health, max_health)
        if health <= 0 and old_health > 0:
            died.emit()

var is_invincible: bool = false

func _ready() -> void:
    health = max_health

func take_damage(amount: int, source: Node = null) -> void:
    if is_invincible or health <= 0:
        return

    health -= amount
    damaged.emit(amount, source)

    if invincibility_duration > 0:
        _start_invincibility()

func heal(amount: int) -> void:
    if health <= 0:
        return

    var actual_heal := mini(amount, max_health - health)
    health += actual_heal
    healed.emit(actual_heal)

func _start_invincibility() -> void:
    is_invincible = true
    await get_tree().create_timer(invincibility_duration).timeout
    is_invincible = false
```

```gdscript
# scripts/components/hitbox_component.gd
class_name HitboxComponent
extends Area2D

signal hit(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var knockback_force: float = 200.0

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
    if area is HurtboxComponent:
        var hurtbox := area as HurtboxComponent
        hurtbox.receive_hit(self)
        hit.emit(hurtbox)
```

```gdscript
# scripts/components/hurtbox_component.gd
class_name HurtboxComponent
extends Area2D

signal hurt(hitbox: HitboxComponent)

@export var health_component: HealthComponent

func receive_hit(hitbox: HitboxComponent) -> void:
    if health_component:
        health_component.take_damage(hitbox.damage, hitbox.owner)
    hurt.emit(hitbox)
```

### Observer Pattern (Signals)
**Use for: Decoupled communication between systems**

```gdscript
# scripts/autoloads/events.gd (Autoload)
extends Node

# Player events
signal player_spawned(player: Player)
signal player_died(player: Player)
signal player_health_changed(health: int, max_health: int)

# Game events
signal level_started(level_name: String)
signal level_completed(level_name: String)
signal game_paused
signal game_resumed

# Economy events
signal coins_changed(new_amount: int)
signal item_purchased(item_id: String)

# UI events
signal show_dialog(text: String)
signal hide_dialog
```

```gdscript
# Usage in player.gd
func _ready() -> void:
    Events.player_spawned.emit(self)

func _on_health_changed(new_health: int, max_health: int) -> void:
    Events.player_health_changed.emit(new_health, max_health)

func die() -> void:
    Events.player_died.emit(self)
```

```gdscript
# Usage in UI (completely decoupled)
func _ready() -> void:
    Events.player_health_changed.connect(_on_player_health_changed)
    Events.player_died.connect(_on_player_died)

func _on_player_health_changed(health: int, max_health: int) -> void:
    health_bar.value = float(health) / float(max_health) * 100
```

### Command Pattern
**Use for: Input handling, undo/redo, replays**

```gdscript
# scripts/classes/command.gd
class_name Command
extends RefCounted

func execute() -> void:
    pass

func undo() -> void:
    pass
```

```gdscript
# scripts/classes/move_command.gd
class_name MoveCommand
extends Command

var actor: Node2D
var direction: Vector2
var distance: float

func _init(p_actor: Node2D, p_direction: Vector2, p_distance: float) -> void:
    actor = p_actor
    direction = p_direction
    distance = p_distance

func execute() -> void:
    actor.position += direction * distance

func undo() -> void:
    actor.position -= direction * distance
```

```gdscript
# scripts/classes/command_history.gd
class_name CommandHistory
extends RefCounted

var history: Array[Command] = []
var current_index: int = -1

func execute(command: Command) -> void:
    # Remove any commands after current index (branching)
    if current_index < history.size() - 1:
        history.resize(current_index + 1)

    command.execute()
    history.append(command)
    current_index += 1

func undo() -> bool:
    if current_index < 0:
        return false

    history[current_index].undo()
    current_index -= 1
    return true

func redo() -> bool:
    if current_index >= history.size() - 1:
        return false

    current_index += 1
    history[current_index].execute()
    return true
```

### Object Pool Pattern
**Use for: Bullets, particles, frequently spawned objects**

```gdscript
# scripts/classes/object_pool.gd
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
@export var initial_size: int = 20
@export var can_grow: bool = true

var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
    _initialize_pool()

func _initialize_pool() -> void:
    for i in initial_size:
        _create_instance()

func _create_instance() -> Node:
    var instance := pooled_scene.instantiate()
    instance.set_process(false)
    instance.set_physics_process(false)
    if instance is Node2D or instance is Node3D:
        instance.visible = false
    add_child(instance)
    _available.append(instance)
    return instance

func acquire() -> Node:
    var instance: Node

    if _available.is_empty():
        if can_grow:
            instance = _create_instance()
            _available.erase(instance)
        else:
            push_warning("Object pool exhausted")
            return null
    else:
        instance = _available.pop_back()

    _in_use.append(instance)
    instance.set_process(true)
    instance.set_physics_process(true)
    if instance is Node2D or instance is Node3D:
        instance.visible = true

    if instance.has_method("on_pool_acquire"):
        instance.on_pool_acquire()

    return instance

func release(instance: Node) -> void:
    if instance not in _in_use:
        push_warning("Trying to release instance not from this pool")
        return

    if instance.has_method("on_pool_release"):
        instance.on_pool_release()

    instance.set_process(false)
    instance.set_physics_process(false)
    if instance is Node2D or instance is Node3D:
        instance.visible = false

    _in_use.erase(instance)
    _available.append(instance)
```

### Service Locator Pattern
**Use for: Accessing global services without tight coupling**

```gdscript
# scripts/autoloads/services.gd (Autoload)
extends Node

var _services: Dictionary = {}

func register(service_name: String, service: Object) -> void:
    if _services.has(service_name):
        push_warning("Service '%s' already registered, overwriting" % service_name)
    _services[service_name] = service

func unregister(service_name: String) -> void:
    _services.erase(service_name)

func get_service(service_name: String) -> Object:
    if not _services.has(service_name):
        push_error("Service '%s' not found" % service_name)
        return null
    return _services[service_name]

func has_service(service_name: String) -> bool:
    return _services.has(service_name)
```

## GDScript Best Practices

### Type Hints (Always Use)
```gdscript
# Variables
var health: int = 100
var position: Vector2 = Vector2.ZERO
var items: Array[Item] = []
var stats: Dictionary = {}

# Functions
func calculate_damage(base_damage: int, multiplier: float) -> int:
    return int(base_damage * multiplier)

func get_nearest_enemy(from_position: Vector2) -> Enemy:
    # Implementation
    return null

# Signals
signal health_changed(new_health: int, max_health: int)
signal item_collected(item: Item)
```

### Null Safety
```gdscript
# Use is_instance_valid() for nodes that might be freed
if is_instance_valid(target):
    target.take_damage(damage)

# Use get_node_or_null() instead of get_node()
var player := get_node_or_null("Player") as Player
if player:
    player.notify()

# Check array bounds
if index >= 0 and index < items.size():
    return items[index]
```

### Signal Connections
```gdscript
# Prefer callable syntax (type-safe)
button.pressed.connect(_on_button_pressed)
health_component.died.connect(_on_died)

# With arguments
timer.timeout.connect(_on_timeout.bind(enemy_id))

# One-shot connections
animation_player.animation_finished.connect(_on_animation_done, CONNECT_ONE_SHOT)

# Disconnect when needed
func _exit_tree() -> void:
    if health_component.died.is_connected(_on_died):
        health_component.died.disconnect(_on_died)
```

### Avoid Common Pitfalls
```gdscript
# BAD: String-based node paths are fragile
var player = get_node("/root/Main/World/Player")

# GOOD: Use exported references or groups
@export var player: Player
# or
var player := get_tree().get_first_node_in_group("player") as Player

# BAD: Hardcoded values
if health < 20:
    play_low_health_warning()

# GOOD: Use constants or exports
const LOW_HEALTH_THRESHOLD: int = 20
@export var low_health_threshold: int = 20

# BAD: Direct child manipulation across scenes
enemy.get_node("HealthBar").visible = false

# GOOD: Let the node manage its own children
enemy.hide_health_bar()
```

### Resource-Based Data
```gdscript
# scripts/resources/weapon_data.gd
class_name WeaponData
extends Resource

@export var weapon_name: String
@export var damage: int
@export var attack_speed: float
@export var range: float
@export var icon: Texture2D
@export var projectile_scene: PackedScene

func get_dps() -> float:
    return damage * attack_speed
```

```gdscript
# Usage
@export var weapon_data: WeaponData

func attack() -> void:
    var projectile := weapon_data.projectile_scene.instantiate()
    # Configure projectile with weapon_data
```

## Scene Organization

### Node Naming
- Use PascalCase for node names: `Player`, `HealthBar`, `SpawnPoint`
- Prefix with underscore for internal nodes: `_AnimationPlayer`, `_CollisionShape`
- Use descriptive names that indicate purpose

### Scene Hierarchy Best Practices
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── StateMachine
│   ├── IdleState
│   ├── RunState
│   └── JumpState
├── Components
│   ├── HealthComponent
│   ├── HurtboxComponent
│   └── HitboxComponent
└── UI
    └── HealthBar
```

### Scene Inheritance
```gdscript
# Base enemy scene (enemy_base.tscn)
# Inherit for specific enemies
# res://scenes/actors/enemies/slime.tscn inherits enemy_base.tscn
```

## Performance Guidelines

### Optimization Priorities
1. Avoid premature optimization
2. Profile before optimizing
3. Focus on algorithms first, micro-optimizations last

### Common Optimizations
```gdscript
# Cache node references
var _sprite: Sprite2D

func _ready() -> void:
    _sprite = $Sprite2D  # Cache once, use many times

# Avoid per-frame allocations
var _reusable_array: Array[Enemy] = []

func _physics_process(_delta: float) -> void:
    _reusable_array.clear()
    # Fill and use _reusable_array

# Use object pools for frequently spawned objects
# (See Object Pool pattern above)

# Use call_deferred for non-urgent operations
call_deferred("_update_ui")

# Use set_deferred for physics-safe property changes
collision_shape.set_deferred("disabled", true)
```

### Physics Optimization
```gdscript
# Use collision layers and masks properly
# Only detect what you need to detect

# Disable processing when not needed
func _on_screen_exited() -> void:
    set_physics_process(false)

func _on_screen_entered() -> void:
    set_physics_process(true)
```

## Code Review Checklist

- [ ] Project runs without errors or warnings
- [ ] GUT tests pass
- [ ] Code follows TDD (tests written first)
- [ ] Type hints used consistently
- [ ] Signals used for decoupled communication
- [ ] Node references cached where appropriate
- [ ] No hardcoded magic numbers (use constants/exports)
- [ ] Components are reusable and single-responsibility
- [ ] Scene hierarchy is logical and well-organized
- [ ] No emojis in code, comments, or documentation
- [ ] Resources used for data-driven design
- [ ] Proper null checks for nodes that might be freed

## Quick Reference

| Pattern | Use When |
|---------|----------|
| State Machine | Complex behavior with distinct states |
| Component | Reusable behavior across actors |
| Observer (Signals) | Decoupled communication |
| Command | Undo/redo, input buffering, replays |
| Object Pool | Frequently spawned/despawned objects |
| Service Locator | Global service access without singletons |

| Do | Don't |
|----|----|
| Use type hints | Use untyped variables |
| Cache node references | Call get_node() every frame |
| Use signals for communication | Direct method calls across scenes |
| Use Resources for data | Hardcode game data in scripts |
| Write tests first (TDD) | Write tests after (or never) |
| Use exported variables | Hardcode values |
| Use groups for finding nodes | Use absolute node paths |

## Additional Resources

### Reference Documentation (in this skill)

- `references/testing-patterns.md` - GUT testing patterns, TDD workflow, mocking, async tests
- `references/scene-architecture.md` - Scene composition, hierarchy patterns, communication
- `references/performance.md` - CPU, GPU, physics, and memory optimization
- `references/gdscript-patterns.md` - Type system, signals, properties, idioms
- `references/entities.md` - Entity composition, component design, systems, factories

### External Resources

- GUT Documentation: https://gut.readthedocs.io/
- GDQuest Tutorials: https://www.gdquest.com/
- Godot Best Practices: https://docs.godotengine.org/en/stable/tutorials/best_practices/
- Godot Design Patterns: https://www.gdquest.com/tutorial/godot/design-patterns/
