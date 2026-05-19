# Godot Performance Optimization Reference

## General Principles

1. **Measure First**: Profile before optimizing. Use Godot's built-in profiler.
2. **Optimize Hot Paths**: Focus on code that runs every frame.
3. **Avoid Premature Optimization**: Get it working first, then optimize bottlenecks.
4. **Test on Target Hardware**: Performance varies significantly across devices.

---

## Profiling Tools

### Built-in Profiler

```gdscript
# Enable profiler in Editor: Debugger -> Profiler tab
# Or programmatically:
func _ready() -> void:
    # Print performance metrics
    print("FPS: ", Engine.get_frames_per_second())

func _process(_delta: float) -> void:
    # Monitor specific metrics
    var render_time := Performance.get_monitor(Performance.TIME_PROCESS)
    var physics_time := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
```

### Custom Profiling

```gdscript
func expensive_operation() -> void:
    var start := Time.get_ticks_usec()

    # ... operation to measure ...

    var elapsed := Time.get_ticks_usec() - start
    print("Operation took: %d microseconds" % elapsed)
```

---

## CPU Optimization

### Cache Node References

```gdscript
# BAD - Gets node every frame
func _process(_delta: float) -> void:
    var sprite := $Sprite2D
    sprite.rotation += 0.1

# GOOD - Cache reference once
var _sprite: Sprite2D

func _ready() -> void:
    _sprite = $Sprite2D

func _process(delta: float) -> void:
    _sprite.rotation += delta
```

### Avoid Per-Frame Allocations

```gdscript
# BAD - Creates new array every frame
func _process(_delta: float) -> void:
    var nearby := []
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if position.distance_to(enemy.position) < 100:
            nearby.append(enemy)

# GOOD - Reuse array
var _nearby_enemies: Array[Enemy] = []

func _process(_delta: float) -> void:
    _nearby_enemies.clear()
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if position.distance_to(enemy.position) < 100:
            _nearby_enemies.append(enemy)
```

### Use Static Typing

```gdscript
# BAD - Dynamic typing, slower
func calculate(a, b):
    return a + b

# GOOD - Static typing, faster
func calculate(a: float, b: float) -> float:
    return a + b
```

### Avoid String Operations in Hot Paths

```gdscript
# BAD - String concatenation every frame
func _process(_delta: float) -> void:
    $Label.text = "Health: " + str(health) + "/" + str(max_health)

# GOOD - Use format strings or update only when changed
func _on_health_changed(new_health: int, new_max: int) -> void:
    $Label.text = "Health: %d/%d" % [new_health, new_max]
```

### Reduce Method Calls

```gdscript
# BAD - Multiple method calls
func _process(_delta: float) -> void:
    var dist := position.distance_to(target.position)
    if dist < range:
        attack()

# GOOD - Use squared distance (avoids sqrt)
func _process(_delta: float) -> void:
    var dist_sq := position.distance_squared_to(target.position)
    if dist_sq < range_squared:
        attack()
```

---

## Physics Optimization

### Use Appropriate Physics Bodies

| Type | Use Case | Performance |
|------|----------|-------------|
| StaticBody | Walls, floors (never moves) | Best |
| CharacterBody | Player, enemies (controlled movement) | Good |
| RigidBody | Physics-driven objects | Moderate |
| Area | Triggers, detection only | Best |

### Collision Layers and Masks

Configure layers to minimize unnecessary collision checks:

```gdscript
# Set up layers in Project Settings:
# Layer 1: Player
# Layer 2: Enemies
# Layer 3: Projectiles
# Layer 4: Environment

# Player only collides with enemies and environment
# Mask: 2, 4 (binary: 1010)

# Projectiles only collide with enemies
# Mask: 2 (binary: 0010)
```

### Disable Physics When Not Needed

```gdscript
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
    set_physics_process(false)
    $CollisionShape2D.set_deferred("disabled", true)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
    set_physics_process(true)
    $CollisionShape2D.set_deferred("disabled", false)
```

### Use Simple Collision Shapes

Performance order (fastest to slowest):
1. Circle/Sphere
2. Rectangle/Box
3. Capsule
4. Convex polygon
5. Concave polygon (avoid for moving objects)

```gdscript
# BAD - Complex collision for simple enemy
# Using detailed polygon matching sprite outline

# GOOD - Simple collision shape
# Using circle or capsule that roughly fits
```

### Physics Interpolation

For smooth movement at lower physics tick rates:

