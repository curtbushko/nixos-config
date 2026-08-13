---
name: godot-csharp
description: Comprehensive Godot 4 C# game development skill with TDD using GdUnit4/xUnit/NUnit, BDD with Reqnroll/Gherkin feature files, SOLID principles, design patterns (State Machine, Component, Observer, Command), and Godot C# API best practices. Use this skill when building Godot games with C#.
---

# Godot C# Game Development Skill

You are an expert Godot C# game developer who follows Test-Driven Development (TDD) and Behavior-Driven Development (BDD) principles using modern .NET practices.

## Critical Requirements

### Build Quality (NON-NEGOTIABLE)
- **Project MUST build and run without errors**
- Before completing any task, verify:
  - `dotnet build` succeeds with no errors
  - Project runs in Godot editor without errors
  - All unit tests pass (GdUnit4 or xUnit/NUnit)
  - All BDD scenarios pass (if using Reqnroll)
- If any of these fail, fix the issues before marking the task complete
- NEVER leave code in a broken state

### Output and Documentation Standards
- **NEVER use emojis in code, comments, documentation, or any output**
- Keep all communication professional and text-based
- Use Nerd Fonts icons for CLI output if visual indicators are needed

### Test-Driven Development (TDD)
**ALWAYS follow the TDD cycle when implementing new functionality:**

1. **RED**: Write a failing test first
   - Write the test that describes the desired behavior
   - Run tests and confirm it fails for the right reason
   - This validates that the test can actually detect failures

2. **GREEN**: Write minimal code to make the test pass
   - Implement just enough code to make the test pass
   - Don't add extra features or over-engineer
   - Run tests and confirm it passes

3. **REFACTOR**: Improve the code while keeping tests green
   - Clean up the implementation
   - Remove duplication
   - Improve naming and structure
   - Run tests after each refactoring to ensure they still pass

## Project Structure

### Recommended Directory Layout
```
project/
├── addons/                    # Godot addons (GdUnit4, etc.)
├── assets/                    # Raw assets
│   ├── sprites/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── shaders/
├── resources/                 # .tres resource files
│   ├── themes/
│   ├── materials/
│   └── data/
├── scenes/                    # .tscn scene files
│   ├── actors/
│   ├── levels/
│   ├── ui/
│   └── components/
├── scripts/                   # C# source files
│   ├── Autoloads/            # Singleton scripts
│   ├── Components/           # Reusable components
│   ├── Entities/             # Game entities (Player, Enemy, etc.)
│   ├── Resources/            # Custom Resource classes
│   ├── States/               # State machine states
│   ├── Systems/              # Game systems (Input, Audio, etc.)
│   └── Utils/                # Utility classes
├── tests/                     # Test projects
│   ├── Unit/                 # Unit tests (xUnit/NUnit/GdUnit4)
│   ├── Integration/          # Integration tests
│   ├── Features/             # BDD feature files (.feature)
│   └── StepDefinitions/      # Reqnroll step definitions
├── project.godot
├── MyGame.csproj
├── MyGame.Tests.csproj       # Test project
└── MyGame.sln
```

### File Naming Conventions
- Scenes: `PascalCase.tscn` (e.g., `PlayerCharacter.tscn`)
- Scripts: `PascalCase.cs` (e.g., `PlayerController.cs`)
- Resources: `PascalCase.tres` (e.g., `PlayerStats.tres`)
- Tests: `<ClassName>Tests.cs` (e.g., `PlayerControllerTests.cs`)
- Feature files: `<Feature>.feature` (e.g., `PlayerMovement.feature`)
- Step definitions: `<Feature>Steps.cs` (e.g., `PlayerMovementSteps.cs`)

## Testing Frameworks

### Option 1: GdUnit4 (Recommended for Godot-Specific Testing)

GdUnit4 is an embedded unit testing framework for Godot 4 supporting C#.

**Installation:**
```xml
<!-- In your .csproj -->
<ItemGroup>
  <PackageReference Include="gdUnit4.api" Version="4.*" />
</ItemGroup>
```

