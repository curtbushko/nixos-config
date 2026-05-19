# C# Design Patterns and SOLID Principles for Godot

## SOLID Principles

### Single Responsibility Principle (SRP)

Each class should have one reason to change.

```csharp
// BAD: One class doing too much
public partial class Player : CharacterBody2D
{
    public void Move() { /* movement logic */ }
    public void TakeDamage(int amount) { /* health logic */ }
    public void Attack() { /* combat logic */ }
    public void PlaySound(string sound) { /* audio logic */ }
    public void SaveProgress() { /* save logic */ }
    public void UpdateUI() { /* UI logic */ }
}

// GOOD: Separate components for each responsibility
public partial class Player : CharacterBody2D
{
    [Export] public HealthComponent Health { get; set; } = null!;
    [Export] public MovementComponent Movement { get; set; } = null!;
    [Export] public CombatComponent Combat { get; set; } = null!;
}

public partial class HealthComponent : Node
{
    public int Health { get; private set; }
    public void TakeDamage(int amount) { /* health logic only */ }
}

public partial class MovementComponent : Node
{
    public void Move(Vector2 direction) { /* movement logic only */ }
}

public partial class CombatComponent : Node
{
    public void Attack() { /* combat logic only */ }
}
```

### Open/Closed Principle (OCP)

Open for extension, closed for modification.

```csharp
// BAD: Modifying existing code for each new weapon type
public class Weapon
{
    public int CalculateDamage(string weaponType)
    {
        switch (weaponType)
        {
            case "sword": return 10;
            case "axe": return 15;
            case "bow": return 8;
            // Have to modify this method for every new weapon
            default: return 5;
        }
    }
}

// GOOD: Extended through inheritance/interfaces
public interface IWeapon
{
    int BaseDamage { get; }
    float AttackSpeed { get; }
    int CalculateDamage(int strengthBonus);
}

public class Sword : IWeapon
{
    public int BaseDamage => 10;
    public float AttackSpeed => 1.5f;

    public int CalculateDamage(int strengthBonus)
        => BaseDamage + (int)(strengthBonus * 0.5f);
}

public class Axe : IWeapon
{
    public int BaseDamage => 15;
    public float AttackSpeed => 0.8f;

    public int CalculateDamage(int strengthBonus)
        => BaseDamage + strengthBonus; // Axes scale better with strength
}

// New weapons can be added without modifying existing code
public class MagicStaff : IWeapon
{
    public int BaseDamage => 5;
    public float AttackSpeed => 2.0f;

    public int CalculateDamage(int strengthBonus)
        => BaseDamage * 2; // Ignores strength, uses magic
}
```

### Liskov Substitution Principle (LSP)

Derived classes must be substitutable for their base classes.

```csharp
// BAD: Square violates LSP when used as Rectangle
public class Rectangle
{
    public virtual int Width { get; set; }
    public virtual int Height { get; set; }

    public int Area => Width * Height;
}

public class Square : Rectangle
{
    public override int Width
    {
        get => base.Width;
        set { base.Width = value; base.Height = value; }
    }

    public override int Height
    {
        get => base.Height;
        set { base.Width = value; base.Height = value; }
    }
}

// This breaks when you do:
// Rectangle rect = new Square();
// rect.Width = 5;
// rect.Height = 10;
// rect.Area would be 100, not 50!

// GOOD: Use interfaces that make sense for substitution
public interface IShape
{
    int Area { get; }
}

public class Rectangle : IShape
{
    public int Width { get; set; }
    public int Height { get; set; }
    public int Area => Width * Height;
}

public class Square : IShape
{
    public int Side { get; set; }
    public int Area => Side * Side;
}
```

### Interface Segregation Principle (ISP)

Clients shouldn't depend on interfaces they don't use.

```csharp
// BAD: One large interface
public interface IEntity
{
    void Move(Vector2 direction);
    void TakeDamage(int amount);
    void Attack(IEntity target);
    void Heal(int amount);
    void SaveState();
    void LoadState();
    void PlayAnimation(string name);
    void PlaySound(string name);
}

// A static prop doesn't need most of these!

// GOOD: Smaller, focused interfaces
public interface IMovable
{
    void Move(Vector2 direction);
    Vector2 Velocity { get; }
}

public interface IDamageable
{
    int Health { get; }
    void TakeDamage(int amount);
    event Action? Died;
}

public interface IAttacker
{
    int Damage { get; }
    void Attack(IDamageable target);
}

public interface ISaveable
{
    void SaveState(ISaveWriter writer);
    void LoadState(ISaveReader reader);
}

// Now classes implement only what they need
public partial class Player : CharacterBody2D, IMovable, IDamageable, IAttacker, ISaveable
{
    // Implements all interfaces
}

public partial class Turret : Node2D, IAttacker
{
    // Only implements IAttacker - doesn't move or take damage
}

public partial class DestructibleProp : Node2D, IDamageable
{
    // Only implements IDamageable - doesn't move or attack
}
```

