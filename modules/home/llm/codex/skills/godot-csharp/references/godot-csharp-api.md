# Godot C# API Reference and Best Practices

## API Naming Differences

The C# API uses PascalCase instead of snake_case. Here are the key differences:

### Methods and Properties

| GDScript | C# |
|----------|-----|
| `get_node("Path")` | `GetNode<T>("Path")` |
| `add_child(node)` | `AddChild(node)` |
| `queue_free()` | `QueueFree()` |
| `is_inside_tree()` | `IsInsideTree()` |
| `get_tree()` | `GetTree()` |
| `set_process(true)` | `SetProcess(true)` |
| `_ready()` | `_Ready()` |
| `_process(delta)` | `_Process(double delta)` |
| `_physics_process(delta)` | `_PhysicsProcess(double delta)` |
| `_input(event)` | `_Input(InputEvent @event)` |

### Properties

| GDScript | C# |
|----------|-----|
| `position` | `Position` |
| `global_position` | `GlobalPosition` |
| `rotation` | `Rotation` |
| `rotation_degrees` | `RotationDegrees` |
| `scale` | `Scale` |
| `visible` | `Visible` |
| `modulate` | `Modulate` |

### Export Syntax

```csharp
// GDScript: @export var speed: float = 100.0
[Export]
public float Speed { get; set; } = 100.0f;

// GDScript: @export_range(0, 100) var health: int = 100
[Export(PropertyHint.Range, "0,100")]
public int Health { get; set; } = 100;

// GDScript: @export_file("*.png") var texture_path: String
[Export(PropertyHint.File, "*.png")]
public string TexturePath { get; set; } = "";

// GDScript: @export_enum("Sword", "Bow", "Staff") var weapon: int
[Export(PropertyHint.Enum, "Sword,Bow,Staff")]
public int Weapon { get; set; }

// GDScript: @export_node_path("Node2D") var target_path: NodePath
[Export]
public NodePath TargetPath { get; set; } = "";

// GDScript: @export_group("Movement")
[ExportGroup("Movement")]
[Export] public float MoveSpeed { get; set; } = 100f;
[Export] public float JumpForce { get; set; } = 400f;

// GDScript: @export_subgroup("Advanced")
[ExportSubgroup("Advanced")]
[Export] public float Acceleration { get; set; } = 10f;
```

### Signal Definitions

```csharp
// GDScript: signal health_changed(new_health: int, max_health: int)

// C# uses delegate pattern
[Signal]
public delegate void HealthChangedEventHandler(int newHealth, int maxHealth);

// Emitting signals
EmitSignal(SignalName.HealthChanged, health, maxHealth);

// Connecting signals (C# style)
node.HealthChanged += OnHealthChanged;
node.HealthChanged -= OnHealthChanged;

// Connecting signals (Godot style)
node.Connect(Node.SignalName.HealthChanged, Callable.From<int, int>(OnHealthChanged));
```

---

## Node Access Patterns

### Getting Nodes

```csharp
// Direct child
var sprite = GetNode<Sprite2D>("Sprite2D");

// Nested path
var label = GetNode<Label>("UI/HUD/ScoreLabel");

// Safe get (returns null if not found)
var maybeNode = GetNodeOrNull<Node2D>("MaybeExists");

// Get parent
var parent = GetParent<Node2D>();

// Get owner (root of the scene)
var sceneRoot = Owner;

// Get from group
var enemies = GetTree().GetNodesInGroup("enemies");

// First node in group
var player = GetTree().GetFirstNodeInGroup("player") as Player;
```

### Unique Nodes

```csharp
// In scene: Set node's "Access as Unique Name" in editor (% prefix)
// GDScript: %Player
var player = GetNode<Player>("%Player");

// Or by unique name string
var player = GetNode<Player>("%Player");
```

### Deferred Access

```csharp
// Safe for nodes not yet in tree
public override void _Ready()
{
    // Deferred call - runs after current frame
    CallDeferred(MethodName.SetupReferences);
}

private void SetupReferences()
{
    // Now safe to access nodes
    _player = GetTree().GetFirstNodeInGroup("player") as Player;
}
```

---

## Input Handling

### Input Map Actions

