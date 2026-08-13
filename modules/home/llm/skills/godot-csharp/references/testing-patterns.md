# C# Testing Patterns for Godot

## TDD Cycle: Investigate -> Plan -> Test -> Implement -> Validate -> Finalize

### Phase 1: Investigate

Before writing any code, understand the requirement:

```csharp
// Questions to answer:
// 1. What is the expected behavior?
// 2. What signals should be emitted?
// 3. What state changes occur?
// 4. What are the edge cases?
// 5. What dependencies exist?

// Document findings as comments or in a feature file
// Feature: Player Health System
//
// Acceptance Criteria:
// - Health starts at max_health value
// - Taking damage reduces health
// - Health cannot go below 0
// - Signal emitted when health changes
// - Signal emitted when player dies
// - Invincibility frames after taking damage
```

### Phase 2: Plan

Design the interface before implementation:

```csharp
// Interface planning - just the signatures
// IHealthComponent:
//   - int Health { get; }
//   - int MaxHealth { get; set; }
//   - bool IsInvincible { get; }
//   - bool IsDead { get; }
//   - void TakeDamage(int amount, Node? source = null)
//   - void Heal(int amount)
//   - event HealthChangedEventHandler HealthChanged
//   - event DamagedEventHandler Damaged
//   - event DiedEventHandler Died
```

### Phase 3: Test (RED)

Write failing tests following AAA pattern.

---

## GdUnit4 Testing Patterns

### Basic Test Structure

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
        _healthComponent = new HealthComponent
        {
            MaxHealth = 100
        };
    }

    [After]
    public void Teardown()
    {
        _healthComponent?.Free();
    }

    [TestCase]
    public void InitialHealth_ShouldEqualMaxHealth()
    {
        // Arrange - done in Setup

        // Act
        _healthComponent._Ready();

        // Assert
        AssertThat(_healthComponent.Health).IsEqual(100);
    }

    [TestCase]
    public void TakeDamage_WithValidAmount_ShouldReduceHealth()
    {
        // Arrange
        _healthComponent._Ready();

        // Act
        _healthComponent.TakeDamage(25);

        // Assert
        AssertThat(_healthComponent.Health).IsEqual(75);
    }

    [TestCase]
    public void TakeDamage_WithExcessiveDamage_ShouldClampToZero()
    {
        // Arrange
        _healthComponent._Ready();

        // Act
        _healthComponent.TakeDamage(9999);

        // Assert
        AssertThat(_healthComponent.Health).IsEqual(0);
        AssertThat(_healthComponent.IsDead).IsTrue();
    }
}
```

### Testing Signals

```csharp
[TestCase]
public void TakeDamage_ShouldEmitHealthChangedSignal()
{
    // Arrange
    _healthComponent._Ready();
    var monitor = _healthComponent.MonitorSignal("HealthChanged");

    // Act
    _healthComponent.TakeDamage(10);

    // Assert
    AssertThat(monitor).IsEmitted();
}

[TestCase]
public void TakeDamage_WhenHealthReachesZero_ShouldEmitDiedSignal()
{
    // Arrange
    _healthComponent._Ready();
    var monitor = _healthComponent.MonitorSignal("Died");

    // Act
    _healthComponent.TakeDamage(100);

    // Assert
    AssertThat(monitor).IsEmitted();
    AssertThat(monitor).EmitCount(1);
}

[TestCase]
public void TakeDamage_WhenAlreadyDead_ShouldNotEmitDiedAgain()
{
    // Arrange
    _healthComponent._Ready();
    _healthComponent.TakeDamage(100); // Kill once
    var monitor = _healthComponent.MonitorSignal("Died");

    // Act
    _healthComponent.TakeDamage(50); // Try to kill again

    // Assert
    AssertThat(monitor).EmitCount(0);
}
```

### Testing with Scene Runner

```csharp
using GdUnit4;
using static GdUnit4.Assertions;