### Dependency Inversion Principle (DIP)

Depend on abstractions, not concrete implementations.

```csharp
// BAD: High-level module depends on low-level module
public class Player
{
    private readonly FileLogger _logger = new FileLogger();
    private readonly SqlDatabase _database = new SqlDatabase();

    public void SaveProgress()
    {
        _logger.Log("Saving progress...");
        _database.Save(this);
    }
}

// GOOD: Both depend on abstractions
public interface ILogger
{
    void Log(string message);
    void LogError(string message);
}

public interface IGameDataStore
{
    void Save<T>(string key, T data);
    T? Load<T>(string key);
}

public class Player
{
    private readonly ILogger _logger;
    private readonly IGameDataStore _dataStore;

    public Player(ILogger logger, IGameDataStore dataStore)
    {
        _logger = logger;
        _dataStore = dataStore;
    }

    public void SaveProgress()
    {
        _logger.Log("Saving progress...");
        _dataStore.Save("player", GetSaveData());
    }
}

// Implementations
public class GodotLogger : ILogger
{
    public void Log(string message) => GD.Print(message);
    public void LogError(string message) => GD.PushError(message);
}

public class ResourceDataStore : IGameDataStore
{
    public void Save<T>(string key, T data)
    {
        // Save using Godot's ResourceSaver
    }

    public T? Load<T>(string key)
    {
        // Load using Godot's ResourceLoader
        return default;
    }
}
```

---

## Common Design Patterns

### Singleton Pattern (Use Sparingly)

For global game state and services. In Godot, use Autoloads.

```csharp
// Autoloads/GameManager.cs
public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; } = null!;

    public GameState CurrentState { get; private set; } = GameState.Playing;
    public int Score { get; private set; }

    public override void _Ready()
    {
        Instance = this;
        ProcessMode = ProcessModeEnum.Always; // Run even when paused
    }

    public void AddScore(int points)
    {
        Score += points;
        EmitSignal(SignalName.ScoreChanged, Score);
    }

    public void PauseGame()
    {
        CurrentState = GameState.Paused;
        GetTree().Paused = true;
        EmitSignal(SignalName.GamePaused);
    }

    public void ResumeGame()
    {
        CurrentState = GameState.Playing;
        GetTree().Paused = false;
        EmitSignal(SignalName.GameResumed);
    }

    [Signal]
    public delegate void ScoreChangedEventHandler(int newScore);

    [Signal]
    public delegate void GamePausedEventHandler();

    [Signal]
    public delegate void GameResumedEventHandler();
}

public enum GameState
{
    Playing,
    Paused,
    GameOver
}
```

### Factory Pattern

For creating complex objects with configuration.

```csharp
// Factory for creating enemies
public interface IEnemyFactory
{
    Enemy CreateEnemy(EnemyType type, Vector2 position);
}

public class EnemyFactory : IEnemyFactory
{
    private readonly Dictionary<EnemyType, PackedScene> _enemyScenes;

    public EnemyFactory()
    {
        _enemyScenes = new Dictionary<EnemyType, PackedScene>
        {
            [EnemyType.Slime] = GD.Load<PackedScene>("res://scenes/enemies/Slime.tscn"),
            [EnemyType.Goblin] = GD.Load<PackedScene>("res://scenes/enemies/Goblin.tscn"),
            [EnemyType.Skeleton] = GD.Load<PackedScene>("res://scenes/enemies/Skeleton.tscn"),
            [EnemyType.Boss] = GD.Load<PackedScene>("res://scenes/enemies/Boss.tscn"),
        };
    }

    public Enemy CreateEnemy(EnemyType type, Vector2 position)
    {
        if (!_enemyScenes.TryGetValue(type, out var scene))
        {
            throw new ArgumentException($"Unknown enemy type: {type}");
        }

        var enemy = scene.Instantiate<Enemy>();
        enemy.Position = position;

        // Apply type-specific configuration
        ConfigureEnemy(enemy, type);

        return enemy;
    }

    private void ConfigureEnemy(Enemy enemy, EnemyType type)
    {
        var config = GetEnemyConfig(type);
        enemy.HealthComponent.MaxHealth = config.MaxHealth;
        enemy.Damage = config.Damage;
        enemy.MoveSpeed = config.MoveSpeed;
    }

    private EnemyConfig GetEnemyConfig(EnemyType type) => type switch
    {
        EnemyType.Slime => new EnemyConfig(30, 5, 50f),
        EnemyType.Goblin => new EnemyConfig(50, 10, 100f),
        EnemyType.Skeleton => new EnemyConfig(40, 15, 80f),
        EnemyType.Boss => new EnemyConfig(500, 30, 60f),
        _ => new EnemyConfig(20, 5, 50f)
    };

    private record EnemyConfig(int MaxHealth, int Damage, float MoveSpeed);
}

public enum EnemyType
{
    Slime,
    Goblin,
    Skeleton,
    Boss
}
```

