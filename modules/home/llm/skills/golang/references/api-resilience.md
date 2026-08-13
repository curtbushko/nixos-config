# API Resilience Patterns

Production-grade patterns for building resilient HTTP clients and API interactions in Go.

## Core Principles

1. **Expect failure**: Networks fail, services go down, rate limits trigger
2. **Fail fast, recover gracefully**: Detect issues quickly, retry intelligently
3. **Protect both sides**: Client-side limits protect you, server-side limits protect them
4. **Observable**: Log/metric every retry, timeout, and rate limit hit

---

## Retry with Exponential Backoff and Jitter

### Why Jitter Matters

Without jitter, synchronized retries create "thundering herd" problems:

```
Without jitter: All clients retry at exactly 1s, 2s, 4s...
                Server gets hammered at predictable intervals

With jitter:    Client A: 0.8s, 1.9s, 4.2s
                Client B: 1.1s, 2.3s, 3.8s
                Load spreads out naturally
```

### Basic Retry Pattern

```go
package retry

import (
    "context"
    "math/rand"
    "time"
)

// Config holds retry configuration.
type Config struct {
    MaxAttempts  int           // Maximum number of attempts (including first)
    InitialDelay time.Duration // Starting delay between retries
    MaxDelay     time.Duration // Maximum delay cap
    Multiplier   float64       // Backoff multiplier (typically 2.0)
    JitterFactor float64       // Jitter as fraction of delay (0.0-1.0)
}

// DefaultConfig provides sensible defaults.
var DefaultConfig = Config{
    MaxAttempts:  3,
    InitialDelay: 100 * time.Millisecond,
    MaxDelay:     30 * time.Second,
    Multiplier:   2.0,
    JitterFactor: 0.2, // +/- 20% jitter
}

// Do executes fn with retries according to config.
// Returns first nil error or last error after all attempts exhausted.
func Do(ctx context.Context, cfg Config, fn func() error) error {
    var lastErr error
    delay := cfg.InitialDelay

    for attempt := 0; attempt < cfg.MaxAttempts; attempt++ {
        lastErr = fn()
        if lastErr == nil {
            return nil
        }

        // Check if error is retryable
        if !isRetryable(lastErr) {
            return lastErr
        }

        // Don't sleep after last attempt
        if attempt == cfg.MaxAttempts-1 {
            break
        }

        // Calculate delay with jitter
        jitteredDelay := addJitter(delay, cfg.JitterFactor)

        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-time.After(jitteredDelay):
        }

        // Increase delay for next iteration (exponential backoff)
        delay = time.Duration(float64(delay) * cfg.Multiplier)
        if delay > cfg.MaxDelay {
            delay = cfg.MaxDelay
        }
    }

    return lastErr
}

// addJitter adds random jitter to duration.
// jitterFactor of 0.2 means +/- 20% of the base delay.
func addJitter(d time.Duration, jitterFactor float64) time.Duration {
    if jitterFactor <= 0 {
        return d
    }
    // Generate random value between -jitterFactor and +jitterFactor
    jitter := (rand.Float64()*2 - 1) * jitterFactor
    return time.Duration(float64(d) * (1 + jitter))
}

// isRetryable determines if an error should trigger a retry.
func isRetryable(err error) bool {
    // Customize based on your error types
    // Network errors, 5xx responses, rate limits are typically retryable
    // 4xx client errors (except 429) are typically not retryable
    return true // Simplified - implement proper checks
}
```

### Full Jitter vs Equal Jitter

```go
// Full jitter: random between 0 and calculated delay
// Best for reducing contention
func fullJitter(delay time.Duration) time.Duration {
    return time.Duration(rand.Float64() * float64(delay))
}

// Equal jitter: half the delay + random up to half
// Good balance between minimum wait and spread
func equalJitter(delay time.Duration) time.Duration {
    half := delay / 2
    return half + time.Duration(rand.Float64()*float64(half))
}

// Decorrelated jitter: based on previous delay, not current
// Best for long retry sequences
func decorrelatedJitter(prevDelay, baseDelay, maxDelay time.Duration) time.Duration {
    delay := time.Duration(rand.Float64() * float64(prevDelay*3))
    if delay < baseDelay {
        delay = baseDelay
    }
    if delay > maxDelay {
        delay = maxDelay
    }
    return delay
}
```

---

## Handling Rate Limits

### Client-Side Rate Limiting

Prevent overwhelming the server before you hit their limits:

```go
package ratelimit

import (
    "context"
    "time"

    "golang.org/x/time/rate"
)

// RateLimitedClient wraps an HTTP client with rate limiting.
type RateLimitedClient struct {
    client  *http.Client
    limiter *rate.Limiter
}

// NewRateLimitedClient creates a client that limits to rps requests per second.
func NewRateLimitedClient(rps float64, burst int) *RateLimitedClient {
    return &RateLimitedClient{
        client:  &http.Client{Timeout: 30 * time.Second},
        limiter: rate.NewLimiter(rate.Limit(rps), burst),
    }
}

// Do executes the request after waiting for rate limit token.
func (c *RateLimitedClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    // Wait for rate limit token
    if err := c.limiter.Wait(ctx); err != nil {
        return nil, fmt.Errorf("rate limit wait: %w", err)
    }

    req = req.WithContext(ctx)
    return c.client.Do(req)
}
```

### Server-Side Rate Limit Response Handling

Parse and respect `Retry-After` headers:

```go
package api

import (
    "context"
    "fmt"
    "net/http"
    "strconv"
    "time"
)

// ErrRateLimited is returned when the server returns 429.
type ErrRateLimited struct {
    RetryAfter time.Duration
}

func (e *ErrRateLimited) Error() string {
    return fmt.Sprintf("rate limited, retry after %v", e.RetryAfter)
}

// parseRetryAfter extracts delay from Retry-After header.
// Handles both delay-seconds and HTTP-date formats.
func parseRetryAfter(header string) time.Duration {
    if header == "" {
        return 0
    }

    // Try parsing as seconds first
    if seconds, err := strconv.Atoi(header); err == nil {
        return time.Duration(seconds) * time.Second
    }

    // Try parsing as HTTP-date
    if t, err := http.ParseTime(header); err == nil {
        delay := time.Until(t)
        if delay > 0 {
            return delay
        }
    }

    return 0
}

// doRequest executes request with retry on rate limit.
func (c *Client) doRequest(ctx context.Context, req *http.Request) (*http.Response, error) {
    for {
        resp, err := c.httpClient.Do(req.WithContext(ctx))
        if err != nil {
            return nil, err
        }

        // Handle rate limiting
        if resp.StatusCode == http.StatusTooManyRequests {
            resp.Body.Close()

            retryAfter := parseRetryAfter(resp.Header.Get("Retry-After"))
            if retryAfter == 0 {
                retryAfter = time.Second // Default fallback
            }

            // Cap the wait time
            if retryAfter > 5*time.Minute {
                return nil, &ErrRateLimited{RetryAfter: retryAfter}
            }

            select {
            case <-ctx.Done():
                return nil, ctx.Err()
            case <-time.After(retryAfter):
                continue // Retry
            }
        }

        return resp, nil
    }
}
```

### Adaptive Rate Limiting

Adjust client-side limits based on server responses:

```go
package adaptive

import (
    "sync"
    "time"

    "golang.org/x/time/rate"
)

// AdaptiveLimiter adjusts rate based on success/failure.
type AdaptiveLimiter struct {
    mu          sync.Mutex
    limiter     *rate.Limiter
    minRate     float64
    maxRate     float64
    currentRate float64
}

// NewAdaptiveLimiter creates a limiter that adjusts between min and max RPS.
func NewAdaptiveLimiter(minRate, maxRate, startRate float64) *AdaptiveLimiter {
    return &AdaptiveLimiter{
        limiter:     rate.NewLimiter(rate.Limit(startRate), int(startRate)),
        minRate:     minRate,
        maxRate:     maxRate,
        currentRate: startRate,
    }
}

// OnSuccess increases rate (up to max).
func (a *AdaptiveLimiter) OnSuccess() {
    a.mu.Lock()
    defer a.mu.Unlock()

    // Increase by 10%
    a.currentRate *= 1.1
    if a.currentRate > a.maxRate {
        a.currentRate = a.maxRate
    }
    a.limiter.SetLimit(rate.Limit(a.currentRate))
}

// OnRateLimit decreases rate (down to min).
func (a *AdaptiveLimiter) OnRateLimit() {
    a.mu.Lock()
    defer a.mu.Unlock()

    // Decrease by 50%
    a.currentRate *= 0.5
    if a.currentRate < a.minRate {
        a.currentRate = a.minRate
    }
    a.limiter.SetLimit(rate.Limit(a.currentRate))
}
```

---

## Circuit Breaker Pattern

Prevent cascading failures by failing fast when a service is down:

```go
package circuit

import (
    "errors"
    "sync"
    "time"
)

// State represents circuit breaker state.
type State int

const (
    StateClosed   State = iota // Normal operation
    StateOpen                  // Failing fast
    StateHalfOpen              // Testing if recovered
)

var ErrCircuitOpen = errors.New("circuit breaker is open")

// Breaker implements the circuit breaker pattern.
type Breaker struct {
    mu sync.Mutex

    state           State
    failures        int
    successes       int
    lastFailureTime time.Time

    // Configuration
    failureThreshold int           // Failures before opening
    successThreshold int           // Successes in half-open to close
    timeout          time.Duration // Time before half-open
}

// NewBreaker creates a circuit breaker.
func NewBreaker(failureThreshold, successThreshold int, timeout time.Duration) *Breaker {
    return &Breaker{
        state:            StateClosed,
        failureThreshold: failureThreshold,
        successThreshold: successThreshold,
        timeout:          timeout,
    }
}

// Execute runs fn if circuit allows, tracking success/failure.
func (b *Breaker) Execute(fn func() error) error {
    if !b.allowRequest() {
        return ErrCircuitOpen
    }

    err := fn()

    b.recordResult(err == nil)
    return err
}

func (b *Breaker) allowRequest() bool {
    b.mu.Lock()
    defer b.mu.Unlock()

    switch b.state {
    case StateClosed:
        return true
    case StateOpen:
        // Check if timeout has passed
        if time.Since(b.lastFailureTime) > b.timeout {
            b.state = StateHalfOpen
            b.successes = 0
            return true
        }
        return false
    case StateHalfOpen:
        return true
    }
    return false
}

func (b *Breaker) recordResult(success bool) {
    b.mu.Lock()
    defer b.mu.Unlock()

    switch b.state {
    case StateClosed:
        if success {
            b.failures = 0
        } else {
            b.failures++
            if b.failures >= b.failureThreshold {
                b.state = StateOpen
                b.lastFailureTime = time.Now()
            }
        }
    case StateHalfOpen:
        if success {
            b.successes++
            if b.successes >= b.successThreshold {
                b.state = StateClosed
                b.failures = 0
            }
        } else {
            b.state = StateOpen
            b.lastFailureTime = time.Now()
        }
    }
}
```

---

## Complete Resilient Client Example

Combining all patterns:

```go
package client

import (
    "context"
    "fmt"
    "io"
    "net/http"
    "time"

    "golang.org/x/time/rate"
)

// Config holds client configuration.
type Config struct {
    BaseURL        string
    Timeout        time.Duration
    MaxRetries     int
    InitialBackoff time.Duration
    MaxBackoff     time.Duration
    RateLimit      float64 // Requests per second
    RateBurst      int
}

// DefaultConfig returns sensible defaults.
var DefaultConfig = Config{
    Timeout:        30 * time.Second,
    MaxRetries:     3,
    InitialBackoff: 100 * time.Millisecond,
    MaxBackoff:     30 * time.Second,
    RateLimit:      10.0,
    RateBurst:      20,
}

// Client is a resilient HTTP client.
type Client struct {
    httpClient *http.Client
    limiter    *rate.Limiter
    breaker    *Breaker
    config     Config
}

// New creates a new resilient client.
func New(cfg Config) *Client {
    return &Client{
        httpClient: &http.Client{Timeout: cfg.Timeout},
        limiter:    rate.NewLimiter(rate.Limit(cfg.RateLimit), cfg.RateBurst),
        breaker:    NewBreaker(5, 2, 30*time.Second),
        config:     cfg,
    }
}

// Get performs a GET request with full resilience.
func (c *Client) Get(ctx context.Context, path string) ([]byte, error) {
    // Wait for rate limit
    if err := c.limiter.Wait(ctx); err != nil {
        return nil, fmt.Errorf("rate limit: %w", err)
    }

    var result []byte
    var lastErr error

    err := c.breaker.Execute(func() error {
        result, lastErr = c.doWithRetry(ctx, "GET", path, nil)
        return lastErr
    })

    if err != nil {
        return nil, err
    }
    return result, lastErr
}

func (c *Client) doWithRetry(ctx context.Context, method, path string, body io.Reader) ([]byte, error) {
    var lastErr error
    backoff := c.config.InitialBackoff

    for attempt := 0; attempt <= c.config.MaxRetries; attempt++ {
        if attempt > 0 {
            // Wait with jitter before retry
            jitteredBackoff := addJitter(backoff, 0.2)
            select {
            case <-ctx.Done():
                return nil, ctx.Err()
            case <-time.After(jitteredBackoff):
            }
            backoff = min(backoff*2, c.config.MaxBackoff)
        }

        req, err := http.NewRequestWithContext(ctx, method, c.config.BaseURL+path, body)
        if err != nil {
            return nil, fmt.Errorf("create request: %w", err)
        }

        resp, err := c.httpClient.Do(req)
        if err != nil {
            lastErr = fmt.Errorf("request failed: %w", err)
            continue // Retry on network error
        }

        data, err := io.ReadAll(resp.Body)
        resp.Body.Close()

        // Handle based on status code
        switch {
        case resp.StatusCode >= 200 && resp.StatusCode < 300:
            return data, nil

        case resp.StatusCode == 429:
            // Rate limited - use Retry-After if present
            if retryAfter := parseRetryAfter(resp.Header.Get("Retry-After")); retryAfter > 0 {
                backoff = retryAfter
            }
            lastErr = fmt.Errorf("rate limited")
            continue

        case resp.StatusCode >= 500:
            // Server error - retry
            lastErr = fmt.Errorf("server error: %d", resp.StatusCode)
            continue

        default:
            // Client error - don't retry
            return nil, fmt.Errorf("client error: %d: %s", resp.StatusCode, string(data))
        }
    }

    return nil, fmt.Errorf("max retries exceeded: %w", lastErr)
}
```