**Test Structure:**
```csharp
using GdUnit4;
using static GdUnit4.Assertions;

namespace MyGame.Tests;

[TestSuite]
public class HealthComponentTests
{
    private HealthComponent _healthComponent = null!;

    [Before]
    public void Setup()
    {
        _healthComponent = new HealthComponent();
    }

    [After]
    public void Teardown()
    {
        _healthComponent?.Free();
    }

    [TestCase]
    public void InitialHealth_ShouldEqualMaxHealth()
    {
        // Arrange
        _healthComponent.MaxHealth = 100;

        // Act
        _healthComponent._Ready();

        // Assert
        AssertThat(_healthComponent.Health).IsEqual(100);
    }

    [TestCase]
    public void TakeDamage_ShouldReduceHealth()
    {
        // Arrange
        _healthComponent.MaxHealth = 100;
        _healthComponent._Ready();

        // Act
        _healthComponent.TakeDamage(25);

        // Assert
        AssertThat(_healthComponent.Health).IsEqual(75);
    }

    [TestCase]
    public void TakeDamage_ShouldEmitHealthChangedSignal()
    {
        // Arrange
        _healthComponent.MaxHealth = 100;
        _healthComponent._Ready();
        var monitor = _healthComponent.MonitorSignal("HealthChanged");

        // Act
        _healthComponent.TakeDamage(10);

        // Assert
        AssertThat(monitor).IsEmitted();
    }
}
```

### Option 2: xUnit/NUnit (For Logic-Only Testing)

Use standard .NET testing frameworks for non-Godot-specific logic.

**Installation:**
```xml
<!-- MyGame.Tests.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="xunit" Version="2.*" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.*" />
    <PackageReference Include="FluentAssertions" Version="6.*" />
    <PackageReference Include="NSubstitute" Version="5.*" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\MyGame.csproj" />
  </ItemGroup>
</Project>
```

**Test Structure:**
```csharp
using FluentAssertions;
using NSubstitute;
using Xunit;

namespace MyGame.Tests;

public class DamageCalculatorTests
{
    [Fact]
    public void CalculateDamage_WithNoArmor_ReturnsFullDamage()
    {
        // Arrange
        var calculator = new DamageCalculator();
        var baseDamage = 100;
        var armor = 0;

        // Act
        var result = calculator.Calculate(baseDamage, armor);

        // Assert
        result.Should().Be(100);
    }

    [Theory]
    [InlineData(100, 0, 100)]
    [InlineData(100, 50, 50)]
    [InlineData(100, 100, 1)]  // Minimum 1 damage
    public void CalculateDamage_WithArmor_ReducesDamageCorrectly(
        int baseDamage, int armor, int expected)
    {
        // Arrange
        var calculator = new DamageCalculator();

        // Act
        var result = calculator.Calculate(baseDamage, armor);

        // Assert
        result.Should().Be(expected);
    }
}
```

### Option 3: Chickensoft GoDotTest (Integrated Testing)

For tests that need to run within Godot's runtime.

**Installation:**
```xml
<ItemGroup>
  <PackageReference Include="Chickensoft.GoDotTest" Version="2.*" />
</ItemGroup>
```

**Test Structure:**
```csharp
using Chickensoft.GoDotTest;
using Godot;
using Shouldly;

namespace MyGame.Tests;

public class PlayerTests : TestClass
{
    private Player _player = null!;

    public PlayerTests(Node testScene) : base(testScene) { }

    [Setup]
    public void Setup()
    {
        _player = new Player();
        TestScene.AddChild(_player);
    }

    [Cleanup]
    public void Cleanup()
    {
        _player.QueueFree();
    }

    [Test]
    public void Player_ShouldMoveRight_WhenInputPressed()
    {
        // Arrange
        var initialPosition = _player.Position;
        Input.ActionPress("move_right");

        // Act
        _player._PhysicsProcess(0.016); // Simulate one frame

        // Assert
        _player.Position.X.ShouldBeGreaterThan(initialPosition.X);

        // Cleanup
        Input.ActionRelease("move_right");
    }
}
```

## BDD with Reqnroll

### Installation

```xml
<!-- MyGame.Tests.csproj -->
<ItemGroup>
  <PackageReference Include="Reqnroll" Version="2.*" />
  <PackageReference Include="Reqnroll.xUnit" Version="2.*" />
</ItemGroup>
```

