# Godot Testing Patterns Reference

## TDD Cycle for Godot: Investigate -> Plan -> Test -> Implement -> Validate -> Finalize

### Phase 1: Investigate

Before writing any code, understand the requirement:

```gdscript
# Questions to answer:
# 1. What is the expected behavior?
# 2. What signals should be emitted?
# 3. What state changes occur?
# 4. What are the edge cases?
# 5. What nodes/scenes are dependencies?

# Document findings as comments
## Feature: Player Health System
##
## Acceptance Criteria:
## - Health starts at max_health value
## - Taking damage reduces health
## - Health cannot go below 0
## - Signal emitted when health changes
## - Signal emitted when player dies
## - Invincibility frames after taking damage
```

### Phase 2: Plan

Design the interface before implementation:

```gdscript
# Interface planning - just the signatures
# HealthComponent:
#   - health: int (property)
#   - max_health: int (export)
#   - is_invincible: bool (property)
#   - take_damage(amount: int, source: Node = null) -> void
#   - heal(amount: int) -> void
#   - signal health_changed(new_health: int, max_health: int)
#   - signal damaged(amount: int, source: Node)
#   - signal died()
```

### Phase 3: Test (RED)

Write failing tests following AAA pattern:

```gdscript
# tests/unit/test_health_component.gd
extends GutTest

var _health_component: HealthComponent

func before_each() -> void:
    _health_component = HealthComponent.new()
    _health_component.max_health = 100
    add_child_autofree(_health_component)
    # Wait for _ready to complete
    await get_tree().process_frame

# Test name format: test_<behavior>_<condition>_<expected_result>
func test_initial_health_equals_max_health() -> void:
    # Arrange - setup done in before_each
    var expected := 100

    # Act - health is set in _ready
    var actual := _health_component.health

    # Assert
    assert_eq(actual, expected, "Initial health should equal max_health")

func test_take_damage_reduces_health_by_damage_amount() -> void:
    # Arrange
    var damage := 25
    var expected := 75

    # Act
    _health_component.take_damage(damage)

    # Assert
    assert_eq(_health_component.health, expected)

func test_take_damage_emits_health_changed_signal() -> void:
    # Arrange
    watch_signals(_health_component)

    # Act
    _health_component.take_damage(10)

    # Assert
    assert_signal_emitted(_health_component, "health_changed")
    assert_signal_emitted_with_parameters(
        _health_component,
        "health_changed",
        [90, 100]
    )

func test_take_damage_emits_damaged_signal_with_source() -> void:
    # Arrange
    watch_signals(_health_component)
    var attacker := Node.new()
    add_child_autofree(attacker)

    # Act
    _health_component.take_damage(10, attacker)

    # Assert
    assert_signal_emitted(_health_component, "damaged")

func test_health_cannot_go_below_zero() -> void:
    # Arrange
    var excessive_damage := 9999

    # Act
    _health_component.take_damage(excessive_damage)

    # Assert
    assert_eq(_health_component.health, 0, "Health should clamp at 0")

func test_died_signal_emitted_when_health_reaches_zero() -> void:
    # Arrange
    watch_signals(_health_component)

    # Act
    _health_component.take_damage(100)

    # Assert
    assert_signal_emitted(_health_component, "died")

func test_died_signal_emitted_only_once() -> void:
    # Arrange
    watch_signals(_health_component)
    _health_component.take_damage(100)

    # Act - try to damage again
    _health_component.take_damage(50)

    # Assert - should only have emitted once
    assert_signal_emit_count(_health_component, "died", 1)

func test_heal_increases_health() -> void:
    # Arrange
    _health_component.take_damage(50)

    # Act
    _health_component.heal(30)

    # Assert
    assert_eq(_health_component.health, 80)

func test_heal_cannot_exceed_max_health() -> void:
    # Arrange
    _health_component.take_damage(10)

    # Act
    _health_component.heal(100)

    # Assert
    assert_eq(_health_component.health, _health_component.max_health)

func test_heal_does_nothing_when_dead() -> void:
    # Arrange
    _health_component.take_damage(100)

    # Act
    _health_component.heal(50)

    # Assert
    assert_eq(_health_component.health, 0, "Cannot heal when dead")
```

### Phase 4: Implement (GREEN)

Write minimal code to pass each test:

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
    if actual_heal > 0:
        healed.emit(actual_heal)

func _start_invincibility() -> void:
    is_invincible = true
    await get_tree().create_timer(invincibility_duration).timeout
    is_invincible = false
```

### Phase 5: Validate

Run full test suite:

```bash
# Run all GUT tests
godot --headless -s addons/gut/gut_cmdln.gd

# Run with verbose output
godot --headless -s addons/gut/gut_cmdln.gd -glog=2

# Run specific test file
godot --headless -s addons/gut/gut_cmdln.gd \
    -gtest=res://tests/unit/test_health_component.gd