```csharp
public override void _PhysicsProcess(double delta)
{
    // Digital input (pressed or not)
    if (Input.IsActionPressed("move_right"))
    {
        Position += Vector2.Right * Speed * (float)delta;
    }

    // Just pressed (single frame)
    if (Input.IsActionJustPressed("jump"))
    {
        Jump();
    }

    // Just released
    if (Input.IsActionJustReleased("attack"))
    {
        ReleaseAttack();
    }

    // Axis input (-1 to 1)
    var horizontal = Input.GetAxis("move_left", "move_right");
    var vertical = Input.GetAxis("move_up", "move_down");

    // 2D Vector input
    var direction = Input.GetVector("move_left", "move_right", "move_up", "move_down");

    // Analog strength (for gamepad triggers, etc.)
    var strength = Input.GetActionStrength("accelerate");
}
```

### Input Events

```csharp
public override void _Input(InputEvent @event)
{
    // Keyboard
    if (@event is InputEventKey keyEvent)
    {
        if (keyEvent.Pressed && keyEvent.Keycode == Key.Escape)
        {
            GetTree().Quit();
        }
    }

    // Mouse button
    if (@event is InputEventMouseButton mouseEvent)
    {
        if (mouseEvent.Pressed && mouseEvent.ButtonIndex == MouseButton.Left)
        {
            Shoot(mouseEvent.Position);
        }
    }

    // Mouse motion
    if (@event is InputEventMouseMotion motionEvent)
    {
        LookAt(motionEvent.Position);
    }

    // Joypad button
    if (@event is InputEventJoypadButton joypadEvent)
    {
        if (joypadEvent.Pressed && joypadEvent.ButtonIndex == JoyButton.A)
        {
            Jump();
        }
    }

    // Mark event as handled
    GetViewport().SetInputAsHandled();
}

public override void _UnhandledInput(InputEvent @event)
{
    // Called only if no one else handled the input
    if (@event.IsActionPressed("pause"))
    {
        TogglePause();
    }
}
```

---

## Physics and Movement

### CharacterBody2D

```csharp
public partial class Player : CharacterBody2D
{
    [Export] public float Speed { get; set; } = 300f;
    [Export] public float JumpVelocity { get; set; } = -400f;
    [Export] public float Gravity { get; set; } = 980f;

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;

        // Apply gravity
        if (!IsOnFloor())
        {
            velocity.Y += Gravity * (float)delta;
        }

        // Handle jump
        if (Input.IsActionJustPressed("jump") && IsOnFloor())
        {
            velocity.Y = JumpVelocity;
        }

        // Get input direction
        var direction = Input.GetAxis("move_left", "move_right");

        // Apply horizontal movement
        if (Mathf.Abs(direction) > 0.1f)
        {
            velocity.X = direction * Speed;
        }
        else
        {
            velocity.X = Mathf.MoveToward(velocity.X, 0, Speed);
        }

        Velocity = velocity;
        MoveAndSlide();

        // Check collisions
        for (int i = 0; i < GetSlideCollisionCount(); i++)
        {
            var collision = GetSlideCollision(i);
            var collider = collision.GetCollider();

            if (collider is Enemy enemy)
            {
                HandleEnemyCollision(enemy, collision);
            }
        }
    }

    private void HandleEnemyCollision(Enemy enemy, KinematicCollision2D collision)
    {
        // Check if stomping from above
        if (collision.GetNormal().Y < -0.7f)
        {
            enemy.TakeDamage(1);
            Velocity = new Vector2(Velocity.X, JumpVelocity * 0.5f);
        }
        else
        {
            TakeDamage(1);
        }
    }
}
```

### Area2D Collision Detection

```csharp
public partial class Hitbox : Area2D
{
    [Signal]
    public delegate void HitEventHandler(Node2D target);

    [Export] public int Damage { get; set; } = 10;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
        AreaEntered += OnAreaEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is IDamageable damageable)
        {
            damageable.TakeDamage(Damage);
            EmitSignal(SignalName.Hit, body);
        }
    }

    private void OnAreaEntered(Area2D area)
    {
        if (area is Hurtbox hurtbox)
        {
            hurtbox.ReceiveHit(this);
        }
    }
}
```

### RayCast2D