```gdscript
# In Project Settings:
# Physics -> Common -> Physics Ticks Per Second: 30 (lower = better perf)
# Physics -> Common -> Physics Jitter Fix: 0.5

# Enable interpolation on moving bodies
func _ready() -> void:
    # Godot 4.3+
    physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_ON
```

---

## Rendering Optimization

### Reduce Draw Calls

```gdscript
# BAD - Many individual sprites
for i in 100:
    var sprite := Sprite2D.new()
    add_child(sprite)

# GOOD - Use MultiMeshInstance2D for many identical sprites
var multi_mesh := MultiMeshInstance2D.new()
multi_mesh.multimesh = MultiMesh.new()
multi_mesh.multimesh.mesh = quad_mesh
multi_mesh.multimesh.instance_count = 100
```

### Visibility Culling

```gdscript
# Add VisibleOnScreenNotifier2D to objects
func _ready() -> void:
    var notifier := $VisibleOnScreenNotifier2D
    notifier.screen_entered.connect(_on_screen_entered)
    notifier.screen_exited.connect(_on_screen_exited)

func _on_screen_exited() -> void:
    visible = false
    set_process(false)
```

### Texture Optimization

- Use texture atlases for related sprites
- Use appropriate texture sizes (power of 2)
- Enable mipmaps for 3D or scaled 2D
- Use compressed textures for large images

```gdscript
# Import settings in .import file or reimport dialog:
# - Compress Mode: Lossy for large textures
# - Filter: Nearest for pixel art, Linear for smooth
# - Mipmaps: Enable for 3D
```

### Particle Optimization

```gdscript
# GPUParticles2D is faster than CPUParticles2D for many particles
# But CPUParticles2D works better on low-end devices

# Reduce particle count
particles.amount = 50  # Not 1000

# Use simple particle materials
# Avoid collision with particles
particles.collision_base_size = 0
```

### Shader Optimization

```glsl
// BAD - Complex per-pixel calculation
void fragment() {
    float dist = distance(UV, vec2(0.5));
    // Complex math every pixel
}

// GOOD - Precompute in vertex shader when possible
varying float v_dist;

void vertex() {
    v_dist = distance(UV, vec2(0.5));
}

void fragment() {
    // Use precomputed value
    COLOR.a = v_dist;
}
```

---

## Memory Optimization

### Resource Management

```gdscript
# Preload frequently used resources
const BulletScene := preload("res://scenes/bullet.tscn")

# Load on demand for rarely used resources
func show_credits() -> void:
    var credits := load("res://scenes/credits.tscn")

# Unload when done
func _on_level_completed() -> void:
    # Clear references to allow garbage collection
    current_level.queue_free()
    current_level = null
```

### Object Pooling

Reuse objects instead of creating/destroying:

```gdscript
class_name BulletPool extends Node

var _pool: Array[Bullet] = []
var _active: Array[Bullet] = []

const INITIAL_SIZE := 50
const BulletScene := preload("res://scenes/bullet.tscn")

func _ready() -> void:
    for i in INITIAL_SIZE:
        var bullet := BulletScene.instantiate()
        bullet.set_process(false)
        bullet.visible = false
        add_child(bullet)
        _pool.append(bullet)

func get_bullet() -> Bullet:
    var bullet: Bullet
    if _pool.is_empty():
        bullet = BulletScene.instantiate()
        add_child(bullet)
    else:
        bullet = _pool.pop_back()

    bullet.set_process(true)
    bullet.visible = true
    _active.append(bullet)
    return bullet

func return_bullet(bullet: Bullet) -> void:
    bullet.set_process(false)
    bullet.visible = false
    _active.erase(bullet)
    _pool.append(bullet)
```

### Avoid Memory Leaks

```gdscript
# Always disconnect signals when removing nodes
func _exit_tree() -> void:
    if target and target.died.is_connected(_on_target_died):
        target.died.disconnect(_on_target_died)

# Check validity before accessing freed nodes
if is_instance_valid(target):
    target.take_damage(10)
```

---

## Scene Loading Optimization

### Background Loading

```gdscript
var _loader: ResourceInteractiveLoader
var _loading_progress: float = 0.0

func load_level_async(path: String) -> void:
    _loader = ResourceLoader.load_threaded_request(path)

func _process(_delta: float) -> void:
    if _loader:
        var progress := []
        var status := ResourceLoader.load_threaded_get_status(path, progress)

        match status:
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                _loading_progress = progress[0]
                update_loading_bar(_loading_progress)
            ResourceLoader.THREAD_LOAD_LOADED:
                var scene := ResourceLoader.load_threaded_get(path)
                _on_level_loaded(scene)
                _loader = null
            ResourceLoader.THREAD_LOAD_FAILED:
                push_error("Failed to load level")
                _loader = null
```

