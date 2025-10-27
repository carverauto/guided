# Contributing to Guided.dev

Thank you for your interest in contributing to Guided.dev! We're building the missing link between AI coding assistants and best-practice software development, and we'd love your help.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please be respectful, inclusive, and considerate in all interactions.

## Getting Started

### Understanding the Project

Before contributing, familiarize yourself with:

1. **The Vision**: Read [GitHub Issue #1](https://github.com/your-org/guided/issues/1) for the complete PRD
2. **The Implementation Plan**: See [docs/implementation_plan.md](docs/implementation_plan.md)
3. **Current Progress**: Check [SETUP_COMPLETE.md](SETUP_COMPLETE.md) for Phase 0 completion status

### Finding Something to Work On

- Check the [Issues page](https://github.com/your-org/guided/issues)
- Look for `good-first-issue` labels for beginner-friendly tasks
- Look for `help-wanted` labels for areas where we need help
- Check the project board for Phase 1 and Phase 2 tasks

## Development Setup

### Quick Setup

We provide an automated setup script:

```bash
./scripts/dev_setup.sh
```

### Manual Setup

For detailed manual setup instructions, see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

1. **Code Contributions**
   - New features (aligned with the implementation plan)
   - Bug fixes
   - Performance improvements
   - Refactoring

2. **Knowledge Graph Contributions**
   - Adding new technologies
   - Adding security vulnerabilities
   - Adding best practices and secure coding patterns
   - Adding deployment patterns

3. **Documentation**
   - Improving setup guides
   - Adding code comments
   - Writing tutorials
   - Fixing typos

4. **Testing**
   - Writing tests for existing features
   - Improving test coverage
   - Testing edge cases

5. **Design & UX**
   - UI/UX improvements for the admin interface (Phase 1)
   - Accessibility improvements

### Reporting Bugs

When reporting bugs, please include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the behavior
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**: OS, Elixir version, Docker version
- **Logs**: Relevant error messages or logs

### Suggesting Features

When suggesting features:

- Check if the feature aligns with the [PRD](https://github.com/your-org/guided/issues/1)
- Explain the use case and problem it solves
- Consider how it fits into the phased implementation plan
- Be open to discussion and feedback

## Pull Request Process

### Before You Start

1. **Check for existing work**: Search issues and PRs to avoid duplication
2. **Create or comment on an issue**: Discuss your proposed changes
3. **Fork the repository**: Create your own fork to work in

### Working on Your Contribution

1. **Create a branch**: Use descriptive branch names
   ```bash
   git checkout -b feature/add-nodejs-knowledge
   git checkout -b fix/graph-query-bug
   git checkout -b docs/improve-setup-guide
   ```

2. **Make your changes**:
   - Write clean, readable code
   - Follow the coding standards (see below)
   - Add or update tests
   - Update documentation if needed

3. **Test your changes**:
   ```bash
   mix test
   mix format --check-formatted
   mix precommit
   ```

4. **Commit your changes**:
   - Write clear commit messages
   - Reference related issues (e.g., "Fixes #123")
   ```bash
   git commit -m "Add Node.js to knowledge graph

   - Add Node.js as a Technology node
   - Add common Node.js vulnerabilities
   - Add security best practices
   - Update tests

   Fixes #123"
   ```

### Submitting a Pull Request

1. **Push to your fork**:
   ```bash
   git push origin feature/add-nodejs-knowledge
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear title describing the change
   - Description of what changed and why
   - Reference to related issues
   - Screenshots (if UI changes)
   - Checklist of completed items

3. **PR Template** (we'll add this to `.github/PULL_REQUEST_TEMPLATE.md`):
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update
   - [ ] Knowledge graph update

   ## Related Issues
   Fixes #(issue number)

   ## Testing
   - [ ] Tests pass (`mix test`)
   - [ ] Pre-commit checks pass (`mix precommit`)
   - [ ] Manual testing completed

   ## Documentation
   - [ ] Documentation updated (if needed)
   - [ ] Code comments added (if needed)
   ```

4. **Respond to feedback**: Be receptive to code review comments

### After Your PR is Merged

- Delete your branch (optional)
- Pull the latest changes from main
- Celebrate! You've contributed to Guided.dev 🎉

## Coding Standards

### Elixir Style Guide

We follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) with a few additions:

1. **Formatting**: Always run `mix format` before committing
   ```bash
   mix format
   ```

2. **Documentation**: Add `@moduledoc` and `@doc` to all public modules and functions
   ```elixir
   defmodule Guided.NewModule do
     @moduledoc """
     Brief description of what this module does.
     """

     @doc """
     Brief description of what this function does.

     ## Examples

         iex> NewModule.function_name(arg)
         {:ok, result}
     """
     def function_name(arg) do
       # implementation
     end
   end
   ```

3. **Naming Conventions**:
   - Use `snake_case` for functions and variables
   - Use `CamelCase` for modules
   - Use descriptive names

4. **Pattern Matching**: Use pattern matching for clarity
   ```elixir
   # Good
   def process({:ok, result}), do: result
   def process({:error, reason}), do: handle_error(reason)

   # Less ideal
   def process(result) do
     case result do
       {:ok, value} -> value
       {:error, reason} -> handle_error(reason)
     end
   end
   ```

5. **Pipes**: Use the pipe operator for function chains
   ```elixir
   # Good
   data
   |> transform()
   |> validate()
   |> save()

   # Less ideal
   save(validate(transform(data)))
   ```

### Graph Database Conventions

When working with the knowledge graph:

1. **Node Labels**: Use singular nouns in PascalCase
   - `Technology`, `Vulnerability`, `BestPractice`

2. **Relationship Types**: Use SCREAMING_SNAKE_CASE
   - `RECOMMENDED_FOR`, `HAS_VULNERABILITY`, `MITIGATED_BY`

3. **Properties**: Use `snake_case` for property names
   - `name`, `severity`, `owasp_rank`

4. **Cypher Queries**: Format for readability
   ```elixir
   query = """
   MATCH (t:Technology {name: $tech_name})
         -[:HAS_VULNERABILITY]->(v:Vulnerability)
         -[:MITIGATED_BY]->(sc:SecurityControl)
   RETURN t.name, v.name, sc.name
   ORDER BY v.severity DESC
   """
   ```

## Testing

### Running Tests

```bash
# Run all tests
mix test

# Run a specific test file
mix test test/guided/graph_test.exs

# Run tests with coverage
mix test --cover
```

### Writing Tests

1. **Test file naming**: `test/path/to/module_test.exs`
2. **Describe blocks**: Group related tests
   ```elixir
   defmodule Guided.GraphTest do
     use Guided.DataCase

     describe "create_node/2" do
       test "creates a node with valid attributes" do
         assert {:ok, _} = Graph.create_node("Technology", %{name: "Test"})
       end

       test "returns error with invalid attributes" do
         assert {:error, _} = Graph.create_node("Technology", %{})
       end
     end
   end
   ```

3. **Test coverage**: Aim for >80% coverage on new code
4. **Edge cases**: Test error conditions and edge cases

## Documentation

### Types of Documentation

1. **Code Documentation**: Add `@doc` to public functions
2. **README**: Keep the main README up to date
3. **Development Guide**: Update `docs/DEVELOPMENT.md` for setup changes
4. **Inline Comments**: Explain complex logic

### Documentation Standards

- Use proper grammar and punctuation
- Be concise but complete
- Include examples where helpful
- Keep documentation in sync with code

## Community

### Getting Help

- **Questions**: Open a [Discussion](https://github.com/your-org/guided/discussions)
- **Bugs**: Open an [Issue](https://github.com/your-org/guided/issues)
- **Chat**: [Join our community chat] (if available)

### Staying Updated

- Watch the repository for updates
- Follow the project roadmap
- Participate in discussions

## Recognition

We value all contributions! Contributors will be:

- Listed in a CONTRIBUTORS.md file
- Acknowledged in release notes
- Given credit in documentation they've written

## Questions?

If you have questions about contributing, please:

1. Check the [Development Guide](docs/DEVELOPMENT.md)
2. Search existing [Issues](https://github.com/your-org/guided/issues) and [Discussions](https://github.com/your-org/guided/discussions)
3. Open a new Discussion if you can't find an answer

Thank you for contributing to Guided.dev! Together we're building a better, more secure development ecosystem. 🚀