```csharp
public partial class Enemy : CharacterBody2D
{
    private RayCast2D _groundCheck = null!;
    private RayCast2D _wallCheck = null!;

    public override void _Ready()
    {
        _groundCheck = GetNode<RayCast2D>("GroundCheck");
        _wallCheck = GetNode<RayCast2D>("WallCheck");
    }

    public override void _PhysicsProcess(double delta)
    {
        // Check for ground ahead
        if (!_groundCheck.IsColliding())
        {
            // Turn around at ledge
            TurnAround();
        }

        // Check for wall
        if (_wallCheck.IsColliding())
        {
            var collider = _wallCheck.GetCollider();
            if (collider is TileMap or StaticBody2D)
            {
                TurnAround();
            }
        }
    }

    private void TurnAround()
    {
        Scale = new Vector2(-Scale.X, Scale.Y);
        _groundCheck.Position = new Vector2(-_groundCheck.Position.X, _groundCheck.Position.Y);
        _wallCheck.Position = new Vector2(-_wallCheck.Position.X, _wallCheck.Position.Y);
    }
}
```

---

## Animation

### AnimationPlayer

```csharp
public partial class Player : CharacterBody2D
{
    private AnimationPlayer _animPlayer = null!;

    public override void _Ready()
    {
        _animPlayer = GetNode<AnimationPlayer>("AnimationPlayer");

        // Connect signals
        _animPlayer.AnimationFinished += OnAnimationFinished;
    }

    public override void _Process(double delta)
    {
        UpdateAnimation();
    }

    private void UpdateAnimation()
    {
        if (!IsOnFloor())
        {
            _animPlayer.Play(Velocity.Y < 0 ? "jump" : "fall");
        }
        else if (Mathf.Abs(Velocity.X) > 0.1f)
        {
            _animPlayer.Play("run");
        }
        else
        {
            _animPlayer.Play("idle");
        }
    }

    private void OnAnimationFinished(StringName animName)
    {
        if (animName == "attack")
        {
            // Return to idle after attack
            _animPlayer.Play("idle");
        }
    }

    public async Task PlayAttackAnimation()
    {
        _animPlayer.Play("attack");
        await ToSignal(_animPlayer, AnimationPlayer.SignalName.AnimationFinished);
    }
}
```

### AnimatedSprite2D

```csharp
public partial class Player : CharacterBody2D
{
    private AnimatedSprite2D _sprite = null!;

    public override void _Ready()
    {
        _sprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
        _sprite.AnimationFinished += OnAnimationFinished;
    }

    private void UpdateAnimation()
    {
        // Flip sprite based on direction
        if (Velocity.X != 0)
        {
            _sprite.FlipH = Velocity.X < 0;
        }

        // Play appropriate animation
        if (!IsOnFloor())
        {
            _sprite.Play("jump");
        }
        else if (Mathf.Abs(Velocity.X) > 0.1f)
        {
            _sprite.Play("run");
        }
        else
        {
            _sprite.Play("idle");
        }
    }

    private void OnAnimationFinished()
    {
        if (_sprite.Animation == "attack")
        {
            _sprite.Play("idle");
        }
    }
}
```

### Tween

```csharp
public partial class UI : Control
{
    public async Task FadeIn(float duration = 0.5f)
    {
        Modulate = new Color(1, 1, 1, 0);

        var tween = CreateTween();
        tween.TweenProperty(this, "modulate:a", 1f, duration);
        tween.SetEase(Tween.EaseType.Out);
        tween.SetTrans(Tween.TransitionType.Cubic);

        await ToSignal(tween, Tween.SignalName.Finished);
    }

    public async Task Shake(float intensity = 10f, float duration = 0.5f)
    {
        var originalPosition = Position;
        var tween = CreateTween();

        var steps = 10;
        var stepDuration = duration / steps;

        for (int i = 0; i < steps; i++)
        {
            var offset = new Vector2(
                GD.Randf() * intensity * 2 - intensity,
                GD.Randf() * intensity * 2 - intensity
            );
            tween.TweenProperty(this, "position", originalPosition + offset, stepDuration);
        }

        tween.TweenProperty(this, "position", originalPosition, stepDuration);

        await ToSignal(tween, Tween.SignalName.Finished);
    }

    public void AnimateScore(int from, int to, float duration = 1f)
    {
        var label = GetNode<Label>("ScoreLabel");
        var tween = CreateTween();

        tween.TweenMethod(
            Callable.From<int>(value => label.Text = value.ToString()),
            from, to, duration
        );
    }
}
```

---

## Resource Management

### Custom Resources