### Feature File Structure
```gherkin
# tests/Features/PlayerHealth.feature
Feature: Player Health System
    As a player
    I want to have a health system
    So that I can take damage and die

    Background:
        Given a player with 100 max health

    Scenario: Player takes damage
        When the player takes 25 damage
        Then the player health should be 75

    Scenario: Player cannot have negative health
        When the player takes 9999 damage
        Then the player health should be 0
        And the player should be dead

    Scenario: Player heals after taking damage
        Given the player has taken 50 damage
        When the player heals 30 health
        Then the player health should be 80

    Scenario Outline: Damage calculation with armor
        Given the player has <armor> armor
        When the player takes <damage> raw damage
        Then the player should receive <actual> damage

        Examples:
            | armor | damage | actual |
            | 0     | 100    | 100    |
            | 50    | 100    | 50     |
            | 100   | 100    | 1      |
```

### Step Definitions
```csharp
// tests/StepDefinitions/PlayerHealthSteps.cs
using Reqnroll;
using FluentAssertions;

namespace MyGame.Tests.StepDefinitions;

[Binding]
public class PlayerHealthSteps
{
    private HealthComponent _healthComponent = null!;
    private int _lastDamageReceived;

    [Given(@"a player with (\d+) max health")]
    public void GivenAPlayerWithMaxHealth(int maxHealth)
    {
        _healthComponent = new HealthComponent
        {
            MaxHealth = maxHealth
        };
        _healthComponent._Ready();
    }

    [Given(@"the player has (\d+) armor")]
    public void GivenThePlayerHasArmor(int armor)
    {
        _healthComponent.Armor = armor;
    }

    [Given(@"the player has taken (\d+) damage")]
    public void GivenThePlayerHasTakenDamage(int damage)
    {
        _healthComponent.TakeDamage(damage);
    }

    [When(@"the player takes (\d+) damage")]
    public void WhenThePlayerTakesDamage(int damage)
    {
        _healthComponent.TakeDamage(damage);
    }

    [When(@"the player takes (\d+) raw damage")]
    public void WhenThePlayerTakesRawDamage(int damage)
    {
        _lastDamageReceived = _healthComponent.CalculateDamage(damage);
        _healthComponent.TakeDamage(_lastDamageReceived);
    }

    [When(@"the player heals (\d+) health")]
    public void WhenThePlayerHealsHealth(int amount)
    {
        _healthComponent.Heal(amount);
    }

    [Then(@"the player health should be (\d+)")]
    public void ThenThePlayerHealthShouldBe(int expected)
    {
        _healthComponent.Health.Should().Be(expected);
    }

    [Then(@"the player should be dead")]
    public void ThenThePlayerShouldBeDead()
    {
        _healthComponent.IsDead.Should().BeTrue();
    }

    [Then(@"the player should receive (\d+) damage")]
    public void ThenThePlayerShouldReceiveDamage(int expected)
    {
        _lastDamageReceived.Should().Be(expected);
    }
}
```

### Hooks for Test Lifecycle
```csharp
// tests/StepDefinitions/Hooks.cs
using Reqnroll;

namespace MyGame.Tests.StepDefinitions;

[Binding]
public class Hooks
{
    [BeforeScenario]
    public void BeforeScenario(ScenarioContext context)
    {
        // Setup before each scenario
    }

    [AfterScenario]
    public void AfterScenario(ScenarioContext context)
    {
        // Cleanup after each scenario
    }

    [BeforeFeature]
    public static void BeforeFeature(FeatureContext context)
    {
        // Setup before each feature
    }

    [AfterFeature]
    public static void AfterFeature(FeatureContext context)
    {
        // Cleanup after each feature
    }
}
```

## C# Godot Best Practices

### Node References
```csharp
public partial class Player : CharacterBody2D
{
    // Use [Export] for editor-configurable references
    [Export] public HealthComponent? HealthComponent { get; set; }
    [Export] public Sprite2D? Sprite { get; set; }

    // Cache node references in _Ready
    private AnimationPlayer _animationPlayer = null!;
    private StateMachine _stateMachine = null!;

    public override void _Ready()
    {
        _animationPlayer = GetNode<AnimationPlayer>("AnimationPlayer");
        _stateMachine = GetNode<StateMachine>("StateMachine");

        // Null check exports
        if (HealthComponent is null)
            GD.PushError("HealthComponent not assigned!");
    }
}
```

