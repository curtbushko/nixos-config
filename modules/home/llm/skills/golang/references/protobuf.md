# Protobuf Guidelines for Go Projects

Guidelines for designing Protocol Buffer schemas in Go projects.

## Trace ID Requirement (MANDATORY)

**Every protobuf message MUST include a `trace_id` field** for distributed tracing and debugging.

```protobuf
message CreateUserRequest {
    string trace_id = 1;  // REQUIRED - Always field number 1
    string email = 2;
    string name = 3;
}

message CreateUserResponse {
    string trace_id = 1;  // REQUIRED - Echo back the trace_id
    User user = 2;
}
```

### Rules

1. **Field position**: `trace_id` should be field number 1 in every message
2. **Type**: Always `string` (UUIDs, ULIDs, or other trace formats)
3. **Request messages**: Include `trace_id` for correlation
4. **Response messages**: Echo back the `trace_id` from the request
5. **Nested messages**: Only top-level request/response messages need `trace_id`

### Example Service Definition

```protobuf
syntax = "proto3";

package user.v1;

option go_package = "myapp/gen/user/v1;userv1";

import "google/protobuf/timestamp.proto";

// User service for managing user accounts
service UserService {
    rpc CreateUser(CreateUserRequest) returns (CreateUserResponse);
    rpc GetUser(GetUserRequest) returns (GetUserResponse);
    rpc UpdateUser(UpdateUserRequest) returns (UpdateUserResponse);
    rpc DeleteUser(DeleteUserRequest) returns (DeleteUserResponse);
    rpc ListUsers(ListUsersRequest) returns (ListUsersResponse);
}

// User entity
message User {
    string id = 1;
    string email = 2;
    string name = 3;
    google.protobuf.Timestamp created_at = 4;
    google.protobuf.Timestamp updated_at = 5;
}

// CreateUser
message CreateUserRequest {
    string trace_id = 1;  // REQUIRED
    string email = 2;
    string name = 3;
}

message CreateUserResponse {
    string trace_id = 1;  // REQUIRED - Echo back
    User user = 2;
}

// GetUser
message GetUserRequest {
    string trace_id = 1;  // REQUIRED
    string id = 2;
}

message GetUserResponse {
    string trace_id = 1;  // REQUIRED - Echo back
    User user = 2;
}

// UpdateUser
message UpdateUserRequest {
    string trace_id = 1;  // REQUIRED
    string id = 2;
    optional string email = 3;
    optional string name = 4;
}

message UpdateUserResponse {
    string trace_id = 1;  // REQUIRED - Echo back
    User user = 2;
}

// DeleteUser
message DeleteUserRequest {
    string trace_id = 1;  // REQUIRED
    string id = 2;
}

message DeleteUserResponse {
    string trace_id = 1;  // REQUIRED - Echo back
}

// ListUsers with pagination
message ListUsersRequest {
    string trace_id = 1;  // REQUIRED
    int32 page = 2;
    int32 page_size = 3;
    string sort_by = 4;
    bool descending = 5;
}

message ListUsersResponse {
    string trace_id = 1;  // REQUIRED - Echo back
    repeated User users = 2;
    int32 total_count = 3;
    int32 page = 4;
    int32 page_size = 5;
}
```

---

## Context Propagation

In Go handlers, propagate trace IDs through context:

```go
type contextKey string

const traceIDKey contextKey = "trace_id"

// Extract trace ID from request and add to context
func (s *userServer) CreateUser(ctx context.Context, req *userv1.CreateUserRequest) (*userv1.CreateUserResponse, error) {
    // Add trace ID to context
    ctx = context.WithValue(ctx, traceIDKey, req.TraceId)

    // Use context throughout the call chain
    user, err := s.service.CreateUser(ctx, req.Email, req.Name)
    if err != nil {
        return nil, status.Errorf(codes.Internal, "create user: %v", err)
    }

    // Echo trace ID in response
    return &userv1.CreateUserResponse{
        TraceId: req.TraceId,
        User:    toProtoUser(user),
    }, nil
}
```