```csharp
// Resources/WeaponData.cs
[GlobalClass]
public partial class WeaponData : Resource
{
    [Export] public string WeaponName { get; set; } = "";
    [Export] public int BaseDamage { get; set; } = 10;
    [Export] public float AttackSpeed { get; set; } = 1.0f;
    [Export] public float Range { get; set; } = 50f;
    [Export] public Texture2D? Icon { get; set; }
    [Export] public PackedScene? ProjectileScene { get; set; }
    [Export] public AudioStream? AttackSound { get; set; }

    public float GetDPS() => BaseDamage * AttackSpeed;
}

// Usage
public partial class Weapon : Node2D
{
    [Export]
    public WeaponData? Data { get; set; }

    public void Attack(IDamageable target)
    {
        if (Data is null) return;

        target.TakeDamage(Data.BaseDamage);

        if (Data.AttackSound is not null)
        {
            var audioPlayer = GetNode<AudioStreamPlayer2D>("AudioPlayer");
            audioPlayer.Stream = Data.AttackSound;
            audioPlayer.Play();
        }
    }
}
```

### Loading Resources

```csharp
// Synchronous loading
var texture = GD.Load<Texture2D>("res://assets/sprites/player.png");
var scene = GD.Load<PackedScene>("res://scenes/enemies/Slime.tscn");
var weaponData = GD.Load<WeaponData>("res://resources/weapons/Sword.tres");

// Check if resource exists
if (ResourceLoader.Exists("res://scenes/levels/Level2.tscn"))
{
    var level = GD.Load<PackedScene>("res://scenes/levels/Level2.tscn");
}

// Async loading
public async Task<PackedScene?> LoadSceneAsync(string path)
{
    var error = ResourceLoader.LoadThreadedRequest(path);
    if (error != Error.Ok)
    {
        GD.PushError($"Failed to start loading {path}");
        return null;
    }

    while (true)
    {
        var status = ResourceLoader.LoadThreadedGetStatus(path);

        switch (status)
        {
            case ResourceLoader.ThreadLoadStatus.Loaded:
                return ResourceLoader.LoadThreadedGet(path) as PackedScene;

            case ResourceLoader.ThreadLoadStatus.Failed:
            case ResourceLoader.ThreadLoadStatus.InvalidResource:
                GD.PushError($"Failed to load {path}");
                return null;

            case ResourceLoader.ThreadLoadStatus.InProgress:
                // Show loading progress
                var progress = new Godot.Collections.Array();
                ResourceLoader.LoadThreadedGetStatus(path, progress);
                if (progress.Count > 0)
                {
                    GD.Print($"Loading: {(float)progress[0] * 100:F0}%");
                }
                await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
                break;
        }
    }
}
```

---

## Scene Management

### Changing Scenes

```csharp
// Simple scene change
GetTree().ChangeSceneToFile("res://scenes/levels/Level2.tscn");

// With packed scene
var scene = GD.Load<PackedScene>("res://scenes/levels/Level2.tscn");
GetTree().ChangeSceneToPacked(scene);

// Deferred (safe from physics callback)
GetTree().CallDeferred("change_scene_to_file", "res://scenes/levels/Level2.tscn");
```

### Scene Transitions

```csharp
public partial class SceneManager : Node
{
    public static SceneManager Instance { get; private set; } = null!;

    private ColorRect? _fadeRect;

    public override void _Ready()
    {
        Instance = this;

        // Create fade overlay
        _fadeRect = new ColorRect
        {
            Color = Colors.Black,
            MouseFilter = Control.MouseFilterEnum.Ignore
        };

        var canvas = new CanvasLayer { Layer = 100 };
        canvas.AddChild(_fadeRect);
        AddChild(canvas);

        _fadeRect.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        _fadeRect.Modulate = new Color(1, 1, 1, 0);
    }

    public async Task ChangeScene(string path, float fadeDuration = 0.5f)
    {
        // Fade out
        var tween = CreateTween();
        tween.TweenProperty(_fadeRect, "modulate:a", 1f, fadeDuration);
        await ToSignal(tween, Tween.SignalName.Finished);

        // Change scene
        GetTree().ChangeSceneToFile(path);

        // Wait a frame for new scene to load
        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

        // Fade in
        tween = CreateTween();
        tween.TweenProperty(_fadeRect, "modulate:a", 0f, fadeDuration);
        await ToSignal(tween, Tween.SignalName.Finished);
    }
}

// Usage
await SceneManager.Instance.ChangeScene("res://scenes/levels/Level2.tscn");
```

### Instancing Scenes