### Signals (C# Style)
```csharp
public partial class HealthComponent : Node
{
    // Signal definitions using delegates
    [Signal]
    public delegate void HealthChangedEventHandler(int newHealth, int maxHealth);

    [Signal]
    public delegate void DamagedEventHandler(int amount, Node? source);

    [Signal]
    public delegate void DiedEventHandler();

    private int _health;
    public int Health
    {
        get => _health;
        private set
        {
            var oldHealth = _health;
            _health = Math.Clamp(value, 0, MaxHealth);

            if (_health != oldHealth)
            {
                EmitSignal(SignalName.HealthChanged, _health, MaxHealth);
            }

            if (_health <= 0 && oldHealth > 0)
            {
                EmitSignal(SignalName.Died);
            }
        }
    }

    [Export]
    public int MaxHealth { get; set; } = 100;

    public bool IsDead => Health <= 0;

    public override void _Ready()
    {
        Health = MaxHealth;
    }

    public void TakeDamage(int amount, Node? source = null)
    {
        if (IsDead) return;

        Health -= amount;
        EmitSignal(SignalName.Damaged, amount, source);
    }

    public void Heal(int amount)
    {
        if (IsDead) return;
        Health += amount;
    }
}
```

### Signal Connections
```csharp
public override void _Ready()
{
    // Connect to signals using C# events
    HealthComponent.HealthChanged += OnHealthChanged;
    HealthComponent.Died += OnDied;

    // Or using Godot's Connect method
    HealthComponent.Connect(
        HealthComponent.SignalName.HealthChanged,
        Callable.From<int, int>(OnHealthChanged)
    );
}

public override void _ExitTree()
{
    // Disconnect signals
    HealthComponent.HealthChanged -= OnHealthChanged;
    HealthComponent.Died -= OnDied;
}

private void OnHealthChanged(int newHealth, int maxHealth)
{
    GD.Print($"Health: {newHealth}/{maxHealth}");
}

private void OnDied()
{
    GD.Print("Player died!");
}
```

### Async/Await with Godot
```csharp
public async Task PlayAttackAnimation()
{
    _animationPlayer.Play("attack");

    // Wait for animation to finish
    await ToSignal(_animationPlayer, AnimationPlayer.SignalName.AnimationFinished);

    _animationPlayer.Play("idle");
}

public async Task WaitForSeconds(double seconds)
{
    await ToSignal(
        GetTree().CreateTimer(seconds),
        SceneTreeTimer.SignalName.Timeout
    );
}

public async Task FadeOut(float duration)
{
    var tween = CreateTween();
    tween.TweenProperty(this, "modulate:a", 0f, duration);
    await ToSignal(tween, Tween.SignalName.Finished);
}
```

### Properties vs Fields
```csharp
public partial class Enemy : CharacterBody2D
{
    // Use [Export] for editor-visible properties
    [Export]
    public float MoveSpeed { get; set; } = 100f;

    [Export]
    public int Damage { get; set; } = 10;

    // Private fields with underscore prefix
    private Vector2 _targetPosition;
    private bool _isChasing;

    // Read-only computed properties
    public bool IsMoving => Velocity.LengthSquared() > 0.01f;
    public float DistanceToTarget => Position.DistanceTo(_targetPosition);
}
```

## Design Patterns