### Strategy Pattern

For interchangeable algorithms.

```csharp
// Movement strategies
public interface IMovementStrategy
{
    Vector2 CalculateMovement(Node2D entity, double delta);
}

public class ChaseStrategy : IMovementStrategy
{
    private readonly Node2D _target;
    private readonly float _speed;

    public ChaseStrategy(Node2D target, float speed)
    {
        _target = target;
        _speed = speed;
    }

    public Vector2 CalculateMovement(Node2D entity, double delta)
    {
        var direction = (_target.GlobalPosition - entity.GlobalPosition).Normalized();
        return direction * _speed * (float)delta;
    }
}

public class PatrolStrategy : IMovementStrategy
{
    private readonly Vector2[] _waypoints;
    private readonly float _speed;
    private int _currentWaypoint;

    public PatrolStrategy(Vector2[] waypoints, float speed)
    {
        _waypoints = waypoints;
        _speed = speed;
    }

    public Vector2 CalculateMovement(Node2D entity, double delta)
    {
        var target = _waypoints[_currentWaypoint];
        var direction = (target - entity.GlobalPosition).Normalized();

        if (entity.GlobalPosition.DistanceTo(target) < 5f)
        {
            _currentWaypoint = (_currentWaypoint + 1) % _waypoints.Length;
        }

        return direction * _speed * (float)delta;
    }
}

public class FleeStrategy : IMovementStrategy
{
    private readonly Node2D _threat;
    private readonly float _speed;

    public FleeStrategy(Node2D threat, float speed)
    {
        _threat = threat;
        _speed = speed;
    }

    public Vector2 CalculateMovement(Node2D entity, double delta)
    {
        var direction = (entity.GlobalPosition - _threat.GlobalPosition).Normalized();
        return direction * _speed * (float)delta;
    }
}

// Usage in Enemy
public partial class Enemy : CharacterBody2D
{
    private IMovementStrategy _movementStrategy = null!;

    public void SetMovementStrategy(IMovementStrategy strategy)
    {
        _movementStrategy = strategy;
    }

    public override void _PhysicsProcess(double delta)
    {
        var movement = _movementStrategy.CalculateMovement(this, delta);
        Velocity = movement / (float)delta;
        MoveAndSlide();
    }
}
```

### Observer Pattern (Event Aggregator)

For decoupled communication between systems.