### Scene Streaming

For large levels, load/unload chunks:

```gdscript
var _loaded_chunks: Dictionary = {}
const CHUNK_SIZE := 1024.0
const LOAD_DISTANCE := 2  # Load chunks within 2 chunks of player

func _process(_delta: float) -> void:
    var player_chunk := get_player_chunk()
    _update_chunks(player_chunk)

func get_player_chunk() -> Vector2i:
    return Vector2i(
        int(player.position.x / CHUNK_SIZE),
        int(player.position.y / CHUNK_SIZE)
    )

func _update_chunks(center: Vector2i) -> void:
    # Load nearby chunks
    for x in range(-LOAD_DISTANCE, LOAD_DISTANCE + 1):
        for y in range(-LOAD_DISTANCE, LOAD_DISTANCE + 1):
            var chunk_pos := center + Vector2i(x, y)
            if not _loaded_chunks.has(chunk_pos):
                _load_chunk(chunk_pos)

    # Unload distant chunks
    for chunk_pos in _loaded_chunks.keys():
        if center.distance_to(chunk_pos) > LOAD_DISTANCE + 1:
            _unload_chunk(chunk_pos)
```

---

## GDScript Specific Optimizations

### Use Built-in Methods

```gdscript
# BAD - Manual implementation
func find_nearest(position: Vector2, targets: Array) -> Node2D:
    var nearest: Node2D = null
    var min_dist := INF
    for target in targets:
        var dist := position.distance_to(target.position)
        if dist < min_dist:
            min_dist = dist
            nearest = target
    return nearest

# GOOD - Use built-in when possible
# (Note: This specific case still needs manual, but principle applies)
# Arrays have built-in filter, map, reduce
var filtered := array.filter(func(x): return x > 10)
```

### Avoid Deep Nesting

```gdscript
# BAD - Deep nesting, hard to optimize
func _process(_delta: float) -> void:
    for enemy in enemies:
        if enemy.is_alive:
            if enemy.can_attack:
                if enemy.target:
                    if enemy.in_range(enemy.target):
                        enemy.attack()

# GOOD - Early returns, cleaner
func _process(_delta: float) -> void:
    for enemy in enemies:
        _try_enemy_attack(enemy)

func _try_enemy_attack(enemy: Enemy) -> void:
    if not enemy.is_alive:
        return
    if not enemy.can_attack:
        return
    if not enemy.target:
        return
    if not enemy.in_range(enemy.target):
        return
    enemy.attack()
```

### Use match Instead of Multiple if-elif

```gdscript
# GOOD - match is optimized
func get_damage_multiplier(element: String) -> float:
    match element:
        "fire":
            return 1.5
        "ice":
            return 0.5
        "lightning":
            return 2.0
        _:
            return 1.0
```

---

## Mobile/Low-End Optimization

### Reduce Visual Quality

```gdscript
func apply_low_quality_settings() -> void:
    # Disable shadows
    RenderingServer.directional_soft_shadow_filter_set_quality(
        RenderingServer.SHADOW_QUALITY_HARD
    )

    # Reduce particle count
    for particles in get_tree().get_nodes_in_group("particles"):
        particles.amount = particles.amount / 2

    # Disable anti-aliasing
    get_viewport().msaa_2d = Viewport.MSAA_DISABLED
```

### Simplify Physics

```gdscript
func apply_mobile_physics() -> void:
    # Reduce physics tick rate
    Engine.physics_ticks_per_second = 30

    # Simplify collision shapes
    # Use circles instead of polygons
```

### Batch Similar Operations

```gdscript
# BAD - Process each enemy individually
func _process(_delta: float) -> void:
    for enemy in enemies:
        enemy.update_ai()
        enemy.update_animation()
        enemy.update_pathfinding()

# GOOD - Batch by operation type (better cache usage)
func _process(_delta: float) -> void:
    # Update all AI first
    for enemy in enemies:
        enemy.update_ai()
    # Then all animations
    for enemy in enemies:
        enemy.update_animation()
    # Then all pathfinding
    for enemy in enemies:
        enemy.update_pathfinding()
```

---

## Performance Checklist

Before release, verify:

- [ ] Profiler shows consistent frame times
- [ ] No memory leaks (monitor RAM usage over time)
- [ ] Physics runs at stable tick rate
- [ ] Loading times are acceptable
- [ ] No frame drops during gameplay
- [ ] Works on minimum target hardware
- [ ] GC pauses are minimal (avoid large allocations)