### State Machine Pattern
```csharp
// States/IState.cs
public interface IState
{
    void Enter();
    void Exit();
    void Update(double delta);
    void PhysicsUpdate(double delta);
    void HandleInput(InputEvent @event);
}

// States/StateMachine.cs
public partial class StateMachine : Node
{
    [Signal]
    public delegate void StateChangedEventHandler(IState? oldState, IState newState);

    [Export]
    public NodePath? InitialStatePath { get; set; }

    public IState? CurrentState { get; private set; }

    private Dictionary<string, IState> _states = new();

    public override void _Ready()
    {
        foreach (var child in GetChildren())
        {
            if (child is IState state)
            {
                _states[child.Name.ToString().ToLower()] = state;
            }
        }

        if (InitialStatePath is not null)
        {
            var initialState = GetNode<Node>(InitialStatePath);
            if (initialState is IState state)
            {
                TransitionTo(initialState.Name);
            }
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

    public void TransitionTo(string stateName)
    {
        var key = stateName.ToLower();
        if (!_states.TryGetValue(key, out var newState))
        {
            GD.PushError($"State '{stateName}' not found");
            return;
        }

        var oldState = CurrentState;
        CurrentState?.Exit();
        CurrentState = newState;
        CurrentState.Enter();

        EmitSignal(SignalName.StateChanged, oldState, newState);
    }
}

// States/PlayerIdleState.cs
public partial class PlayerIdleState : Node, IState
{
    [Export]
    public CharacterBody2D? Actor { get; set; }

    [Export]
    public AnimatedSprite2D? AnimatedSprite { get; set; }

    private StateMachine _stateMachine = null!;

    public override void _Ready()
    {
        _stateMachine = GetParent<StateMachine>();
    }

    public void Enter()
    {
        AnimatedSprite?.Play("idle");
    }

    public void Exit() { }

    public void Update(double delta) { }

    public void PhysicsUpdate(double delta)
    {
        var direction = Input.GetAxis("move_left", "move_right");
        if (Math.Abs(direction) > 0.1f)
        {
            _stateMachine.TransitionTo("Run");
        }

        if (Input.IsActionJustPressed("jump"))
        {
            _stateMachine.TransitionTo("Jump");
        }
    }

    public void HandleInput(InputEvent @event) { }
}
```

### Component Pattern
```csharp
// Components/HealthComponent.cs
public partial class HealthComponent : Node
{
    [Signal]
    public delegate void HealthChangedEventHandler(int newHealth, int maxHealth);

    [Signal]
    public delegate void DiedEventHandler();

    [Export]
    public int MaxHealth { get; set; } = 100;

    [Export]
    public float InvincibilityDuration { get; set; } = 0f;

    public int Health { get; private set; }
    public bool IsInvincible { get; private set; }
    public bool IsDead => Health <= 0;

    public override void _Ready()
    {
        Health = MaxHealth;
    }

    public void TakeDamage(int amount, Node? source = null)
    {
        if (IsInvincible || IsDead) return;

        Health = Math.Max(0, Health - amount);
        EmitSignal(SignalName.HealthChanged, Health, MaxHealth);

        if (IsDead)
        {
            EmitSignal(SignalName.Died);
        }
        else if (InvincibilityDuration > 0)
        {
            StartInvincibility();
        }
    }

    public void Heal(int amount)
    {
        if (IsDead) return;

        Health = Math.Min(MaxHealth, Health + amount);
        EmitSignal(SignalName.HealthChanged, Health, MaxHealth);
    }

    private async void StartInvincibility()
    {
        IsInvincible = true;
        await ToSignal(
            GetTree().CreateTimer(InvincibilityDuration),
            SceneTreeTimer.SignalName.Timeout
        );
        IsInvincible = false;
    }
}

// Components/HitboxComponent.cs
public partial class HitboxComponent : Area2D
{
    [Signal]
    public delegate void HitEventHandler(HurtboxComponent hurtbox);

    [Export]
    public int Damage { get; set; } = 10;

    [Export]
    public float KnockbackForce { get; set; } = 200f;

    public override void _Ready()
    {
        AreaEntered += OnAreaEntered;
    }

    private void OnAreaEntered(Area2D area)
    {
        if (area is HurtboxComponent hurtbox)
        {
            hurtbox.ReceiveHit(this);
            EmitSignal(SignalName.Hit, hurtbox);
        }
    }
}

// Components/HurtboxComponent.cs
public partial class HurtboxComponent : Area2D
{
    [Signal]
    public delegate void HurtEventHandler(HitboxComponent hitbox);

    [Export]
    public HealthComponent? HealthComponent { get; set; }

    public void ReceiveHit(HitboxComponent hitbox)
    {
        HealthComponent?.TakeDamage(hitbox.Damage, hitbox.Owner);
        EmitSignal(SignalName.Hurt, hitbox);
    }
}
```

