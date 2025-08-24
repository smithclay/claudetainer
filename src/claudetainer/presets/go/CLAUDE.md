# Go Development Standards

## Language-Specific Commands

Inspect the project to determine test, lint, format and other commands.

## Code Style Preferences
- **Project Structure**: cmd/, internal/, pkg/, api/ layout
- **Naming**: camelCase for private, PascalCase for public
- **Interfaces**: Small, focused interfaces with -er suffix
- **Error Handling**: Explicit error checking, wrapped errors with `fmt.Errorf`
- **Documentation**: GoDoc comments for all exported functions

## Go Workflow Notes
- Use table-driven tests with parallel execution
- Apply Clean Architecture patterns (handlers, services, repositories)
- Always propagate `context.Context` for cancellation/timeouts
- Use dependency injection via constructor functions
- Implement OpenTelemetry tracing for observability
- Run `goimports` and `golangci-lint` before commits
