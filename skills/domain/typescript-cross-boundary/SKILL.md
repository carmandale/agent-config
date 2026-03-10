---
name: typescript-cross-boundary
description: TypeScript patterns for code crossing module, process, or abstraction boundaries. Use when accepting both rich and minimal types (structural subtyping), deferring value resolution (lazy evaluation), or extracting shared code across modules.
---

# TypeScript Cross-Boundary Patterns

Heuristics for TypeScript code that crosses module, process, or abstraction boundaries.

## When to Use

- A function needs to accept both a rich context (ExtensionContext) and a minimal one (CLI)
- A value isn't available at object creation but is needed later
- Code is being extracted from one module to be shared across two

## Pattern 1: Structural Subtyping Over Casts

When a function needs to work with both a rich type and a minimal caller:

### DO
```typescript
// Define the minimal shape the function actually needs
export interface HandlerContext {
  cwd: string;
  hasUI: boolean;
  model?: { id: string };
}

// The function accepts the minimal shape
function executeReserve(ctx: HandlerContext, paths: string[]) { ... }

// Rich types structurally satisfy it — no cast needed
const extensionCtx: ExtensionContext = { cwd, hasUI: true, model, tools, ... };
executeReserve(extensionCtx, paths); // ✅ works without cast
```

### DON'T
```typescript
// Casting hides type errors and breaks when the target type changes
executeReserve({ cwd, hasUI: false } as any, paths); // ❌
executeReserve(ctx as ExtensionContext, paths); // ❌
```

**Why:** `as any` silences the compiler but doesn't make the types compatible. If ExtensionContext adds a required field later, casts won't catch it. Structural subtyping means the compiler enforces the contract.

## Pattern 2: Lazy Evaluation for Deferred Values

When a value is null at creation time but available when needed:

### DO
```typescript
interface TimerConfig {
  taskId: string | (() => string);  // Accept getter for lazy resolution
}

function createTimer(config: TimerConfig) {
  return () => {
    const id = typeof config.taskId === 'function' ? config.taskId() : config.taskId;
    log(`Timer fired for ${id}`);
  };
}

// Callsite where value is known at creation
createTimer({ taskId: "task-1" });

// Callsite where value is set later
let assignedTaskId: string | null = null;
createTimer({ taskId: () => assignedTaskId ?? "unknown" });
```

### DON'T
```typescript
// Capturing null at creation, hoping it's set by fire time
const id = assignedTaskId; // ❌ Captures null, not the future value
createTimer({ taskId: id ?? "unknown" }); // Always "unknown"
```

**Why:** JavaScript closures capture the *variable binding*, not the *value*. But when you assign to a local `const`, you snapshot the value. Use a getter function to defer evaluation.

## Evidence

- **spec-003 R3**: 6 `as any` casts replaced with HandlerContext structural subtype
- **spec-003 R4**: stuck-timer taskId as `string | (() => string)` for lobby workers whose assignedTaskId is null at timer creation
- **spec-002**: RuntimeAdapter interface — minimal contract for adapter implementations