```csharp
// Events/GameEvents.cs
public static class GameEvents
{
    // Player Events
    public static event Action<int, int>? OnPlayerHealthChanged;
    public static event Action? OnPlayerDied;
    public static event Action<Vector2>? OnPlayerMoved;

    // Combat Events
    public static event Action<Node, Node, int>? OnDamageDealt;
    public static event Action<Node>? OnEnemyKilled;

    // Game State Events
    public static event Action? OnLevelStarted;
    public static event Action? OnLevelCompleted;
    public static event Action<int>? OnScoreChanged;

    // Raise methods
    public static void RaisePlayerHealthChanged(int current, int max)
        => OnPlayerHealthChanged?.Invoke(current, max);

    public static void RaisePlayerDied()
        => OnPlayerDied?.Invoke();

    public static void RaiseDamageDealt(Node attacker, Node target, int damage)
        => OnDamageDealt?.Invoke(attacker, target, damage);

    public static void RaiseEnemyKilled(Node enemy)
        => OnEnemyKilled?.Invoke(enemy);

    public static void RaiseScoreChanged(int newScore)
        => OnScoreChanged?.Invoke(newScore);

    // Clear all subscriptions (call on scene change)
    public static void ClearAll()
    {
        OnPlayerHealthChanged = null;
        OnPlayerDied = null;
        OnPlayerMoved = null;
        OnDamageDealt = null;
        OnEnemyKilled = null;
        OnLevelStarted = null;
        OnLevelCompleted = null;
        OnScoreChanged = null;
    }
}

// Usage in HealthComponent
public void TakeDamage(int amount, Node? source = null)
{
    Health -= amount;
    GameEvents.RaisePlayerHealthChanged(Health, MaxHealth);

    if (source != null)
    {
        GameEvents.RaiseDamageDealt(source, Owner, amount);
    }

    if (IsDead)
    {
        GameEvents.RaisePlayerDied();
    }
}

// Usage in UI
public partial class HealthBar : Control
{
    public override void _Ready()
    {
        GameEvents.OnPlayerHealthChanged += UpdateHealthBar;
    }

    public override void _ExitTree()
    {
        GameEvents.OnPlayerHealthChanged -= UpdateHealthBar;
    }

    private void UpdateHealthBar(int current, int max)
    {
        var bar = GetNode<ProgressBar>("Bar");
        bar.Value = (float)current / max * 100;
    }
}
```

### State Pattern (Finite State Machine)

For managing complex entity states.

```csharp
// States/IState.cs
public interface IState
{
    void Enter(IStateMachine stateMachine);
    void Exit();
    void Update(double delta);
    void PhysicsUpdate(double delta);
    void HandleInput(InputEvent @event);
}

// States/StateMachine.cs
public interface IStateMachine
{
    IState CurrentState { get; }
    void TransitionTo<T>() where T : IState;
    void TransitionTo(string stateName);
    T GetOwner<T>() where T : Node;
}

public partial class StateMachine : Node, IStateMachine
{
    [Signal]
    public delegate void StateChangedEventHandler(string oldState, string newState);

    private readonly Dictionary<string, IState> _states = new();

    public IState CurrentState { get; private set; } = null!;

    [Export]
    public string InitialState { get; set; } = "";

    public override void _Ready()
    {
        foreach (var child in GetChildren())
        {
            if (child is IState state)
            {
                _states[child.Name] = state;
            }
        }

        if (!string.IsNullOrEmpty(InitialState) && _states.TryGetValue(InitialState, out var initial))
        {
            CurrentState = initial;
            CurrentState.Enter(this);
        }
    }

    public override void _Process(double delta)
    {
        CurrentState?.Update(delta);
    }

    public override void _PhysicsProcess(double delta)
    {
        CurrentState?.PhysicsUpdate(delta);
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        CurrentState?.HandleInput(@event);
    }

    public void TransitionTo<T>() where T : IState
    {
        var stateName = typeof(T).Name;
        TransitionTo(stateName);
    }

    public void TransitionTo(string stateName)
    {
        if (!_states.TryGetValue(stateName, out var newState))
        {
            GD.PushError($"State '{stateName}' not found");
            return;
        }

        var oldStateName = CurrentState?.GetType().Name ?? "";
        CurrentState?.Exit();
        CurrentState = newState;
        CurrentState.Enter(this);

        EmitSignal(SignalName.StateChanged, oldStateName, stateName);
    }

    public T GetOwner<T>() where T : Node
    {
        return Owner as T ?? throw new InvalidCastException($"Owner is not of type {typeof(T).Name}");
    }
}

// States/PlayerStates/IdleState.cs
public partial class IdleState : Node, IState
{
    private IStateMachine _stateMachine = null!;
    private Player _player = null!;

    public void Enter(IStateMachine stateMachine)
    {
        _stateMachine = stateMachine;
        _player = stateMachine.GetOwner<Player>();
        _player.AnimationPlayer.Play("idle");
    }

    public void Exit() { }

    public void Update(double delta) { }

    public void PhysicsUpdate(double delta)
    {
        var inputDirection = Input.GetVector("move_left", "move_right", "move_up", "move_down");

        if (inputDirection.LengthSquared() > 0.01f)
        {
            _stateMachine.TransitionTo("RunState");
            return;
        }

        if (Input.IsActionJustPressed("jump") && _player.IsOnFloor())
        {
            _stateMachine.TransitionTo("JumpState");
            return;
        }

        if (Input.IsActionJustPressed("attack"))
        {
            _stateMachine.TransitionTo("AttackState");
            return;
        }
    }

    public void HandleInput(InputEvent @event) { }
}
```