```csharp
public partial class EnemySpawner : Node2D
{
    [Export]
    public PackedScene? EnemyScene { get; set; }

    [Export]
    public float SpawnInterval { get; set; } = 2f;

    private Timer _spawnTimer = null!;

    public override void _Ready()
    {
        _spawnTimer = new Timer
        {
            WaitTime = SpawnInterval,
            Autostart = true
        };
        _spawnTimer.Timeout += SpawnEnemy;
        AddChild(_spawnTimer);
    }

    private void SpawnEnemy()
    {
        if (EnemyScene is null) return;

        var enemy = EnemyScene.Instantiate<Enemy>();
        enemy.Position = GlobalPosition;
        enemy.Died += () => OnEnemyDied(enemy);

        GetParent().AddChild(enemy);
    }

    private void OnEnemyDied(Enemy enemy)
    {
        GD.Print($"Enemy at {enemy.Position} died");
    }
}
```

---

## Saving and Loading

### Save System

```csharp
public static class SaveManager
{
    private const string SavePath = "user://savegame.json";

    public static void Save(GameSaveData data)
    {
        var json = JsonSerializer.Serialize(data, new JsonSerializerOptions
        {
            WriteIndented = true
        });

        using var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Write);
        if (file is null)
        {
            GD.PushError($"Failed to open save file: {FileAccess.GetOpenError()}");
            return;
        }

        file.StoreString(json);
    }

    public static GameSaveData? Load()
    {
        if (!FileAccess.FileExists(SavePath))
        {
            return null;
        }

        using var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Read);
        if (file is null)
        {
            GD.PushError($"Failed to open save file: {FileAccess.GetOpenError()}");
            return null;
        }

        var json = file.GetAsText();

        try
        {
            return JsonSerializer.Deserialize<GameSaveData>(json);
        }
        catch (JsonException ex)
        {
            GD.PushError($"Failed to parse save file: {ex.Message}");
            return null;
        }
    }

    public static bool SaveExists() => FileAccess.FileExists(SavePath);

    public static void DeleteSave()
    {
        if (SaveExists())
        {
            DirAccess.RemoveAbsolute(SavePath);
        }
    }
}

// Save data structure
public class GameSaveData
{
    public string PlayerName { get; set; } = "";
    public int Level { get; set; } = 1;
    public int Health { get; set; } = 100;
    public int MaxHealth { get; set; } = 100;
    public float PositionX { get; set; }
    public float PositionY { get; set; }
    public List<string> Inventory { get; set; } = new();
    public Dictionary<string, bool> Flags { get; set; } = new();
    public DateTime SaveTime { get; set; } = DateTime.Now;
}
```

---

## Audio

### Audio Management

```csharp
public partial class AudioManager : Node
{
    public static AudioManager Instance { get; private set; } = null!;

    private AudioStreamPlayer _musicPlayer = null!;
    private readonly Dictionary<string, AudioStreamPlayer> _sfxPlayers = new();

    [Export] public int MaxSimultaneousSfx { get; set; } = 8;

    public override void _Ready()
    {
        Instance = this;

        _musicPlayer = new AudioStreamPlayer { Bus = "Music" };
        AddChild(_musicPlayer);

        for (int i = 0; i < MaxSimultaneousSfx; i++)
        {
            var player = new AudioStreamPlayer { Bus = "SFX" };
            AddChild(player);
            _sfxPlayers[$"sfx_{i}"] = player;
        }
    }

    public void PlayMusic(AudioStream stream, float fadeTime = 1f)
    {
        if (_musicPlayer.Stream == stream && _musicPlayer.Playing)
            return;

        var tween = CreateTween();

        if (_musicPlayer.Playing)
        {
            tween.TweenProperty(_musicPlayer, "volume_db", -80f, fadeTime);
            tween.TweenCallback(Callable.From(() =>
            {
                _musicPlayer.Stream = stream;
                _musicPlayer.VolumeDb = -80f;
                _musicPlayer.Play();
            }));
            tween.TweenProperty(_musicPlayer, "volume_db", 0f, fadeTime);
        }
        else
        {
            _musicPlayer.Stream = stream;
            _musicPlayer.VolumeDb = 0f;
            _musicPlayer.Play();
        }
    }

    public void PlaySfx(AudioStream stream, float volumeDb = 0f)
    {
        // Find available player
        foreach (var player in _sfxPlayers.Values)
        {
            if (!player.Playing)
            {
                player.Stream = stream;
                player.VolumeDb = volumeDb;
                player.Play();
                return;
            }
        }

        // All players busy - use first one (oldest sound)
        var firstPlayer = _sfxPlayers.Values.First();
        firstPlayer.Stream = stream;
        firstPlayer.VolumeDb = volumeDb;
        firstPlayer.Play();
    }

    public void StopMusic(float fadeTime = 1f)
    {
        var tween = CreateTween();
        tween.TweenProperty(_musicPlayer, "volume_db", -80f, fadeTime);
        tween.TweenCallback(Callable.From(() => _musicPlayer.Stop()));
    }
}
```