---

## Testing Resilience

### Testing Retries

```go
func TestRetryOnTransientFailure(t *testing.T) {
    attempts := 0
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        attempts++
        if attempts < 3 {
            w.WriteHeader(http.StatusServiceUnavailable)
            return
        }
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("success"))
    }))
    defer server.Close()

    client := New(Config{
        BaseURL:    server.URL,
        MaxRetries: 5,
    })

    data, err := client.Get(context.Background(), "/test")
    require.NoError(t, err)
    assert.Equal(t, "success", string(data))
    assert.Equal(t, 3, attempts)
}
```

### Testing Rate Limiting

```go
func TestRateLimiting(t *testing.T) {
    requestTimes := make([]time.Time, 0)
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        requestTimes = append(requestTimes, time.Now())
        w.WriteHeader(http.StatusOK)
    }))
    defer server.Close()

    client := New(Config{
        BaseURL:   server.URL,
        RateLimit: 2.0, // 2 requests per second
        RateBurst: 1,
    })

    for i := 0; i < 5; i++ {
        _, _ = client.Get(context.Background(), "/test")
    }

    // Verify requests are spaced appropriately
    for i := 1; i < len(requestTimes); i++ {
        gap := requestTimes[i].Sub(requestTimes[i-1])
        assert.GreaterOrEqual(t, gap, 400*time.Millisecond) // ~500ms expected
    }
}
```

---

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| No jitter | Thundering herd on retries | Add 10-30% random jitter |
| Fixed retry delay | Doesn't adapt to load | Use exponential backoff |
| Unlimited retries | Wastes resources | Cap at 3-5 attempts |
| Ignoring 429 | Gets banned by server | Parse Retry-After, back off |
| No client rate limit | Triggers server limits | Use `golang.org/x/time/rate` |
| Retry on 4xx | Wastes time on permanent errors | Only retry 5xx and network errors |
| No circuit breaker | Cascading failures | Fail fast when service down |
| No timeout | Requests hang forever | Always set context timeout |

---

## Libraries

- **golang.org/x/time/rate**: Standard rate limiter
- **github.com/sony/gobreaker**: Circuit breaker implementation
- **github.com/cenkalti/backoff/v4**: Retry with backoff utilities
- **github.com/hashicorp/go-retryablehttp**: HTTP client with retries built-in
- **github.com/avast/retry-go**: Simple retry library

---

## Quick Reference

```go
// Rate limiter setup
limiter := rate.NewLimiter(rate.Limit(10), 20) // 10 RPS, burst of 20
limiter.Wait(ctx) // Block until token available

// Exponential backoff
delay = min(delay * 2, maxDelay)

// Add jitter (20%)
jittered = delay * (1 + (rand.Float64()*0.4 - 0.2))

// Parse Retry-After
seconds, _ := strconv.Atoi(header)
retryAfter := time.Duration(seconds) * time.Second

// Circuit breaker states
Closed -> (failures >= threshold) -> Open
Open -> (timeout elapsed) -> HalfOpen
HalfOpen -> (success) -> Closed
HalfOpen -> (failure) -> Open
```