### Command Pattern

For input handling, undo/redo, and action replay.

```csharp
// Commands/ICommand.cs
public interface ICommand
{
    void Execute();
    void Undo();
    bool CanExecute();
}

// Commands/MoveCommand.cs
public class MoveCommand : ICommand
{
    private readonly CharacterBody2D _actor;
    private readonly Vector2 _direction;
    private readonly float _distance;
    private Vector2 _previousPosition;

    public MoveCommand(CharacterBody2D actor, Vector2 direction, float distance)
    {
        _actor = actor;
        _direction = direction.Normalized();
        _distance = distance;
    }

    public bool CanExecute() => _actor.IsInsideTree();

    public void Execute()
    {
        _previousPosition = _actor.Position;
        _actor.Position += _direction * _distance;
    }

    public void Undo()
    {
        _actor.Position = _previousPosition;
    }
}

// Commands/AttackCommand.cs
public class AttackCommand : ICommand
{
    private readonly IAttacker _attacker;
    private readonly IDamageable _target;
    private int _damageDealt;

    public AttackCommand(IAttacker attacker, IDamageable target)
    {
        _attacker = attacker;
        _target = target;
    }

    public bool CanExecute() => !_target.IsDead;

    public void Execute()
    {
        _damageDealt = _attacker.Damage;
        _target.TakeDamage(_damageDealt);
    }

    public void Undo()
    {
        // Can't undo damage in most games, but useful for turn-based
        _target.Heal(_damageDealt);
    }
}

// Commands/CommandInvoker.cs
public class CommandInvoker
{
    private readonly Stack<ICommand> _undoStack = new();
    private readonly Stack<ICommand> _redoStack = new();

    public void Execute(ICommand command)
    {
        if (!command.CanExecute())
            return;

        command.Execute();
        _undoStack.Push(command);
        _redoStack.Clear(); // Clear redo stack on new command
    }

    public bool CanUndo => _undoStack.Count > 0;
    public bool CanRedo => _redoStack.Count > 0;

    public void Undo()
    {
        if (!CanUndo) return;

        var command = _undoStack.Pop();
        command.Undo();
        _redoStack.Push(command);
    }

    public void Redo()
    {
        if (!CanRedo) return;

        var command = _redoStack.Pop();
        command.Execute();
        _undoStack.Push(command);
    }

    public void Clear()
    {
        _undoStack.Clear();
        _redoStack.Clear();
    }
}
```

### Object Pool Pattern

For performance-critical object reuse.

