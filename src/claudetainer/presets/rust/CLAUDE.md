# Rust Development Standards

## Language-Specific Commands
```bash
cargo test            # Run single tests during development
cargo test --watch    # Continuous testing (with cargo-watch)
cargo clippy          # Linting and code analysis
cargo fmt             # Code formatting
cargo check           # Fast compilation check
cargo bench           # Benchmarking for performance
```

## Code Style Preferences
- **Naming**: snake_case for functions/variables, PascalCase for types/structs
- **Modules**: Use `mod` and `pub mod` for organization
- **Error Handling**: `Result<T, E>` for fallible operations, `?` operator for propagation
- **Documentation**: rustdoc comments (`///`) for all public APIs

## Rust Workflow Notes
- Use TDD approach for complex business logic
- Leverage Rust's zero-cost abstractions (iterators, closures)
- Prefer references over cloning for performance
- Use `cargo test --lib` for unit tests, `cargo test --tests` for integration
- Run `cargo clippy` before commits to catch common issues
- Profile with `cargo flamegraph` for performance optimization
