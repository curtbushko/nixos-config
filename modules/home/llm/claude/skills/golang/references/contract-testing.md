# Contract Testing for Hexagonal Architecture

## The Gap in Hexagonal Architecture

Hexagonal architecture (ports and adapters) ensures:
- Domain has no infrastructure dependencies
- Dependencies flow inward
- Adapters implement port interfaces

But it does NOT ensure:
- Adapters handle edge cases correctly
- Multiple implementations behave identically
- Mocks are accurate representations of real implementations

**Contract tests fill this gap.**

## Contract Test Architecture

```
                    Contract Tests
                    (RunXxxContract)
                          |
          +---------------+---------------+
          |               |               |
     PostgresImpl    MockImpl      InMemoryImpl
          |               |               |
     integration      unit test        unit test
```

## Complete Contract Test Example

### Port Interface with Contract Documentation

```go
// internal/ports/repositories.go

package ports

import (
    "context"
    "github.com/google/uuid"
    "myapp/internal/domain"
)

// CardRepository provides persistence for cards.
//
// Contract (all implementations must satisfy):
//   - Create: nil card returns ErrInvalidInput
//   - Create: zero ID returns ErrInvalidInput
//   - Create: nil Tags treated as empty slice
//   - Create: duplicate ID returns ErrDuplicateKey
//   - Get: not found returns ErrCardNotFound
//   - Get: zero ID returns ErrInvalidInput
//   - Update: nil card returns ErrInvalidInput
//   - Update: not found returns ErrCardNotFound
//   - Delete: not found returns ErrCardNotFound (or is idempotent)
//   - All methods respect context cancellation
type CardRepository interface {
    Create(ctx context.Context, card *domain.Card) error
    Get(ctx context.Context, id uuid.UUID) (*domain.Card, error)
    Update(ctx context.Context, card *domain.Card) error
    Delete(ctx context.Context, id uuid.UUID) error
    List(ctx context.Context, filter CardFilter) ([]*domain.Card, error)
}
```

### Contract Test Implementation