```csharp
// Systems/GenericObjectPool.cs
public class ObjectPool<T> where T : Node, new()
{
    private readonly Queue<T> _available = new();
    private readonly HashSet<T> _active = new();
    private readonly Node _parent;
    private readonly int _maxSize;
    private readonly Func<T>? _factory;

    public int ActiveCount => _active.Count;
    public int AvailableCount => _available.Count;

    public ObjectPool(Node parent, int initialSize = 10, int maxSize = 100,
        Func<T>? factory = null)
    {
        _parent = parent;
        _maxSize = maxSize;
        _factory = factory;

        for (int i = 0; i < initialSize; i++)
        {
            var instance = CreateInstance();
            Deactivate(instance);
            _available.Enqueue(instance);
        }
    }

    public T? Get()
    {
        T instance;

        if (_available.Count > 0)
        {
            instance = _available.Dequeue();
        }
        else if (_active.Count < _maxSize)
        {
            instance = CreateInstance();
        }
        else
        {
            GD.PushWarning($"Object pool exhausted (max: {_maxSize})");
            return null;
        }

        Activate(instance);
        _active.Add(instance);

        if (instance is IPoolable poolable)
            poolable.OnSpawn();

        return instance;
    }

    public void Return(T instance)
    {
        if (!_active.Contains(instance))
        {
            GD.PushWarning("Returning instance not from this pool");
            return;
        }

        if (instance is IPoolable poolable)
            poolable.OnDespawn();

        Deactivate(instance);
        _active.Remove(instance);
        _available.Enqueue(instance);
    }

    public void ReturnAll()
    {
        foreach (var instance in _active.ToList())
        {
            Return(instance);
        }
    }

    private T CreateInstance()
    {
        var instance = _factory?.Invoke() ?? new T();
        _parent.AddChild(instance);
        return instance;
    }

    private void Activate(T instance)
    {
        instance.SetProcess(true);
        instance.SetPhysicsProcess(true);

        if (instance is CanvasItem canvasItem)
            canvasItem.Visible = true;
        else if (instance is Node3D node3D)
            node3D.Visible = true;
    }

    private void Deactivate(T instance)
    {
        instance.SetProcess(false);
        instance.SetPhysicsProcess(false);

        if (instance is CanvasItem canvasItem)
            canvasItem.Visible = false;
        else if (instance is Node3D node3D)
            node3D.Visible = false;
    }
}

public interface IPoolable
{
    void OnSpawn();
    void OnDespawn();
}

// Usage: Bullet pool
public partial class BulletManager : Node
{
    private ObjectPool<Bullet> _bulletPool = null!;

    [Export]
    public PackedScene BulletScene { get; set; } = null!;

    public override void _Ready()
    {
        _bulletPool = new ObjectPool<Bullet>(
            parent: this,
            initialSize: 50,
            maxSize: 200,
            factory: () => BulletScene.Instantiate<Bullet>()
        );
    }

    public Bullet? SpawnBullet(Vector2 position, Vector2 direction)
    {
        var bullet = _bulletPool.Get();
        if (bullet == null) return null;

        bullet.Position = position;
        bullet.Direction = direction;
        bullet.OnHit += () => _bulletPool.Return(bullet);

        return bullet;
    }
}
```

### Service Locator Pattern

For accessing services without tight coupling.

```csharp
// Services/ServiceLocator.cs
public static class ServiceLocator
{
    private static readonly Dictionary<Type, object> _services = new();
    private static readonly Dictionary<Type, Func<object>> _factories = new();

    public static void Register<T>(T service) where T : class
    {
        _services[typeof(T)] = service;
    }

    public static void RegisterFactory<T>(Func<T> factory) where T : class
    {
        _factories[typeof(T)] = () => factory();
    }

    public static T Get<T>() where T : class
    {
        if (_services.TryGetValue(typeof(T), out var service))
        {
            return (T)service;
        }

        if (_factories.TryGetValue(typeof(T), out var factory))
        {
            var instance = (T)factory();
            _services[typeof(T)] = instance;
            return instance;
        }

        throw new InvalidOperationException($"Service {typeof(T).Name} not registered");
    }

    public static bool TryGet<T>(out T? service) where T : class
    {
        if (_services.TryGetValue(typeof(T), out var obj))
        {
            service = (T)obj;
            return true;
        }

        if (_factories.TryGetValue(typeof(T), out var factory))
        {
            service = (T)factory();
            _services[typeof(T)] = service;
            return true;
        }

        service = null;
        return false;
    }

    public static void Clear()
    {
        foreach (var service in _services.Values)
        {
            if (service is IDisposable disposable)
                disposable.Dispose();
        }

        _services.Clear();
        _factories.Clear();
    }
}

// Registration (in game initialization)
public partial class GameBootstrap : Node
{
    public override void _Ready()
    {
        ServiceLocator.Register<ILogger>(new GodotLogger());
        ServiceLocator.Register<IAudioService>(new AudioService());
        ServiceLocator.Register<ISaveService>(new SaveService());
        ServiceLocator.RegisterFactory<IEnemyFactory>(() => new EnemyFactory());
    }

    public override void _ExitTree()
    {
        ServiceLocator.Clear();
    }
}

// Usage
public partial class Player : CharacterBody2D
{
    public override void _Ready()
    {
        var audio = ServiceLocator.Get<IAudioService>();
        audio.PlaySound("player_spawn");
    }
}
```

---

## C# Best Practices for Godot

### Nullable Reference Types