---

## Field Naming Conventions

### Use snake_case for Field Names

```protobuf
message User {
    string user_id = 1;        // snake_case
    string email_address = 2;  // snake_case
    int64 created_at = 3;      // snake_case
}
```

### Proto3 Generated Go Names

| Proto Field | Go Field |
|-------------|----------|
| `user_id` | `UserId` |
| `email_address` | `EmailAddress` |
| `created_at` | `CreatedAt` |

---

## Best Practices

### 1. Use Meaningful Field Numbers

- Reserve 1-15 for frequently used fields (1-byte encoding)
- Reserve 16-2047 for less common fields (2-byte encoding)
- Reserve numbers for future fields

```protobuf
message User {
    // Frequently accessed (1-15)
    string id = 1;
    string email = 2;
    string name = 3;

    // Less frequent (16+)
    string phone = 16;
    string address = 17;

    // Reserved for future use
    reserved 10, 11, 12;
    reserved "deprecated_field";
}
```

### 2. Use Wrapper Types for Optional Fields

```protobuf
import "google/protobuf/wrappers.proto";

message UpdateUserRequest {
    string trace_id = 1;
    string id = 2;
    google.protobuf.StringValue email = 3;  // Optional
    google.protobuf.StringValue name = 4;   // Optional
}
```

Or use proto3 optional keyword:

```protobuf
message UpdateUserRequest {
    string trace_id = 1;
    string id = 2;
    optional string email = 3;
    optional string name = 4;
}
```

### 3. Use Enums for Fixed Value Sets

```protobuf
enum UserStatus {
    USER_STATUS_UNSPECIFIED = 0;  // Always have UNSPECIFIED as 0
    USER_STATUS_ACTIVE = 1;
    USER_STATUS_SUSPENDED = 2;
    USER_STATUS_DELETED = 3;
}

message User {
    string id = 1;
    UserStatus status = 2;
}
```

### 4. Use Timestamps for Time Fields

```protobuf
import "google/protobuf/timestamp.proto";

message User {
    string id = 1;
    google.protobuf.Timestamp created_at = 2;
    google.protobuf.Timestamp updated_at = 3;
}
```

### 5. Design for Pagination

```protobuf
message ListRequest {
    string trace_id = 1;
    int32 page_size = 2;    // Max items per page
    string page_token = 3;  // Opaque token for next page
}

message ListResponse {
    string trace_id = 1;
    repeated Item items = 2;
    string next_page_token = 3;  // Empty if no more pages
    int32 total_count = 4;       // Optional total count
}
```

---

## Project Structure

```
api/
├── proto/
│   └── user/
│       └── v1/
│           └── user.proto
├── gen/
│   └── user/
│       └── v1/
│           ├── user.pb.go
│           └── user_grpc.pb.go
└── buf.yaml
```

### buf.yaml Example

```yaml
version: v1
name: buf.build/myorg/myapp
deps:
  - buf.build/googleapis/googleapis
lint:
  use:
    - DEFAULT
  except:
    - PACKAGE_VERSION_SUFFIX
breaking:
  use:
    - FILE
```

### Generation Commands

```bash
# Using buf
buf generate

# Or using protoc
protoc \
  --go_out=. \
  --go_opt=paths=source_relative \
  --go-grpc_out=. \
  --go-grpc_opt=paths=source_relative \
  api/proto/user/v1/user.proto
```

---

## Validation

When reviewing or creating `.proto` files:

- [ ] Every request/response message has `trace_id` as field 1
- [ ] Field names use snake_case
- [ ] Enums have UNSPECIFIED as value 0
- [ ] Timestamps use `google.protobuf.Timestamp`
- [ ] Pagination uses `page_token` pattern
- [ ] Package includes version (e.g., `user.v1`)
- [ ] `go_package` option is set correctly