```go
// internal/ports/card_repository_contract_test.go

package ports_test

import (
    "context"
    "testing"
    "time"

    "github.com/google/uuid"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"

    "myapp/internal/domain"
    "myapp/internal/ports"
)

// CardRepositoryContractSuite contains all contract tests.
// Any CardRepository implementation must pass all these tests.
type CardRepositoryContractSuite struct {
    // NewRepo creates a fresh repository instance for each test.
    NewRepo func(t *testing.T) ports.CardRepository

    // Cleanup is called after each test (optional).
    Cleanup func(t *testing.T)
}

// Run executes all contract tests.
func (s *CardRepositoryContractSuite) Run(t *testing.T) {
    t.Helper()

    tests := []struct {
        name string
        fn   func(t *testing.T, repo ports.CardRepository)
    }{
        {"Create_ValidCard", s.testCreateValidCard},
        {"Create_NilCard", s.testCreateNilCard},
        {"Create_ZeroID", s.testCreateZeroID},
        {"Create_NilTags", s.testCreateNilTags},
        {"Create_EmptyTags", s.testCreateEmptyTags},
        {"Create_DuplicateID", s.testCreateDuplicateID},
        {"Get_Exists", s.testGetExists},
        {"Get_NotFound", s.testGetNotFound},
        {"Get_ZeroID", s.testGetZeroID},
        {"Update_Exists", s.testUpdateExists},
        {"Update_NotFound", s.testUpdateNotFound},
        {"Update_NilCard", s.testUpdateNilCard},
        {"Delete_Exists", s.testDeleteExists},
        {"Delete_NotFound", s.testDeleteNotFound},
        {"ContextCancellation", s.testContextCancellation},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := s.NewRepo(t)
            if s.Cleanup != nil {
                t.Cleanup(func() { s.Cleanup(t) })
            }
            tt.fn(t, repo)
        })
    }
}

// --- Create Contract Tests ---

func (s *CardRepositoryContractSuite) testCreateValidCard(t *testing.T, repo ports.CardRepository) {
    card := validCard()

    err := repo.Create(context.Background(), card)

    require.NoError(t, err)
}

func (s *CardRepositoryContractSuite) testCreateNilCard(t *testing.T, repo ports.CardRepository) {
    err := repo.Create(context.Background(), nil)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrInvalidInput)
}

func (s *CardRepositoryContractSuite) testCreateZeroID(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    card.ID = uuid.Nil

    err := repo.Create(context.Background(), card)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrInvalidInput)
}

func (s *CardRepositoryContractSuite) testCreateNilTags(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    card.Tags = nil  // Critical edge case

    err := repo.Create(context.Background(), card)

    require.NoError(t, err, "nil tags must be handled without panic")

    // Verify retrieval works
    retrieved, err := repo.Get(context.Background(), card.ID)
    require.NoError(t, err)
    assert.NotNil(t, retrieved.Tags, "tags should never be nil after retrieval")
}

func (s *CardRepositoryContractSuite) testCreateEmptyTags(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    card.Tags = []string{}

    err := repo.Create(context.Background(), card)

    require.NoError(t, err)

    retrieved, err := repo.Get(context.Background(), card.ID)
    require.NoError(t, err)
    assert.Empty(t, retrieved.Tags)
}

func (s *CardRepositoryContractSuite) testCreateDuplicateID(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    require.NoError(t, repo.Create(context.Background(), card))

    // Try to create again with same ID
    duplicate := validCard()
    duplicate.ID = card.ID

    err := repo.Create(context.Background(), duplicate)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrDuplicateKey)
}

// --- Get Contract Tests ---

func (s *CardRepositoryContractSuite) testGetExists(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    require.NoError(t, repo.Create(context.Background(), card))

    retrieved, err := repo.Get(context.Background(), card.ID)

    require.NoError(t, err)
    assert.Equal(t, card.ID, retrieved.ID)
    assert.Equal(t, card.Front, retrieved.Front)
    assert.Equal(t, card.Back, retrieved.Back)
}

func (s *CardRepositoryContractSuite) testGetNotFound(t *testing.T, repo ports.CardRepository) {
    _, err := repo.Get(context.Background(), uuid.New())

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrCardNotFound)
}

func (s *CardRepositoryContractSuite) testGetZeroID(t *testing.T, repo ports.CardRepository) {
    _, err := repo.Get(context.Background(), uuid.Nil)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrInvalidInput)
}

// --- Update Contract Tests ---

func (s *CardRepositoryContractSuite) testUpdateExists(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    require.NoError(t, repo.Create(context.Background(), card))

    card.Front = "Updated Front"
    err := repo.Update(context.Background(), card)

    require.NoError(t, err)

    retrieved, err := repo.Get(context.Background(), card.ID)
    require.NoError(t, err)
    assert.Equal(t, "Updated Front", retrieved.Front)
}

func (s *CardRepositoryContractSuite) testUpdateNotFound(t *testing.T, repo ports.CardRepository) {
    card := validCard()

    err := repo.Update(context.Background(), card)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrCardNotFound)
}

func (s *CardRepositoryContractSuite) testUpdateNilCard(t *testing.T, repo ports.CardRepository) {
    err := repo.Update(context.Background(), nil)

    require.Error(t, err)
    assert.ErrorIs(t, err, domain.ErrInvalidInput)
}

// --- Delete Contract Tests ---

func (s *CardRepositoryContractSuite) testDeleteExists(t *testing.T, repo ports.CardRepository) {
    card := validCard()
    require.NoError(t, repo.Create(context.Background(), card))

    err := repo.Delete(context.Background(), card.ID)

    require.NoError(t, err)

    _, err = repo.Get(context.Background(), card.ID)
    assert.ErrorIs(t, err, domain.ErrCardNotFound)
}

func (s *CardRepositoryContractSuite) testDeleteNotFound(t *testing.T, repo ports.CardRepository) {
    err := repo.Delete(context.Background(), uuid.New())

    // Delete can either:
    // - Return ErrCardNotFound (strict)
    // - Return nil (idempotent)
    // Both are acceptable, but should be consistent
    if err != nil {
        assert.ErrorIs(t, err, domain.ErrCardNotFound)
    }
}

// --- Context Contract Tests ---

func (s *CardRepositoryContractSuite) testContextCancellation(t *testing.T, repo ports.CardRepository) {
    ctx, cancel := context.WithCancel(context.Background())
    cancel() // Cancel immediately

    _, err := repo.Get(ctx, uuid.New())

    require.Error(t, err)
    // Should return context error, not hang
    assert.ErrorIs(t, err, context.Canceled)
}

// --- Test Helpers ---

func validCard() *domain.Card {
    return &domain.Card{
        ID:        uuid.New(),
        DeckID:    uuid.New(),
        UserID:    uuid.New(),
        Front:     "Test Front",
        Back:      "Test Back",
        Tags:      []string{"test"},
        State:     domain.CardStateNew,
        Due:       time.Now(),
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }
}
```