```csharp
// Enable in .csproj
// <Nullable>enable</Nullable>

public partial class Player : CharacterBody2D
{
    // Non-nullable - must be assigned
    [Export]
    public HealthComponent HealthComponent { get; set; } = null!;

    // Nullable - can be null
    public Node2D? CurrentTarget { get; private set; }

    public override void _Ready()
    {
        // Check for required components
        if (HealthComponent is null)
        {
            GD.PushError("HealthComponent not assigned!");
            QueueFree();
            return;
        }
    }

    public void SetTarget(Node2D? target)
    {
        CurrentTarget = target;

        // Safe access with null propagation
        CurrentTarget?.GetNode<Sprite2D>("TargetIndicator")?.Show();
    }

    public float GetDistanceToTarget()
    {
        // Pattern matching with null check
        if (CurrentTarget is { } target)
        {
            return Position.DistanceTo(target.Position);
        }

        return float.MaxValue;
    }
}
```

### Records for Data

```csharp
// Immutable data structures
public record DamageInfo(
    int Amount,
    DamageType Type,
    Node? Source,
    Vector2 HitPoint,
    Vector2 KnockbackDirection
);

public record SaveData(
    string PlayerName,
    int Level,
    int Experience,
    Vector2 LastPosition,
    IReadOnlyList<string> Inventory
);

// Usage
var damage = new DamageInfo(
    Amount: 25,
    Type: DamageType.Physical,
    Source: attacker,
    HitPoint: collision.Position,
    KnockbackDirection: (target.Position - attacker.Position).Normalized()
);

// Records support with-expressions for copying with modifications
var criticalDamage = damage with { Amount = damage.Amount * 2 };
```

### Extension Methods

```csharp
// Extensions/NodeExtensions.cs
public static class NodeExtensions
{
    public static T? GetNodeOrNull<T>(this Node node, string path) where T : class
    {
        return node.GetNodeOrNull(path) as T;
    }

    public static T GetNodeSafe<T>(this Node node, string path) where T : Node
    {
        var child = node.GetNodeOrNull<T>(path);
        if (child is null)
        {
            GD.PushError($"Node '{path}' not found or wrong type");
            throw new InvalidOperationException($"Node '{path}' not found");
        }
        return child;
    }

    public static IEnumerable<T> GetChildrenOfType<T>(this Node node) where T : Node
    {
        foreach (var child in node.GetChildren())
        {
            if (child is T typed)
                yield return typed;
        }
    }

    public static void QueueFreeChildren(this Node node)
    {
        foreach (var child in node.GetChildren())
        {
            child.QueueFree();
        }
    }
}

// Extensions/Vector2Extensions.cs
public static class Vector2Extensions
{
    public static Vector2 RotateToward(this Vector2 from, Vector2 to, float maxAngle)
    {
        var angle = from.AngleTo(to);
        var clampedAngle = Mathf.Clamp(angle, -maxAngle, maxAngle);
        return from.Rotated(clampedAngle);
    }

    public static Vector2 WithX(this Vector2 v, float x) => new(x, v.Y);
    public static Vector2 WithY(this Vector2 v, float y) => new(v.X, y);

    public static bool IsApproximatelyZero(this Vector2 v, float epsilon = 0.001f)
        => v.LengthSquared() < epsilon * epsilon;
}
```

### Async Patterns

```csharp
public partial class DialogueSystem : Node
{
    [Signal]
    public delegate void DialogueFinishedEventHandler();

    public async Task ShowDialogue(string[] lines)
    {
        foreach (var line in lines)
        {
            await ShowLine(line);
            await WaitForInput();
        }

        EmitSignal(SignalName.DialogueFinished);
    }

    private async Task ShowLine(string line)
    {
        var label = GetNode<RichTextLabel>("DialogueLabel");
        label.Text = "";
        label.VisibleCharacters = 0;

        var tween = CreateTween();
        tween.TweenProperty(label, "visible_characters", line.Length, line.Length * 0.05f);

        label.Text = line;
        await ToSignal(tween, Tween.SignalName.Finished);
    }

    private async Task WaitForInput()
    {
        while (!Input.IsActionJustPressed("ui_accept"))
        {
            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        }
    }
}

// Cancellation support
public partial class AsyncLoader : Node
{
    private CancellationTokenSource? _cts;

    public async Task<Resource?> LoadResourceAsync(string path, CancellationToken cancellationToken)
    {
        var loader = ResourceLoader.LoadThreadedRequest(path);

        while (ResourceLoader.LoadThreadedGetStatus(path) == ResourceLoader.ThreadLoadStatus.InProgress)
        {
            if (cancellationToken.IsCancellationRequested)
            {
                return null;
            }

            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        }

        return ResourceLoader.LoadThreadedGet(path);
    }

    public void CancelLoading()
    {
        _cts?.Cancel();
    }
}
```
