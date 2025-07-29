# Node.js Development Standards

## Language-Specific Commands
```bash
npm test           # Run single tests during development
npm run test:watch # Continuous testing 
npm run lint       # ESLint validation
npm run format     # Prettier formatting
npm run typecheck  # TypeScript validation
```

## Code Style Preferences
- **Modules**: Use ES modules (`import/export`)
- **Naming**: camelCase for variables/functions, PascalCase for classes, kebab-case for files
- **Constants**: UPPERCASE for environment variables
- **Documentation**: JSDoc with TypeDoc compatible tags for all public APIs

## Node.js Workflow Notes
- Prefer `npm ci` for consistent installs in containers
- Use TypeScript for better development experience
- Run single tests frequently, full suite before commits
- Always handle async errors with proper try/catch or .catch()
