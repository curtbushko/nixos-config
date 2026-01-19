# Godot Scene Architecture Reference

## Scene Composition Principles

### Favor Composition Over Inheritance

Instead of deep inheritance hierarchies, compose scenes from smaller, reusable parts.

```
# BAD - Deep inheritance
Entity
└── Character
    └── Enemy
        └── FlyingEnemy
            └── Dragon

# GOOD - Composition
Dragon (CharacterBody2D)
├── HealthComponent
├── MovementComponent (configured for flying)
├── AIComponent (dragon behavior)
├── HitboxComponent
└── HurtboxComponent
```

### Single Responsibility Scenes

Each scene should do one thing well:

```
# BAD - Monolithic player scene
Player.tscn
└── Player.gd (handles movement, combat, inventory, UI, saving...)

# GOOD - Composed player scene
Player.tscn
├── CharacterBody2D (root with minimal script)
├── MovementController (handles movement only)
├── CombatController (handles combat only)
├── Components/
│   ├── HealthComponent
│   ├── HitboxComponent
│   ├── HurtboxComponent
│   └── InventoryComponent
└── StateMachine/
    ├── IdleState
    ├── RunState
    └── AttackState
```

---

## Scene Organization Patterns

### Actor Scene Structure

For characters, enemies, and interactive entities:

```
Actor (CharacterBody2D / RigidBody2D)
├── Visuals
│   ├── Sprite2D / AnimatedSprite2D
│   ├── ShadowSprite (optional)
│   └── EffectsContainer
├── Collision
│   └── CollisionShape2D
├── Components
│   ├── HealthComponent
│   ├── HitboxComponent
│   └── HurtboxComponent
├── StateMachine
│   ├── IdleState
│   ├── MoveState
│   └── ...
├── Audio
│   └── AudioStreamPlayer2D
└── UI (optional)
    └── HealthBar
```

### Level Scene Structure

```
Level (Node2D)
├── Environment
│   ├── Background (ParallaxBackground)
│   ├── TileMap
│   └── Decorations
├── Navigation
│   └── NavigationRegion2D
├── Entities
│   ├── Player
│   ├── Enemies
│   │   └── (spawned enemies)
│   └── NPCs
├── Interactables
│   ├── Doors
│   ├── Chests
│   └── Switches
├── Triggers
│   ├── CameraZones
│   ├── SpawnTriggers
│   └── EventTriggers
├── SpawnPoints
│   ├── PlayerSpawn
│   └── EnemySpawns
└── UI
    └── LevelUI
```

### UI Scene Structure

```
GameUI (CanvasLayer)
├── HUD
│   ├── HealthBar
│   ├── ManaBar
│   ├── CoinCounter
│   └── Minimap
├── Menus
│   ├── PauseMenu
│   ├── InventoryMenu
│   └── SettingsMenu
├── Overlays
│   ├── DamageNumbers
│   ├── Notifications
│   └── DialogBox
└── Transitions
    └── ScreenFade
```

---

## Scene Communication Patterns

### Parent-Child Communication

Children should not directly call parent methods. Use signals instead.

```gdscript
# BAD - Child calls parent
class_name HealthComponent extends Node

func take_damage(amount: int) -> void:
    health -= amount
    get_parent().on_damaged(amount)  # Tight coupling

# GOOD - Child emits signal
class_name HealthComponent extends Node

signal damaged(amount: int)

func take_damage(amount: int) -> void:
    health -= amount
    damaged.emit(amount)  # Parent connects to this
```

### Sibling Communication

Siblings should not know about each other directly. Use parent as mediator or signals.

```gdscript
# Parent mediates between siblings
# player.gd (parent script)
func _ready() -> void:
    $HealthComponent.died.connect(_on_health_died)

func _on_health_died() -> void:
    $StateMachine.transition_to("dead")
    $MovementController.enabled = false
```

### Cross-Scene Communication

Use an autoload Events bus for decoupled communication:

```gdscript
# autoloads/events.gd
extends Node

# Player events
signal player_spawned(player: Node)
signal player_died
signal player_health_changed(current: int, maximum: int)

# Game state events
signal game_paused
signal game_resumed
signal level_completed(level_name: String)

# Combat events
signal enemy_killed(enemy: Node, killer: Node)
signal damage_dealt(amount: int, position: Vector2)
```

```gdscript
# In player.gd
func _ready() -> void:
    Events.player_spawned.emit(self)

func die() -> void:
    Events.player_died.emit()
```

```gdscript
# In ui/health_bar.gd (completely decoupled)
func _ready() -> void:
    Events.player_health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(current: int, maximum: int) -> void:
    value = float(current) / float(maximum) * 100
```

---

## Scene Inheritance

### When to Use Scene Inheritance

- Multiple enemies with same base structure but different behaviors
- UI elements with common layout but different content
- Variations of the same object (different colored gems, etc.)

### How to Set Up Scene Inheritance

1. Create base scene: `enemy_base.tscn`
2. Create inherited scene: Scene -> New Inherited Scene -> Select base
3. Override only what differs

