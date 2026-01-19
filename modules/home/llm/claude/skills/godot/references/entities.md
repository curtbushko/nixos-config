# Godot Entity Patterns Reference

## Understanding Entities in Godot

In Godot, an "entity" typically refers to any game object that exists in the world: players, enemies, NPCs, items, projectiles, etc. Unlike traditional ECS engines, Godot uses a node-based architecture where entities are composed of nodes in a tree structure.

**Key insight**: Godot's node system already provides composition. You don't need a full ECS framework for most games. Use patterns selectively where they solve real problems.

---

## When to Use Entity Patterns

### Use Simple Inheritance When

- Entity types are distinct and don't share much behavior
- You have fewer than 3-4 entity variations
- Inheritance hierarchy is shallow (2-3 levels max)

```gdscript
# Simple inheritance is fine for basic cases
class_name Enemy extends CharacterBody2D

func take_damage(amount: int) -> void:
    health -= amount
```

### Use Component Pattern When

- Multiple entity types share behaviors in different combinations
- An entity could be multiple "types" simultaneously (e.g., a battery that's both power source AND receiver)
- You need to add/remove behaviors at runtime
- Inheritance would create diamond problems or deep hierarchies

```
# Problem: Diamond inheritance
Entity
├── PowerSource
├── PowerReceiver
└── Battery (needs both??)

# Solution: Composition
Battery (Entity)
├── PowerSourceComponent
└── PowerReceiverComponent
```

### Use Full ECS When

- You have hundreds/thousands of similar entities
- Performance is critical (bullet hell, large simulations)
- You need data-oriented design for cache efficiency

---

## Godot-Native Entity Composition

### Basic Entity Structure

```gdscript
# scenes/actors/enemy.tscn structure
Enemy (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── Components
│   ├── HealthComponent
│   ├── HurtboxComponent
│   └── MovementComponent
└── StateMachine
    ├── IdleState
    ├── ChaseState
    └── AttackState
```

### Component as Child Node

Components are nodes that provide specific functionality:

```gdscript
# scripts/components/health_component.gd
class_name HealthComponent
extends Node

signal health_changed(current: int, maximum: int)
signal died

@export var max_health: int = 100

var health: int:
    set(value):
        var old := health
        health = clampi(value, 0, max_health)
        if health != old:
            health_changed.emit(health, max_health)
        if health <= 0 and old > 0:
            died.emit()

func _ready() -> void:
    health = max_health

func take_damage(amount: int) -> void:
    health -= amount

func heal(amount: int) -> void:
    health = mini(health + amount, max_health)
```

### Entity Uses Components via Signals

The entity (parent) connects to component signals rather than calling component methods directly:

```gdscript
# scripts/actors/enemy.gd
class_name Enemy
extends CharacterBody2D

@onready var health_component: HealthComponent = $Components/HealthComponent
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
    health_component.died.connect(_on_died)
    health_component.health_changed.connect(_on_health_changed)

func _on_died() -> void:
    state_machine.transition_to("dead")
    # Or: queue_free()

func _on_health_changed(current: int, maximum: int) -> void:
    # Update health bar, play hurt animation, etc.
    pass
```

---

## Component Design Principles

### 1. Components Are "Blind" to Context

Components should not know what entity they belong to or how they're used:

```gdscript
# BAD - Component knows about parent
class_name HealthComponent extends Node

func take_damage(amount: int) -> void:
    health -= amount
    get_parent().play_hurt_animation()  # Tight coupling!
    get_parent().flash_sprite()         # Assumes parent has these methods

# GOOD - Component emits signals, parent handles specifics
class_name HealthComponent extends Node

signal damaged(amount: int)

func take_damage(amount: int) -> void:
    health -= amount
    damaged.emit(amount)  # Parent decides what to do
```

### 2. Components Are Configurable

Use exports so the same component works for different entities:

```gdscript
class_name MovementComponent
extends Node

@export var move_speed: float = 100.0
@export var acceleration: float = 500.0
@export var friction: float = 400.0
@export var can_fly: bool = false

# Same component for player (fast), slime (slow), bat (flying)
```

### 3. Single Responsibility

Each component handles one concern:

```gdscript
# BAD - Component does too much
class_name CombatComponent extends Node
# Handles health, damage, weapons, abilities, buffs...

# GOOD - Separate components
HealthComponent      # Just health/damage
WeaponComponent      # Just weapon logic
AbilityComponent     # Just abilities
BuffComponent        # Just status effects
```

### 4. Minimal Dependencies

Components should work independently when possible:

```gdscript
# BAD - Component requires other components
class_name AttackComponent extends Node

func attack() -> void:
    var health := get_parent().get_node("HealthComponent")  # Assumes it exists
    var weapon := get_parent().get_node("WeaponComponent")  # Assumes it exists

# GOOD - Use optional references
class_name AttackComponent extends Node

@export var weapon_component: WeaponComponent  # Optional, assigned in editor

func attack() -> void:
    if weapon_component:
        weapon_component.use()
```

---

## Systems for Component Management

When multiple components need coordinated updates, use a System:

### System Pattern

```gdscript
# scripts/systems/power_system.gd
class_name PowerSystem
extends Node

func _physics_process(delta: float) -> void:
    var sources := get_tree().get_nodes_in_group("power_sources")
    var receivers := get_tree().get_nodes_in_group("power_receivers")

    # Calculate total power available
    var total_power := 0.0
    for source in sources:
        total_power += source.power_output

    # Distribute power to receivers
    for receiver in receivers:
        var allocated := minf(receiver.power_required, total_power)
        receiver.receive_power(allocated, delta)
        total_power -= allocated
```

### Component Registers with Group

```gdscript
# scripts/components/power_source_component.gd
class_name PowerSourceComponent
extends Node

@export var power_output: float = 10.0

func _ready() -> void:
    add_to_group("power_sources")

func _exit_tree() -> void:
    remove_from_group("power_sources")
```

### When to Use Systems

- Multiple components need synchronized updates
- Components interact with each other indirectly
- You want centralized logic for a game mechanic

---

## Entity Factory Pattern

For spawning entities with varying configurations:

```gdscript
# scripts/factories/enemy_factory.gd
class_name EnemyFactory
extends RefCounted

const EnemyScene := preload("res://scenes/actors/enemy.tscn")

static func create_enemy(type: String, position: Vector2) -> Enemy:
    var enemy := EnemyScene.instantiate()
    enemy.position = position

    match type:
        "slime":
            _configure_slime(enemy)
        "skeleton":
            _configure_skeleton(enemy)
        "boss":
            _configure_boss(enemy)

    return enemy

static func _configure_slime(enemy: Enemy) -> void:
    enemy.health_component.max_health = 20
    enemy.movement_component.move_speed = 50.0
    enemy.get_node("Sprite2D").texture = preload("res://assets/slime.png")

static func _configure_skeleton(enemy: Enemy) -> void:
    enemy.health_component.max_health = 50
    enemy.movement_component.move_speed = 80.0
    enemy.get_node("Sprite2D").texture = preload("res://assets/skeleton.png")
```

Usage:

```gdscript
func spawn_enemy() -> void:
    var enemy := EnemyFactory.create_enemy("slime", spawn_point.position)
    add_child(enemy)
```

---

## Data-Driven Entities with Resources

Use Resources to define entity data separately from logic:

```gdscript
# scripts/resources/enemy_data.gd
class_name EnemyData
extends Resource

@export var enemy_name: String
@export var max_health: int = 100
@export var move_speed: float = 100.0
@export var damage: int = 10
@export var sprite: Texture2D
@export var drop_table: Array[ItemDrop]

# Create .tres files for each enemy type
```

```gdscript
# scripts/actors/enemy.gd
class_name Enemy
extends CharacterBody2D

@export var data: EnemyData

func _ready() -> void:
    if data:
        $HealthComponent.max_health = data.max_health
        $MovementComponent.move_speed = data.move_speed
        $Sprite2D.texture = data.sprite
```

Benefits:
- Designers can create enemies without coding
- Easy to balance (just edit .tres files)
- Supports localization and variants

---

## Entity Lifecycle Management

### Spawning

```gdscript
func spawn_entity(scene: PackedScene, pos: Vector2) -> Node:
    var entity := scene.instantiate()
    entity.position = pos

    # Use call_deferred for physics-safe spawning
    call_deferred("add_child", entity)

    return entity
```

### Despawning

```gdscript
func despawn_entity(entity: Node) -> void:
    # Emit signal before removal for cleanup
    if entity.has_signal("despawning"):
        entity.despawning.emit()

    entity.queue_free()
```

### Object Pooling (When Needed)

Only use for frequently spawned/despawned entities (bullets, particles):

```gdscript
class_name EntityPool
extends Node

var _pool: Array[Node] = []
var _active: Array[Node] = []
var _scene: PackedScene

func _init(scene: PackedScene, initial_size: int = 20) -> void:
    _scene = scene
    for i in initial_size:
        var entity := _scene.instantiate()
        entity.set_process(false)
        entity.visible = false
        _pool.append(entity)

func acquire() -> Node:
    var entity: Node
    if _pool.is_empty():
        entity = _scene.instantiate()
    else:
        entity = _pool.pop_back()

    entity.set_process(true)
    entity.visible = true
    _active.append(entity)

    if entity.has_method("on_spawn"):
        entity.on_spawn()

    return entity

func release(entity: Node) -> void:
    if entity.has_method("on_despawn"):
        entity.on_despawn()

    entity.set_process(false)
    entity.visible = false
    _active.erase(entity)
    _pool.append(entity)
```

---

## Common Entity Types

### Player Entity

```
Player (CharacterBody2D)
├── Visuals
│   ├── Sprite2D
│   └── AnimationPlayer
├── Collision
│   └── CollisionShape2D
├── Components
│   ├── HealthComponent
│   ├── StaminaComponent
│   ├── HurtboxComponent
│   ├── HitboxComponent
│   └── InventoryComponent
├── StateMachine
│   ├── IdleState
│   ├── RunState
│   ├── JumpState
│   └── AttackState
├── Camera2D
└── UI
    └── PlayerHUD
```

### Enemy Entity

```
Enemy (CharacterBody2D)
├── Visuals
│   ├── Sprite2D
│   └── AnimationPlayer
├── Collision
│   └── CollisionShape2D
├── Components
│   ├── HealthComponent
│   ├── HurtboxComponent
│   ├── HitboxComponent
│   └── LootComponent
├── AI
│   ├── NavigationAgent2D
│   └── StateMachine
│       ├── IdleState
│       ├── PatrolState
│       ├── ChaseState
│       └── AttackState
└── Detection
    └── Area2D (aggro range)
```

### Interactable Entity

```
Chest (StaticBody2D)
├── Sprite2D
├── CollisionShape2D
├── InteractionArea (Area2D)
├── AnimationPlayer
└── InteractableComponent
```

---

## Anti-Patterns to Avoid

### God Entity
An entity script that handles everything directly:

```gdscript
# BAD - Player.gd handles everything
func _physics_process(delta):
    handle_movement()
    handle_combat()
    handle_inventory()
    handle_dialogue()
    handle_quests()
    # 2000 lines of code...
```

### Unnecessary Abstraction
Don't use patterns when simple code works:

```gdscript
# BAD - Overengineered for a simple chest
ChestEntityComponentSystemManagerFactory.create_chest_entity()

# GOOD - Just a simple script
func open() -> void:
    if not is_open:
        is_open = true
        $AnimationPlayer.play("open")
        spawn_loot()
```

### Component Soup
Too many tiny components that are hard to manage:

```gdscript
# BAD - Every tiny feature is a component
PositionComponent
VelocityComponent
AccelerationComponent
FrictionComponent
GravityComponent
# Just use one MovementComponent!
```

---

## Sources and Further Reading

- [GDQuest: Entity-Component Pattern](https://www.gdquest.com/tutorial/godot/design-patterns/entity-component-pattern/)
- [GDQuest: Design Patterns in Godot](https://www.gdquest.com/tutorial/godot/design-patterns/intro-to-design-patterns/)
- [GDQuest: Design Patterns GitHub](https://github.com/gdquest-demos/godot-design-patterns)
- [Why Godot Isn't ECS-Based](https://godotengine.org/article/why-isnt-godot-ecs-based-game-engine/)
- [GECS - Godot Entity Component System](https://github.com/csprance/gecs) (for full ECS needs)
- [Game Development Patterns with Godot 4](https://github.com/PacktPublishing/Game-Development-Patterns-with-Godot-4) (Packt book)
