# Claude-Flake Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching potential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## 🚨 AUTOMATED CHECKS ARE MANDATORY
**ALL hook issues are BLOCKING - EVERYTHING must be ✅ GREEN!**
No errors. No formatting issues. No linting problems. Zero tolerance.
These are not suggestions. Fix ALL issues before continuing.

## CRITICAL WORKFLOW - ALWAYS FOLLOW THIS

### Explore → Plan → Code → Commit
**NEVER JUMP STRAIGHT TO CODING!** Always follow this structured sequence:
1. **Explore**: Research the codebase, understand existing patterns and dependencies
2. **Plan**: Create a detailed implementation plan and verify it with me
3. **Code**: Implement with validation checkpoints and iterative improvement
4. **Commit**: Validate, test, and commit changes with proper documentation

When asked to implement any feature, you'll first say: "Let me explore the codebase and create a plan before implementing."

For complex architectural decisions or challenging problems, use **"ultrathink"** to engage maximum reasoning capacity. Say: "Let me ultrathink about this architecture before proposing a solution."

### USE MULTIPLE AGENTS
*Leverage subagents aggressively* for better results:

* Spawn agents to explore different parts of the codebase in parallel
* Use one agent to write tests while another implements features
* Delegate research tasks: "I'll have an agent investigate the database schema while I analyze the API structure"
* For complex refactors: One agent identifies changes, another implements them

Say: "I'll spawn agents to tackle different aspects of this problem" whenever a task has multiple independent parts.

### Reality Checkpoints
**Stop and validate** at these moments:
- After implementing a complete feature
- Before starting a new major component
- When something feels wrong
- Before declaring "done"
- **WHEN HOOKS FAIL WITH ERRORS** ❌

Run: `make fmt && make test && make lint`

> Why: You can lose track of what's actually working. These checkpoints prevent cascading failures.

### 🚨 CRITICAL: Hook Failures Are BLOCKING
**When hooks report ANY issues (exit code 2), you MUST:**
1. **STOP IMMEDIATELY** - Do not continue with other tasks
2. **FIX ALL ISSUES** - Address every ❌ issue until everything is ✅ GREEN
3. **VERIFY THE FIX** - Re-run the failed command to confirm it's fixed
4. **CONTINUE ORIGINAL TASK** - Return to what you were doing before the interrupt
5. **NEVER IGNORE** - There are NO warnings, only requirements

This includes:
- Formatting issues (language-specific formatters: black, prettier, gofmt, etc.)
- Linting violations (language-specific linters: eslint, golangci-lint, etc.)
- Language-specific anti-patterns and code smells
- ALL other checks

Your code must be 100% clean. No exceptions.

**Recovery Protocol:**
- When interrupted by a hook failure, maintain awareness of your original task
- After fixing all issues and verifying the fix, continue where you left off
- Use the todo list to track both the fix and your original task


## Context & Memory Management

### When context gets long
- Use `/clear` to reset and maintain focused context
- Re-read this CLAUDE.md file periodically (every 30+ minutes)
- Use TodoWrite tool to track tasks and maintain continuity
- Document current state before major changes
- Use the `#` key to quickly update documentation

### Visual Development
- Request screenshots when working on UI/UX features
- Use visual targets to guide implementation
- Iterate through multiple versions with user feedback

## Implementation Standards

### Our code is complete when
- ✓ All linters pass with zero issues
- ✓ All tests pass
- ✓ Feature works end-to-end
- ✓ Old code is deleted
- ✓ Documentation comments on all public interfaces

### Testing Strategy
- Use Test-Driven Development (TDD) for complex business logic
- Simple features → Write tests after implementation
- Hot paths → Add benchmarks for performance validation
- Skip tests for entry points and simple CLI parsing
- Run single tests during development, full suite before commit

## Problem-Solving Together

When you're stuck or confused:
1. **Stop** - Don't spiral into complex solutions
2. **Delegate** - Spawn agents for parallel investigation and verification
3. **Think Mode** - Use "ultrathink" for complex architectural challenges
4. **Step back** - Re-read requirements and existing patterns
5. **Simplify** - The simple solution is usually correct
6. **Ask** - "I see two approaches: [A] vs [B]. Which do you prefer?"
7. **Iterate** - Improve through multiple versions rather than perfect first attempts

My insights on better approaches are valued - please ask for them!

## Performance & Security

### **Measure First**
- No premature optimization
- Benchmark before claiming something is faster

### **Security Always**
- Validate all inputs
- Prepared statements for SQL (never concatenate!)

## Communication Protocol

### Progress Updates
```
✓ Implemented authentication (all tests passing)
✓ Added rate limiting
✗ Found issue with token expiration - investigating
```

### Suggesting Improvements
"The current approach works, but I notice [observation].
Would you like me to [specific improvement]?"

## Development Environment & Tools

### Git Workflow
- Use feature branches - no backwards compatibility needed
- Consider git worktrees for parallel task management
- Follow consistent branch naming conventions
- Plan merge strategies early in complex features

### Tool Integration
- Use MCP (Model Context Protocol) servers when available
- Install GitHub CLI (`gh`) for enhanced repository interactions
- Configure tool permissions carefully for security
- Leverage headless mode for automation workflows

### Custom Commands
- Create slash commands for repeated workflows
- Document common bash commands and shortcuts
- Establish code style preferences (modules, imports, etc.)
- Note environment setup requirements

## Working Together

- When in doubt, we choose clarity over cleverness
- **REMINDER**: If this file hasn't been referenced in 30+ minutes, RE-READ IT!
- Periodically refine these instructions for better adherence

Avoid complex abstractions. Keep it simple.