### Running Contract Against PostgreSQL

```go
// internal/adapters/repositories/postgres/card_repository_contract_test.go
//go:build integration

package postgres_test

import (
    "testing"

    "myapp/internal/adapters/repositories/postgres"
    "myapp/internal/ports"
)

func TestCardRepository_Contract(t *testing.T) {
    suite := &ports.CardRepositoryContractSuite{
        NewRepo: func(t *testing.T) ports.CardRepository {
            db := setupTestDB(t)  // Your test helper
            return postgres.NewCardRepository(db)
        },
        Cleanup: func(t *testing.T) {
            // Cleanup handled by setupTestDB's t.Cleanup
        },
    }

    suite.Run(t)
}
```

### Running Contract Against Mock

```go
// internal/mocks/card_repository_contract_test.go
// Note: No build tag - runs as unit test

package mocks_test

import (
    "testing"

    "myapp/internal/mocks"
    "myapp/internal/ports"
)

func TestMockCardRepository_Contract(t *testing.T) {
    suite := &ports.CardRepositoryContractSuite{
        NewRepo: func(t *testing.T) ports.CardRepository {
            return mocks.NewCardRepository()
        },
    }

    suite.Run(t)
}
```

## Contract Tests for Other Port Types

### External Service Contract (FSRS Scheduler)

```go
// internal/ports/fsrs_contract_test.go

type FSRSSchedulerContractSuite struct {
    NewScheduler func(t *testing.T) ports.FSRSScheduler
}

func (s *FSRSSchedulerContractSuite) Run(t *testing.T) {
    tests := []struct{
        name string
        fn   func(t *testing.T, sched ports.FSRSScheduler)
    }{
        {"Schedule_NewCard", s.testScheduleNewCard},
        {"Schedule_AllRatings", s.testScheduleAllRatings},
        {"Schedule_OverdueCard", s.testScheduleOverdueCard},
        {"Schedule_ZeroStability", s.testScheduleZeroStability},
        {"Invariants_PositiveStability", s.testInvariantsPositiveStability},
        {"Invariants_DueInFuture", s.testInvariantsDueInFuture},
        {"StateTransitions_NewToLearning", s.testStateTransitionNewToLearning},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            sched := s.NewScheduler(t)
            tt.fn(t, sched)
        })
    }
}

func (s *FSRSSchedulerContractSuite) testScheduleNewCard(t *testing.T, sched ports.FSRSScheduler) {
    card := newCard()

    result, err := sched.Schedule(card, domain.RatingGood, time.Now())

    require.NoError(t, err)
    assert.True(t, result.Due.After(time.Now()))
    assert.Positive(t, result.Stability)
}

func (s *FSRSSchedulerContractSuite) testInvariantsPositiveStability(t *testing.T, sched ports.FSRSScheduler) {
    ratings := []domain.Rating{domain.RatingAgain, domain.RatingHard, domain.RatingGood, domain.RatingEasy}

    for _, rating := range ratings {
        t.Run(rating.String(), func(t *testing.T) {
            card := newCard()
            result, err := sched.Schedule(card, rating, time.Now())

            require.NoError(t, err)
            assert.Positive(t, result.Stability, "stability must be positive for rating %s", rating)
        })
    }
}
```

## CI Integration

```yaml
# .github/workflows/test.yml

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Run Unit Tests (includes mock contracts)
        run: go test ./...

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: Run Integration Tests (includes postgres contracts)
        run: go test -tags=integration ./...
```

## Summary

| Test Type | Build Tag | Speed | Catches |
|-----------|-----------|-------|---------|
| Mock contract | none | <1s | Mock accuracy |
| Postgres contract | integration | ~1s | Adapter bugs |
| Unit tests | none | <1s | Business logic |
| Integration tests | integration | ~10s | End-to-end flow |

**Run mock contracts on every commit (fast). Run postgres contracts in CI (slower but thorough).**