[TestSuite]
public class PlayerIntegrationTests
{
    [TestCase]
    public async Task Player_WhenMovingRight_ShouldChangePosition()
    {
        // Arrange
        var scene = await ISceneRunner.Load("res://scenes/actors/Player.tscn");
        var player = scene.Scene() as CharacterBody2D;
        var initialX = player!.Position.X;

        // Act
        scene.SimulateKeyPress(Key.Right);
        await scene.SimulateFrames(10);
        scene.SimulateKeyRelease(Key.Right);

        // Assert
        AssertThat(player.Position.X).IsGreater(initialX);

        // Cleanup
        scene.Free();
    }

    [TestCase]
    public async Task Player_WhenTakingDamage_ShouldShowDamageAnimation()
    {
        // Arrange
        var scene = await ISceneRunner.Load("res://scenes/actors/Player.tscn");
        var player = scene.Scene() as Player;
        var animPlayer = player!.GetNode<AnimationPlayer>("AnimationPlayer");

        // Act
        player.HealthComponent.TakeDamage(10);
        await scene.SimulateFrames(1);

        // Assert
        AssertThat(animPlayer.CurrentAnimation).IsEqual("damage");

        // Cleanup
        scene.Free();
    }
}
```

### Parameterized Tests

```csharp
[TestCase(100, 0, 100)]
[TestCase(100, 50, 50)]
[TestCase(100, 100, 1)]    // Minimum 1 damage
[TestCase(50, 25, 25)]
public void CalculateDamage_WithArmor_ShouldReduceDamage(
    int baseDamage, int armor, int expected)
{
    // Arrange
    var calculator = new DamageCalculator();

    // Act
    var result = calculator.Calculate(baseDamage, armor);

    // Assert
    AssertThat(result).IsEqual(expected);
}
```

### Testing Async Operations

```csharp
[TestCase]
public async Task Heal_WithCooldown_ShouldWaitBeforeHealing()
{
    // Arrange
    _healthComponent._Ready();
    _healthComponent.TakeDamage(50);
    _healthComponent.HealCooldown = 0.5f;

    // Act
    _healthComponent.StartHealOverTime(10);

    // Assert - not healed immediately
    AssertThat(_healthComponent.Health).IsEqual(50);

    // Wait for cooldown
    await Task.Delay(TimeSpan.FromSeconds(0.6));

    // Assert - healed after cooldown
    AssertThat(_healthComponent.Health).IsEqual(60);
}
```

---

## xUnit Testing Patterns

### Basic Test Structure

```csharp
using FluentAssertions;
using Xunit;

namespace MyGame.Tests;

public class DamageCalculatorTests
{
    [Fact]
    public void Calculate_WithNoArmor_ReturnsFullDamage()
    {
        // Arrange
        var calculator = new DamageCalculator();

        // Act
        var result = calculator.Calculate(100, 0);

        // Assert
        result.Should().Be(100);
    }

    [Fact]
    public void Calculate_WithNegativeDamage_ThrowsArgumentException()
    {
        // Arrange
        var calculator = new DamageCalculator();

        // Act
        var action = () => calculator.Calculate(-10, 0);

        // Assert
        action.Should().Throw<ArgumentException>()
            .WithMessage("*negative*");
    }
}
```

### Theory Tests (Parameterized)

```csharp
public class DamageCalculatorTheoryTests
{
    [Theory]
    [InlineData(100, 0, 100)]
    [InlineData(100, 50, 50)]
    [InlineData(100, 100, 1)]
    [InlineData(100, 150, 1)]  // Armor > damage still results in minimum
    public void Calculate_WithVariousArmor_ReturnsCorrectDamage(
        int baseDamage, int armor, int expected)
    {
        // Arrange
        var calculator = new DamageCalculator();

        // Act
        var result = calculator.Calculate(baseDamage, armor);

        // Assert
        result.Should().Be(expected);
    }

    [Theory]
    [MemberData(nameof(DamageTestCases))]
    public void Calculate_WithTestCases_ReturnsExpected(DamageTestCase testCase)
    {
        // Arrange
        var calculator = new DamageCalculator();

        // Act
        var result = calculator.Calculate(testCase.BaseDamage, testCase.Armor);

        // Assert
        result.Should().Be(testCase.Expected, testCase.Description);
    }