```

### Phase 6: Finalize (REFACTOR)

Refactor while keeping tests green. Run tests after each change.

---

## GUT Testing Patterns

### Testing Signals

```gdscript
func test_signal_emission() -> void:
    watch_signals(my_node)

    my_node.do_something()

    # Check if signal was emitted
    assert_signal_emitted(my_node, "something_happened")

    # Check emission count
    assert_signal_emit_count(my_node, "something_happened", 1)

    # Check signal parameters
    assert_signal_emitted_with_parameters(
        my_node,
        "something_happened",
        ["expected_param1", 42]
    )
```

### Testing Async Operations

```gdscript
func test_timer_completion() -> void:
    # Arrange
    var timer := Timer.new()
    timer.wait_time = 0.5
    timer.one_shot = true
    add_child_autofree(timer)
    watch_signals(timer)

    # Act
    timer.start()
    await wait_seconds(0.6)

    # Assert
    assert_signal_emitted(timer, "timeout")

func test_await_signal() -> void:
    # Arrange
    var animation_player := preload("res://scenes/test_anim.tscn").instantiate()
    add_child_autofree(animation_player)

    # Act
    animation_player.play("attack")
    await wait_for_signal(animation_player.animation_finished, 2.0)

    # Assert
    assert_true(true, "Animation completed")

func test_multiple_frames() -> void:
    # Wait for physics frames
    await wait_frames(5)

    # Or wait for specific time
    await wait_seconds(0.1)
```

### Testing with Doubles (Mocks)

```gdscript
func test_enemy_uses_navigation() -> void:
    # Create a double of NavigationAgent2D
    var mock_nav := double(NavigationAgent2D).new()

    # Stub method return value
    stub(mock_nav, "get_next_path_position").to_return(Vector2(100, 50))
    stub(mock_nav, "is_navigation_finished").to_return(false)

    # Create enemy with mocked navigation
    var enemy := Enemy.new()
    add_child_autofree(enemy)
    enemy.navigation_agent = mock_nav

    # Act
    enemy.update_movement()

    # Assert - verify mock was called
    assert_called(mock_nav, "get_next_path_position")
    assert_call_count(mock_nav, "get_next_path_position", 1)

func test_with_partial_double() -> void:
    # Partial double - keeps real implementation except stubbed methods
    var partial := partial_double(Enemy).new()

    # Only stub specific method
    stub(partial, "get_target_position").to_return(Vector2.ZERO)

    # Real methods still work
    partial.take_damage(10)
    assert_eq(partial.health, 90)
```

### Testing Scene Instantiation

```gdscript
const PlayerScene := preload("res://scenes/actors/player.tscn")

func test_player_scene_structure() -> void:
    # Arrange & Act
    var player := PlayerScene.instantiate()
    add_child_autofree(player)

    # Assert - verify scene structure
    assert_not_null(player.get_node_or_null("Sprite2D"))
    assert_not_null(player.get_node_or_null("CollisionShape2D"))
    assert_not_null(player.get_node_or_null("StateMachine"))

func test_player_initial_state() -> void:
    var player := PlayerScene.instantiate()
    add_child_autofree(player)
    await get_tree().process_frame

    assert_eq(player.state_machine.current_state.name, "Idle")
```

### Testing Physics

```gdscript
func test_character_moves_right() -> void:
    # Arrange
    var player := PlayerScene.instantiate()
    add_child_autofree(player)
    var initial_x := player.position.x

    # Simulate input
    Input.action_press("move_right")

    # Act - run physics frames
    await wait_frames(10)

    # Cleanup
    Input.action_release("move_right")

    # Assert
    assert_gt(player.position.x, initial_x, "Player should move right")

func test_collision_detection() -> void:
    # Arrange
    var player := PlayerScene.instantiate()
    var enemy := EnemyScene.instantiate()
    add_child_autofree(player)
    add_child_autofree(enemy)

    player.position = Vector2(100, 100)
    enemy.position = Vector2(100, 100)

    watch_signals(player.hurtbox)

    # Act - wait for physics
    await wait_frames(2)

    # Assert
    assert_signal_emitted(player.hurtbox, "hurt")
```

### Testing State Machines

```gdscript
func test_state_transition_idle_to_run() -> void:
    # Arrange
    var player := PlayerScene.instantiate()
    add_child_autofree(player)
    await get_tree().process_frame

    watch_signals(player.state_machine)

    # Act
    Input.action_press("move_right")
    await wait_frames(2)
    Input.action_release("move_right")

    # Assert
    assert_signal_emitted(player.state_machine, "state_changed")
    assert_eq(player.state_machine.current_state.name, "Run")