### Observer Pattern (Event Bus)
```csharp
// Autoloads/Events.cs
public partial class Events : Node
{
    // Singleton instance
    public static Events Instance { get; private set; } = null!;

    // Player events
    [Signal]
    public delegate void PlayerSpawnedEventHandler(Node player);

    [Signal]
    public delegate void PlayerDiedEventHandler(Node player);

    [Signal]
    public delegate void PlayerHealthChangedEventHandler(int health, int maxHealth);

    // Game events
    [Signal]
    public delegate void LevelStartedEventHandler(string levelName);

    [Signal]
    public delegate void LevelCompletedEventHandler(string levelName);

    [Signal]
    public delegate void GamePausedEventHandler();

    [Signal]
    public delegate void GameResumedEventHandler();

    // Economy events
    [Signal]
    public delegate void CoinsChangedEventHandler(int newAmount);

    public override void _Ready()
    {
        Instance = this;
    }
}

// Usage in Player.cs
public override void _Ready()
{
    Events.Instance.EmitSignal(Events.SignalName.PlayerSpawned, this);
}

// Usage in UI
public override void _Ready()
{
    Events.Instance.PlayerHealthChanged += OnPlayerHealthChanged;
    Events.Instance.PlayerDied += OnPlayerDied;
}

public override void _ExitTree()
{
    Events.Instance.PlayerHealthChanged -= OnPlayerHealthChanged;
    Events.Instance.PlayerDied -= OnPlayerDied;
}
```

### Command Pattern
```csharp
// Commands/ICommand.cs
public interface ICommand
{
    void Execute();
    void Undo();
}

// Commands/MoveCommand.cs
public class MoveCommand : ICommand
{
    private readonly Node2D _actor;
    private readonly Vector2 _direction;
    private readonly float _distance;

    public MoveCommand(Node2D actor, Vector2 direction, float distance)
    {
        _actor = actor;
        _direction = direction;
        _distance = distance;
    }

    public void Execute()
    {
        _actor.Position += _direction * _distance;
    }

    public void Undo()
    {
        _actor.Position -= _direction * _distance;
    }
}

// Commands/CommandHistory.cs
public class CommandHistory
{
    private readonly List<ICommand> _history = new();
    private int _currentIndex = -1;

    public void Execute(ICommand command)
    {
        // Remove any commands after current index
        if (_currentIndex < _history.Count - 1)
        {
            _history.RemoveRange(_currentIndex + 1, _history.Count - _currentIndex - 1);
        }

        command.Execute();
        _history.Add(command);
        _currentIndex++;
    }

    public bool Undo()
    {
        if (_currentIndex < 0) return false;

        _history[_currentIndex].Undo();
        _currentIndex--;
        return true;
    }

    public bool Redo()
    {
        if (_currentIndex >= _history.Count - 1) return false;

        _currentIndex++;
        _history[_currentIndex].Execute();
        return true;
    }
}
```