---

## Global Functions (GD Class)

```csharp
// Printing
GD.Print("Hello, World!");
GD.PrintErr("This is an error");
GD.PrintS("Space", "separated", "values");
GD.PrintT("Tab", "separated", "values");

// Warnings and errors
GD.PushWarning("This is a warning");
GD.PushError("This is an error");

// Random
var randomFloat = GD.Randf();           // 0.0 to 1.0
var randomInt = GD.RandRange(1, 10);    // 1 to 10 inclusive
var randomFromArray = items[GD.Randi() % items.Count];

// Seeding random
GD.Seed(12345);
GD.Randomize(); // Use current time as seed

// Math
var clamped = Mathf.Clamp(value, 0, 100);
var lerped = Mathf.Lerp(0f, 100f, 0.5f);  // 50
var smoothed = Mathf.SmoothStep(0f, 1f, t);
var mapped = Mathf.Remap(value, 0, 100, 0, 1);

// Type conversions
var intVar = GD.VarToStr(42);           // "42"
var parsed = GD.StrToVar("42");         // Variant containing 42

// Instance checking
var isValid = GodotObject.IsInstanceValid(node);

// Loading
var resource = GD.Load<Texture2D>("res://icon.png");
var scene = GD.Load<PackedScene>("res://scenes/Player.tscn");
```

---

## Common Gotchas

### 1. Partial Classes Required

```csharp
// WRONG - won't work with Godot
public class Player : CharacterBody2D { }

// CORRECT - must be partial
public partial class Player : CharacterBody2D { }
```

### 2. Signal Delegate Naming

```csharp
// Signal delegates MUST end with "EventHandler"
[Signal]
public delegate void HealthChangedEventHandler(int health);  // Correct

[Signal]
public delegate void HealthChanged(int health);  // WRONG - won't compile
```

### 3. Export Types

```csharp
// These work with [Export]
[Export] public int IntValue { get; set; }
[Export] public float FloatValue { get; set; }
[Export] public string StringValue { get; set; } = "";
[Export] public Vector2 Vector2Value { get; set; }
[Export] public Node2D? NodeReference { get; set; }
[Export] public PackedScene? SceneReference { get; set; }
[Export] public Resource? ResourceReference { get; set; }

// Arrays work but must use Godot.Collections
[Export] public Godot.Collections.Array<int> IntArray { get; set; } = new();
[Export] public Godot.Collections.Dictionary<string, int> Dict { get; set; } = new();

// Regular C# collections DON'T work with [Export]
// [Export] public List<int> IntList { get; set; }  // WRONG
```

### 4. Null Reference Types

```csharp
public partial class Player : CharacterBody2D
{
    // Use null! for required exports (set in editor)
    [Export] public HealthComponent HealthComponent { get; set; } = null!;

    // Use ? for truly optional references
    public Node2D? Target { get; set; }

    public override void _Ready()
    {
        // Always validate required references
        if (HealthComponent is null)
        {
            GD.PushError("HealthComponent not assigned!");
            return;
        }
    }
}
```

### 5. Async/Await with Signals

```csharp
// CORRECT - await ToSignal returns SignalAwaiter
await ToSignal(timer, Timer.SignalName.Timeout);
await ToSignal(animPlayer, AnimationPlayer.SignalName.AnimationFinished);
await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

// For custom signals
await ToSignal(this, SignalName.MyCustomSignal);
```

### 6. Collections

```csharp
// Use Godot collections for engine interop
var godotArray = new Godot.Collections.Array<Node>();
var godotDict = new Godot.Collections.Dictionary<string, Variant>();

// Use C# collections for internal logic
var csharpList = new List<Enemy>();
var csharpDict = new Dictionary<string, int>();

// Converting between them
var nodes = GetTree().GetNodesInGroup("enemies");  // Returns Godot Array
var enemyList = nodes.Cast<Enemy>().ToList();      // Convert to C# List
```
