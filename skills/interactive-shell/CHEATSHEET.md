# Interactive Shell - STOP BEING A CAT

## ⚠️ THE THREE RULES (MEMORIZE THESE)

### Rule 1: PROMPT GOES IN COMMAND, NOT REASON
```typescript
// ❌ WRONG - Agent sits idle forever
interactive_shell({ command: 'pi', reason: 'Fix the bugs' })

// ✅ RIGHT - Prompt embedded in command  
interactive_shell({ command: 'pi "Fix the bugs"', reason: 'Bug fixing' })
```
`reason` = overlay header text only. Agent never sees it!

### Rule 2: PRESS ENTER (ADD \n OR keys)
```typescript
// ❌ WRONG - Text appears, no enter pressed
interactive_shell({ sessionId: "x", input: "hello" })

// ✅ RIGHT - Add newline
interactive_shell({ sessionId: "x", input: "hello\n" })

// ✅ RIGHT - Or use keys
interactive_shell({ sessionId: "x", input: { text: "hello", keys: ["enter"] } })
```

### Rule 3: HANDS-FREE = START → QUERY → KILL
```typescript
// 1. START (returns immediately!)
interactive_shell({ 
  command: 'pi "Do the thing"',  // ← prompt HERE
  mode: "hands-free" 
})
// → { sessionId: "calm-reef" }

// 2. QUERY (wait 30-60s between checks)
interactive_shell({ sessionId: "calm-reef" })
// → { status: "running", output: "..." }

// 3. KILL (when task looks done!)
interactive_shell({ sessionId: "calm-reef", kill: true })
```

---

## Quick Patterns

### Fire-and-Forget (Single Task)
```typescript
interactive_shell({
  command: 'pi "Review code, save to /tmp/review.md"',
  mode: "hands-free",
  handsFree: { autoExitOnQuiet: true }  // auto-kills after 5s silence
})
// Read result from file later
```

### Multi-Turn (Back and Forth)
```typescript
// Start
interactive_shell({ command: 'pi "Start working"', mode: "hands-free" })

// Send more input
interactive_shell({ sessionId: "x", input: "Now do step 2\n" })

// Kill when done
interactive_shell({ sessionId: "x", kill: true })
```

### Send Special Keys
```typescript
interactive_shell({ sessionId: "x", input: { keys: ["ctrl+c"] } })
interactive_shell({ sessionId: "x", input: { keys: ["down", "down", "enter"] } })
```

---

## Common Mistakes Checklist

Before each call, verify:
- [ ] Prompt is IN the `command` string, not in `reason`
- [ ] Input text ends with `\n` OR includes `keys: ["enter"]`
- [ ] For hands-free: I have a plan to query and kill the session
- [ ] I'm not querying more than once per 60 seconds

---

## CLI Prompt Formats

| Agent | Format |
|-------|--------|
| pi | `pi "prompt"` |
| claude | `claude "prompt"` |
| codex | `codex "prompt"` |
| gemini | `gemini -i "prompt"` |