### Object Pool Pattern
```csharp
// Systems/ObjectPool.cs
public partial class ObjectPool<T> : Node where T : Node
{
    private readonly PackedScene _scene;
    private readonly Queue<T> _available = new();
    private readonly HashSet<T> _inUse = new();
    private readonly int _initialSize;
    private readonly bool _canGrow;

    public ObjectPool(PackedScene scene, int initialSize = 20, bool canGrow = true)
    {
        _scene = scene;
        _initialSize = initialSize;
        _canGrow = canGrow;
    }

    public override void _Ready()
    {
        for (int i = 0; i < _initialSize; i++)
        {
            CreateInstance();
        }
    }

    private T CreateInstance()
    {
        var instance = _scene.Instantiate<T>();
        instance.SetProcess(false);
        instance.SetPhysicsProcess(false);

        if (instance is Node2D node2D)
            node2D.Visible = false;
        else if (instance is Node3D node3D)
            node3D.Visible = false;

        AddChild(instance);
        _available.Enqueue(instance);
        return instance;
    }

    public T? Acquire()
    {
        T instance;

        if (_available.Count == 0)
        {
            if (_canGrow)
            {
                instance = CreateInstance();
                _available.Dequeue(); // Remove from available since we just added it
            }
            else
            {
                GD.PushWarning("Object pool exhausted");
                return null;
            }
        }
        else
        {
            instance = _available.Dequeue();
        }

        _inUse.Add(instance);
        instance.SetProcess(true);
        instance.SetPhysicsProcess(true);

        if (instance is Node2D node2D)
            node2D.Visible = true;
        else if (instance is Node3D node3D)
            node3D.Visible = true;

        if (instance is IPoolable poolable)
            poolable.OnAcquire();

        return instance;
    }

    public void Release(T instance)
    {
        if (!_inUse.Contains(instance))
        {
            GD.PushWarning("Trying to release instance not from this pool");
            return;
        }

        if (instance is IPoolable poolable)
            poolable.OnRelease();

        instance.SetProcess(false);
        instance.SetPhysicsProcess(false);

        if (instance is Node2D node2D)
            node2D.Visible = false;
        else if (instance is Node3D node3D)
            node3D.Visible = false;

        _inUse.Remove(instance);
        _available.Enqueue(instance);
    }
}

public interface IPoolable
{
    void OnAcquire();
    void OnRelease();
}
```

## Running Tests

### GdUnit4
```bash
# Run all tests from command line
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --run-all

# Run specific test suite
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --run=res://tests/Unit/HealthComponentTests.cs
```

### xUnit/NUnit
```bash
# Run all tests
dotnet test

# Run with verbosity
dotnet test --verbosity normal

# Run specific test class
dotnet test --filter "FullyQualifiedName~HealthComponentTests"

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"
```

### Reqnroll BDD
```bash
# Run BDD tests (they use the underlying test framework)
dotnet test --filter "Category=BDD"

# Generate living documentation
dotnet reqnroll livingdoc test-assembly MyGame.Tests.dll -t TestExecution.json
```

## Code Review Checklist

- [ ] Project builds without errors (`dotnet build`)
- [ ] Project runs in Godot editor without errors
- [ ] All unit tests pass
- [ ] All BDD scenarios pass
- [ ] Code follows TDD (tests written first)
- [ ] Nullable reference types handled properly
- [ ] Signals properly connected and disconnected
- [ ] Node references cached where appropriate
- [ ] No hardcoded magic numbers (use constants/exports)
- [ ] Components are reusable and single-responsibility
- [ ] SOLID principles followed
- [ ] No emojis in code, comments, or documentation
- [ ] Async operations properly awaited
- [ ] Resources used for data-driven design

## Quick Reference

| Pattern | Use When |
|---------|----------|
| State Machine | Complex behavior with distinct states |
| Component | Reusable behavior across actors |
| Observer (Events) | Decoupled communication |
| Command | Undo/redo, input buffering, replays |
| Object Pool | Frequently spawned/despawned objects |

| Do | Don't |
|----|-------|
| Use nullable reference types | Ignore null warnings |
| Cache node references | Call GetNode<T>() every frame |
| Use signals for communication | Direct method calls across scenes |
| Use Resources for data | Hardcode game data in scripts |
| Write tests first (TDD) | Write tests after (or never) |
| Use [Export] for editor values | Hardcode values |
| Properly disconnect signals | Leave signal connections |

## Additional Resources

### Reference Documentation (in this skill)
- `references/testing-patterns.md` - GdUnit4, xUnit, Reqnroll patterns
- `references/csharp-patterns.md` - C# design patterns and SOLID principles
- `references/godot-csharp-api.md` - Godot C# API reference and differences

### External Resources
- [Godot C# Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/index.html)
- [Godot C# API Differences](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_differences.html)
- [GdUnit4 Documentation](https://godot-gdunit-labs.github.io/gdUnit4/latest/)
- [GdUnit4Net GitHub](https://github.com/MikeSchulze/gdUnit4Net)
- [Chickensoft](https://chickensoft.games/)
- [Reqnroll Documentation](https://docs.reqnroll.net/latest/)
- [xUnit Documentation](https://xunit.net/)
- [FluentAssertions](https://fluentassertions.com/)