    public static IEnumerable<object[]> DamageTestCases => new List<object[]>
    {
        new object[] { new DamageTestCase(100, 0, 100, "No armor") },
        new object[] { new DamageTestCase(100, 50, 50, "Half armor") },
        new object[] { new DamageTestCase(100, 100, 1, "Full armor") },
    };

    public record DamageTestCase(int BaseDamage, int Armor, int Expected, string Description);
}
```

### Mocking with NSubstitute

```csharp
using NSubstitute;
using FluentAssertions;
using Xunit;

public class EnemyAITests
{
    [Fact]
    public void Update_WhenPlayerInRange_ShouldChase()
    {
        // Arrange
        var navigator = Substitute.For<INavigator>();
        var targetFinder = Substitute.For<ITargetFinder>();
        var player = new MockNode2D { Position = new Vector2(100, 100) };

        targetFinder.FindNearestPlayer().Returns(player);
        navigator.IsInRange(Arg.Any<Vector2>(), Arg.Any<float>()).Returns(true);

        var ai = new EnemyAI(navigator, targetFinder);

        // Act
        ai.Update(0.016);

        // Assert
        navigator.Received(1).SetTarget(player.Position);
        ai.CurrentState.Should().Be(EnemyState.Chasing);
    }

    [Fact]
    public void Update_WhenPlayerOutOfRange_ShouldPatrol()
    {
        // Arrange
        var navigator = Substitute.For<INavigator>();
        var targetFinder = Substitute.For<ITargetFinder>();

        targetFinder.FindNearestPlayer().Returns((Node2D?)null);

        var ai = new EnemyAI(navigator, targetFinder);

        // Act
        ai.Update(0.016);

        // Assert
        navigator.DidNotReceive().SetTarget(Arg.Any<Vector2>());
        ai.CurrentState.Should().Be(EnemyState.Patrolling);
    }
}
```

### Testing Events

```csharp
public class HealthComponentEventTests
{
    [Fact]
    public void TakeDamage_ShouldRaiseHealthChangedEvent()
    {
        // Arrange
        var component = new HealthComponent { MaxHealth = 100 };
        component.Initialize();

        using var monitor = component.Monitor();

        // Act
        component.TakeDamage(25);

        // Assert
        monitor.Should().Raise("HealthChanged")
            .WithArgs<HealthChangedEventArgs>(args =>
                args.NewHealth == 75 && args.MaxHealth == 100);
    }
}
```

### Async Tests

```csharp
public class AsyncOperationTests
{
    [Fact]
    public async Task LoadLevel_ShouldCompleteWithinTimeout()
    {
        // Arrange
        var loader = new LevelLoader();

        // Act
        var level = await loader.LoadAsync("level_01");

        // Assert
        level.Should().NotBeNull();
        level.Name.Should().Be("level_01");
    }

    [Fact]
    public async Task SaveGame_WhenDiskFull_ShouldThrowIOException()
    {
        // Arrange
        var saveManager = new SaveManager(new MockDiskFull());

        // Act
        var action = () => saveManager.SaveAsync(new GameState());

        // Assert
        await action.Should().ThrowAsync<IOException>();
    }
}
```

---

## Reqnroll BDD Patterns

### Feature File Best Practices

```gherkin
# features/Combat/DamageCalculation.feature

@combat @damage
Feature: Damage Calculation
    As a game designer
    I want damage to be calculated based on armor
    So that defensive stats are meaningful

    Background:
        Given the damage calculator is initialized

    @smoke
    Scenario: Basic damage without armor
        When I calculate damage for 100 base damage with 0 armor
        Then the result should be 100

    Scenario: Damage reduced by armor
        When I calculate damage for 100 base damage with 50 armor
        Then the result should be 50

    Scenario: Minimum damage with high armor
        Given the minimum damage is set to 1
        When I calculate damage for 100 base damage with 100 armor
        Then the result should be 1

    Scenario Outline: Various damage and armor combinations
        When I calculate damage for <base> base damage with <armor> armor
        Then the result should be <expected>

        Examples:
            | base | armor | expected | description     |
            | 100  | 0     | 100      | No armor       |
            | 100  | 25    | 75       | Light armor    |
            | 100  | 50    | 50       | Medium armor   |
            | 100  | 75    | 25       | Heavy armor    |
            | 100  | 100   | 1        | Full armor     |

    @critical
    Scenario: Critical hits ignore armor
        Given the attacker has critical strike
        When I calculate damage for 100 base damage with 50 armor
        Then the result should be 150