func test_jump_state_returns_to_idle() -> void:
    var player := PlayerScene.instantiate()
    add_child_autofree(player)

    # Put player on ground
    player.position = Vector2(100, 0)
    await wait_frames(2)

    # Jump
    player.state_machine.transition_to("jump")
    await wait_seconds(1.0)  # Wait for jump to complete

    assert_eq(player.state_machine.current_state.name, "Idle")
```

### Test Fixtures and Factories

```gdscript
# tests/fixtures/factories.gd
class_name TestFactories
extends RefCounted

static func create_player(overrides: Dictionary = {}) -> Player:
    var player := preload("res://scenes/actors/player.tscn").instantiate()

    # Apply overrides
    if overrides.has("health"):
        player.health_component.max_health = overrides.health
    if overrides.has("position"):
        player.position = overrides.position
    if overrides.has("speed"):
        player.move_speed = overrides.speed

    return player

static func create_enemy(type: String = "slime", overrides: Dictionary = {}) -> Enemy:
    var scene_path := "res://scenes/actors/enemies/%s.tscn" % type
    var enemy := load(scene_path).instantiate()

    if overrides.has("health"):
        enemy.health_component.max_health = overrides.health

    return enemy
```

Usage in tests:

```gdscript
func test_with_factory() -> void:
    var player := TestFactories.create_player({
        "health": 50,
        "position": Vector2(100, 100)
    })
    add_child_autofree(player)

    assert_eq(player.health_component.max_health, 50)
```

### Parameterized Tests (Table-Driven)

```gdscript
func test_damage_calculations() -> void:
    var test_cases := [
        {"damage": 10, "armor": 0, "expected": 10},
        {"damage": 10, "armor": 5, "expected": 5},
        {"damage": 10, "armor": 10, "expected": 1},  # Minimum 1 damage
        {"damage": 100, "armor": 50, "expected": 50},
    ]

    for tc in test_cases:
        # Arrange
        var actual := calculate_damage(tc.damage, tc.armor)

        # Assert
        assert_eq(
            actual,
            tc.expected,
            "Damage %d with armor %d should deal %d" % [tc.damage, tc.armor, tc.expected]
        )
```

### Testing Resources

```gdscript
func test_weapon_data_resource() -> void:
    # Arrange
    var weapon := WeaponData.new()
    weapon.weapon_name = "Sword"
    weapon.damage = 25
    weapon.attack_speed = 1.5

    # Act
    var dps := weapon.get_dps()

    # Assert
    assert_eq(dps, 37.5)

func test_load_weapon_resource() -> void:
    var weapon: WeaponData = load("res://resources/weapons/iron_sword.tres")

    assert_not_null(weapon)
    assert_eq(weapon.weapon_name, "Iron Sword")
    assert_gt(weapon.damage, 0)
```

---

## GUT Configuration

### .gutconfig.json

```json
{
    "dirs": [
        "res://tests/unit/",
        "res://tests/integration/"
    ],
    "prefix": "test_",
    "suffix": ".gd",
    "should_exit": true,
    "should_exit_on_success": true,
    "log_level": 2,
    "include_subdirs": true,
    "double_strategy": "partial",
    "junit_xml_file": "res://test_results.xml",
    "junit_xml_timestamp": true
}
```

### Running Tests

```bash
# All tests
godot --headless -s addons/gut/gut_cmdln.gd

# Specific directory
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/

# Specific file
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_player.gd

# Tests matching pattern
godot --headless -s addons/gut/gut_cmdln.gd -ginner_class=TestHealth

# Generate JUnit XML for CI
godot --headless -s addons/gut/gut_cmdln.gd -gjunit_xml_file=results.xml
```

---

## Integration Testing

### Testing Scene Loading

```gdscript
# tests/integration/test_level_loading.gd
extends GutTest

func test_level_loads_without_errors() -> void:
    var level := load("res://scenes/levels/level_01.tscn").instantiate()
    add_child_autofree(level)
    await get_tree().process_frame

    assert_not_null(level.get_node_or_null("Player"))
    assert_not_null(level.get_node_or_null("Enemies"))

func test_player_spawns_at_spawn_point() -> void:
    var level := load("res://scenes/levels/level_01.tscn").instantiate()
    add_child_autofree(level)
    await get_tree().process_frame

    var player := level.get_node("Player")
    var spawn := level.get_node("SpawnPoint")

    assert_eq(player.global_position, spawn.global_position)
```

### Testing Save/Load

```gdscript
func test_save_and_load_game_state() -> void:
    # Arrange
    var save_data := {
        "player_health": 75,
        "player_position": {"x": 100, "y": 200},
        "coins": 42
    }

    # Act - Save
    SaveManager.save_game(save_data, "test_save")

    # Act - Load
    var loaded := SaveManager.load_game("test_save")

    # Assert
    assert_eq(loaded.player_health, 75)
    assert_eq(loaded.coins, 42)

    # Cleanup
    DirAccess.remove_absolute(SaveManager.get_save_path("test_save"))
```