```
# enemy_base.tscn (base)
Enemy (CharacterBody2D)
├── Sprite2D (placeholder)
├── CollisionShape2D
├── HealthComponent
├── HurtboxComponent
└── StateMachine
    ├── IdleState
    └── ChaseState

# slime.tscn (inherits enemy_base.tscn)
# - Override Sprite2D texture
# - Set HealthComponent.max_health = 20
# - Add SlimeState to StateMachine

# skeleton.tscn (inherits enemy_base.tscn)
# - Override Sprite2D texture
# - Set HealthComponent.max_health = 50
# - Add PatrolState, AttackState to StateMachine
```

### Overriding in Inherited Scenes

```gdscript
# enemy_base.gd
class_name EnemyBase extends CharacterBody2D

@export var move_speed: float = 100.0

func get_target() -> Node2D:
    # Default implementation
    return get_tree().get_first_node_in_group("player")

func attack() -> void:
    # Override in subclass
    pass
```

```gdscript
# slime.gd (extends EnemyBase)
extends EnemyBase

func _ready() -> void:
    move_speed = 50.0  # Slimes are slower

func attack() -> void:
    # Slime-specific attack
    $HitboxComponent.activate()
```

---

## Node References Best Practices

### Use @export for External References

```gdscript
# For nodes that should be assigned in editor
@export var target: Node2D
@export var health_component: HealthComponent
@export var animation_player: AnimationPlayer
```

### Use @onready for Internal References

```gdscript
# For child nodes within the same scene
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var state_machine: StateMachine = $StateMachine
```

### Use get_node_or_null for Optional Nodes

```gdscript
func _ready() -> void:
    var optional_component := get_node_or_null("OptionalComponent")
    if optional_component:
        optional_component.setup()
```

### Use Groups for Finding Nodes

```gdscript
# Add player to "player" group in editor or code
func _ready() -> void:
    add_to_group("player")

# Find player from anywhere
var player := get_tree().get_first_node_in_group("player")

# Find all enemies
var enemies := get_tree().get_nodes_in_group("enemies")
```

### Avoid String Paths Across Scenes

```gdscript
# BAD - Fragile, breaks if structure changes
var player = get_node("/root/Main/World/Entities/Player")

# GOOD - Use groups
var player = get_tree().get_first_node_in_group("player")

# GOOD - Use exported reference
@export var player: Player

# GOOD - Use events/signals
Events.player_spawned.connect(func(p): player = p)
```

---

## Scene Instancing Patterns

### Preloading Scenes

```gdscript
# Preload for frequently used scenes
const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
const ExplosionScene := preload("res://scenes/effects/explosion.tscn")

func shoot() -> void:
    var bullet := BulletScene.instantiate()
    bullet.position = muzzle_position
    get_parent().add_child(bullet)
```

### Dynamic Loading

```gdscript
# Load scenes that aren't always needed
func load_level(level_name: String) -> void:
    var path := "res://scenes/levels/%s.tscn" % level_name
    var scene := load(path)
    if scene:
        var level := scene.instantiate()
        add_child(level)
```

### Deferred Scene Addition

```gdscript
# Add scenes at safe time in frame
func spawn_enemy() -> void:
    var enemy := EnemyScene.instantiate()
    enemy.position = spawn_point.position
    call_deferred("add_child", enemy)
```

---

## Scene Lifecycle Management

### Proper Cleanup

```gdscript
func _exit_tree() -> void:
    # Disconnect signals
    if Events.player_died.is_connected(_on_player_died):
        Events.player_died.disconnect(_on_player_died)

    # Clean up resources
    if _timer and _timer.is_connected("timeout", _on_timeout):
        _timer.stop()
```

### Queue Free vs Free

```gdscript
# GOOD - Safe, waits for current frame to finish
enemy.queue_free()

# CAUTION - Immediate, can cause issues mid-frame
enemy.free()  # Only use when you know it's safe
```

### Check Instance Validity

```gdscript
func _process(_delta: float) -> void:
    # Target might have been freed
    if is_instance_valid(target):
        look_at(target.global_position)
```

---

## Scene Tree Best Practices

### Use Unique Names for Important Nodes

In editor, right-click node -> Access as Unique Name

```gdscript
# Access unique nodes with %
@onready var player := %Player
@onready var ui := %GameUI
```

### ProcessMode for Pause Handling

```gdscript
# In _ready or set in editor
func _ready() -> void:
    # Always process (for pause menu)
    process_mode = Node.PROCESS_MODE_ALWAYS

    # Only when not paused (default)
    process_mode = Node.PROCESS_MODE_PAUSABLE

    # Only when paused
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
```

### Visibility and Processing

```gdscript
# Disable processing when off-screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    set_process(false)
    set_physics_process(false)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
    set_process(true)
    set_physics_process(true)
```

---

## Anti-Patterns to Avoid

### God Scenes
A single scene that does everything. Break it up into composed scenes.

### Circular Dependencies
Scene A requires Scene B which requires Scene A. Use events/signals instead.

### Hardcoded Node Paths
Using `/root/Game/World/Player` - use groups or exported references.

### Direct Child Manipulation
`enemy.get_node("HealthBar").visible = false` - let nodes manage their own children.

### Unnamed Magic Nodes
Using generic names like `Node2D`, `Control` - use descriptive names.