```

### Step Definitions

```csharp
// StepDefinitions/DamageCalculationSteps.cs
using Reqnroll;
using FluentAssertions;

namespace MyGame.Tests.StepDefinitions;

[Binding]
public class DamageCalculationSteps
{
    private DamageCalculator _calculator = null!;
    private int _result;
    private bool _hasCritical;

    [Given(@"the damage calculator is initialized")]
    public void GivenTheDamageCalculatorIsInitialized()
    {
        _calculator = new DamageCalculator();
    }

    [Given(@"the minimum damage is set to (\d+)")]
    public void GivenTheMinimumDamageIsSetTo(int minDamage)
    {
        _calculator.MinimumDamage = minDamage;
    }

    [Given(@"the attacker has critical strike")]
    public void GivenTheAttackerHasCriticalStrike()
    {
        _hasCritical = true;
    }

    [When(@"I calculate damage for (\d+) base damage with (\d+) armor")]
    public void WhenICalculateDamage(int baseDamage, int armor)
    {
        _result = _calculator.Calculate(baseDamage, armor, _hasCritical);
    }

    [Then(@"the result should be (\d+)")]
    public void ThenTheResultShouldBe(int expected)
    {
        _result.Should().Be(expected);
    }
}
```

### Complex Feature Files

```gherkin
# features/Player/HealthSystem.feature

@player @health
Feature: Player Health System
    As a player
    I want a health system that responds to damage and healing
    So that combat feels responsive and fair

    Background:
        Given a player with the following stats:
            | Stat      | Value |
            | MaxHealth | 100   |
            | Armor     | 0     |

    @damage
    Scenario: Player takes direct damage
        When the player takes 25 damage from "enemy_attack"
        Then the player health should be 75
        And the "health_changed" event should be emitted with:
            | Parameter | Value |
            | NewHealth | 75    |
            | MaxHealth | 100   |

    @damage @death
    Scenario: Player dies from excessive damage
        When the player takes 150 damage from "boss_attack"
        Then the player health should be 0
        And the player should be dead
        And the "died" event should be emitted

    @healing
    Scenario: Player heals after taking damage
        Given the player has taken 50 damage
        When the player uses a health potion of 30
        Then the player health should be 80

    @healing @cap
    Scenario: Healing cannot exceed max health
        Given the player has taken 10 damage
        When the player uses a health potion of 50
        Then the player health should be 100

    @invincibility
    Scenario: Invincibility frames prevent damage
        Given the player has 0.5 seconds of invincibility
        When the player takes 25 damage from "enemy_attack"
        And 0.3 seconds pass
        And the player takes 25 damage from "another_attack"
        Then the player health should be 75
        And the player should have taken damage only once
```

### Step Definitions with Tables

```csharp
[Binding]
public class PlayerHealthSteps
{
    private Player _player = null!;
    private readonly List<string> _eventsEmitted = new();
    private readonly Dictionary<string, object> _lastEventArgs = new();
    private int _damageCount;

    [Given(@"a player with the following stats:")]
    public void GivenAPlayerWithStats(Table table)
    {
        _player = new Player();

        foreach (var row in table.Rows)
        {
            switch (row["Stat"])
            {
                case "MaxHealth":
                    _player.HealthComponent.MaxHealth = int.Parse(row["Value"]);
                    break;
                case "Armor":
                    _player.Armor = int.Parse(row["Value"]);
                    break;
            }
        }

        _player.HealthComponent.HealthChanged += (newHealth, maxHealth) =>
        {
            _eventsEmitted.Add("health_changed");
            _lastEventArgs["NewHealth"] = newHealth;
            _lastEventArgs["MaxHealth"] = maxHealth;
            _damageCount++;
        };

        _player.HealthComponent.Died += () =>
        {
            _eventsEmitted.Add("died");
        };

        _player.Initialize();
    }

    [Given(@"the player has taken (\d+) damage")]
    public void GivenThePlayerHasTakenDamage(int damage)
    {
        _player.HealthComponent.TakeDamage(damage);
        _damageCount = 0; // Reset for next scenario step
    }

    [Given(@"the player has ([\d.]+) seconds of invincibility")]
    public void GivenThePlayerHasInvincibility(float seconds)
    {
        _player.HealthComponent.InvincibilityDuration = seconds;
        _player.HealthComponent.StartInvincibility();
    }

    [When(@"the player takes (\d+) damage from ""(.+)""")]
    public void WhenThePlayerTakesDamage(int damage, string source)
    {
        _player.HealthComponent.TakeDamage(damage);
    }

    [When(@"the player uses a health potion of (\d+)")]
    public void WhenThePlayerUsesHealthPotion(int amount)
    {
        _player.HealthComponent.Heal(amount);
    }

    [When(@"([\d.]+) seconds pass")]
    public async void WhenSecondPass(float seconds)
    {
        await Task.Delay(TimeSpan.FromSeconds(seconds));
    }

    [Then(@"the player health should be (\d+)")]
    public void ThenThePlayerHealthShouldBe(int expected)
    {
        _player.HealthComponent.Health.Should().Be(expected);
    }

    [Then(@"the player should be dead")]
    public void ThenThePlayerShouldBeDead()
    {
        _player.HealthComponent.IsDead.Should().BeTrue();
    }

    [Then(@"the ""(.+)"" event should be emitted")]
    public void ThenTheEventShouldBeEmitted(string eventName)
    {
        _eventsEmitted.Should().Contain(eventName);
    }

    [Then(@"the ""(.+)"" event should be emitted with:")]
    public void ThenTheEventShouldBeEmittedWith(string eventName, Table table)
    {
        _eventsEmitted.Should().Contain(eventName);

        foreach (var row in table.Rows)
        {
            var param = row["Parameter"];
            var expectedValue = int.Parse(row["Value"]);
            _lastEventArgs[param].Should().Be(expectedValue);
        }
    }

    [Then(@"the player should have taken damage only once")]
    public void ThenThePlayerShouldHaveTakenDamageOnlyOnce()
    {
        _damageCount.Should().Be(1);
    }
}
```

### Hooks for Test Lifecycle

```csharp
// StepDefinitions/Hooks.cs
using Reqnroll;

namespace MyGame.Tests.StepDefinitions;

[Binding]
public class Hooks
{
    private readonly ScenarioContext _scenarioContext;
    private readonly FeatureContext _featureContext;

    public Hooks(ScenarioContext scenarioContext, FeatureContext featureContext)
    {
        _scenarioContext = scenarioContext;
        _featureContext = featureContext;
    }

    [BeforeScenario]
    public void BeforeScenario()
    {
        // Initialize test context
        Console.WriteLine($"Starting scenario: {_scenarioContext.ScenarioInfo.Title}");
    }

    [AfterScenario]
    public void AfterScenario()
    {
        // Cleanup
        if (_scenarioContext.TryGetValue<Node>("player", out var player))
        {
            player.QueueFree();
        }
    }

    [BeforeScenario("@slow")]
    public void BeforeSlowScenario()
    {
        // Special setup for slow tests
    }

    [AfterScenario("@database")]
    public void AfterDatabaseScenario()
    {
        // Cleanup database state
    }

    [BeforeFeature]
    public static void BeforeFeature(FeatureContext context)
    {
        Console.WriteLine($"Starting feature: {context.FeatureInfo.Title}");
    }

    [AfterFeature]
    public static void AfterFeature(FeatureContext context)
    {
        Console.WriteLine($"Completed feature: {context.FeatureInfo.Title}");
    }

    [BeforeTestRun]
    public static void BeforeTestRun()
    {
        // Global setup - run once before all tests
    }

    [AfterTestRun]
    public static void AfterTestRun()
    {
        // Global cleanup - run once after all tests
    }
}
```

### Sharing Data Between Steps

```csharp
// Using ScenarioContext
[Binding]
public class SharedStateSteps
{
    private readonly ScenarioContext _context;

    public SharedStateSteps(ScenarioContext context)
    {
        _context = context;
    }

    [Given(@"I create a player named ""(.+)""")]
    public void GivenICreateAPlayer(string name)
    {
        var player = new Player { Name = name };
        _context.Set(player, "currentPlayer");
    }

    [When(@"I give the player (\d+) coins")]
    public void WhenIGiveThePlayerCoins(int coins)
    {
        var player = _context.Get<Player>("currentPlayer");
        player.Coins += coins;
    }

    [Then(@"the player should have (\d+) coins")]
    public void ThenThePlayerShouldHaveCoins(int expected)
    {
        var player = _context.Get<Player>("currentPlayer");
        player.Coins.Should().Be(expected);
    }
}
```

---

## Test Fixtures and Factories

### Test Factory Pattern

```csharp
// Tests/Fixtures/TestFactory.cs
namespace MyGame.Tests.Fixtures;

public static class TestFactory
{
    public static Player CreatePlayer(Action<PlayerOptions>? configure = null)
    {
        var options = new PlayerOptions();
        configure?.Invoke(options);

        var player = new Player
        {
            Name = options.Name ?? "TestPlayer"
        };

        player.HealthComponent.MaxHealth = options.MaxHealth;
        player.MoveSpeed = options.MoveSpeed;

        if (options.Position.HasValue)
            player.Position = options.Position.Value;

        player.Initialize();
        return player;
    }

    public static Enemy CreateEnemy(EnemyType type = EnemyType.Basic,
        Action<EnemyOptions>? configure = null)
    {
        var options = new EnemyOptions();
        configure?.Invoke(options);

        var enemy = type switch
        {
            EnemyType.Basic => new BasicEnemy(),
            EnemyType.Ranged => new RangedEnemy(),
            EnemyType.Boss => new BossEnemy(),
            _ => throw new ArgumentException($"Unknown enemy type: {type}")
        };

        enemy.HealthComponent.MaxHealth = options.MaxHealth;
        enemy.Damage = options.Damage;

        if (options.Position.HasValue)
            enemy.Position = options.Position.Value;

        enemy.Initialize();
        return enemy;
    }

    public class PlayerOptions
    {
        public string? Name { get; set; }
        public int MaxHealth { get; set; } = 100;
        public float MoveSpeed { get; set; } = 200f;
        public Vector2? Position { get; set; }
    }

    public class EnemyOptions
    {
        public int MaxHealth { get; set; } = 50;
        public int Damage { get; set; } = 10;
        public Vector2? Position { get; set; }
    }
}
```

### Using Test Factories

```csharp
public class CombatTests
{
    [Fact]
    public void Player_CanDefeatEnemy()
    {
        // Arrange
        var player = TestFactory.CreatePlayer(opts =>
        {
            opts.MaxHealth = 100;
            opts.Position = Vector2.Zero;
        });

        var enemy = TestFactory.CreateEnemy(EnemyType.Basic, opts =>
        {
            opts.MaxHealth = 30;
            opts.Position = new Vector2(50, 0);
        });

        // Act
        player.Attack(enemy);
        player.Attack(enemy);
        player.Attack(enemy);

        // Assert
        enemy.IsDead.Should().BeTrue();
    }
}
```

---

## Running Tests

### GdUnit4 Commands

```bash
# Run all tests
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --run-all

# Run specific test suite
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
    --run=res://tests/Unit/HealthComponentTests.cs

# Generate report
godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd \
    --run-all --report-path=./test-reports
```

### dotnet test Commands

```bash
# Run all tests
dotnet test

# Run with verbosity
dotnet test --verbosity normal

# Run specific tests by name
dotnet test --filter "FullyQualifiedName~HealthComponent"

# Run by category/trait
dotnet test --filter "Category=Combat"

# Run BDD tests only
dotnet test --filter "Category=BDD"

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run with detailed results
dotnet test --logger "console;verbosity=detailed"

# Generate JUnit XML for CI
dotnet test --logger "junit;LogFilePath=test-results.xml"
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore dependencies
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore

      - name: Run unit tests
        run: dotnet test --no-build --logger "trx;LogFileName=test-results.trx"

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: '**/test-results.trx'
```
