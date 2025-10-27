# Development Setup Guide

Welcome to guided.dev! This guide will help you get your development environment up and running.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [Common Tasks](#common-tasks)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Erlang/OTP 28** or later
- **Elixir 1.19.1** or later
- **Docker** (for PostgreSQL with Apache AGE)
- **Git**

### Recommended Tools

- **asdf** - Version manager for Erlang and Elixir (recommended)
- **Docker Desktop** or **Docker Engine**

## Quick Start

If you're already familiar with Elixir/Phoenix development:

```bash
# 1. Clone and enter the repository
git clone https://github.com/your-org/guided.git
cd guided

# 2. Install Erlang and Elixir (if using asdf)
asdf install

# 3. Start PostgreSQL with Apache AGE
docker run \
  --name age \
  -p 5455:5432 \
  -e POSTGRES_USER=postgresUser \
  -e POSTGRES_PASSWORD=postgresPW \
  -e POSTGRES_DB=postgresDB \
  -d \
  apache/age

# 4. Install dependencies and setup
mix setup

# 5. Setup the graph database
mix graph.setup
mix graph.seed

# 6. Start the Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) in your browser!

## Detailed Setup

### 1. Install Erlang and Elixir

#### Using asdf (Recommended)

asdf is a version manager that allows you to manage multiple runtime versions easily.

1. **Install asdf** (if not already installed):

   ```bash
   # macOS (using Homebrew)
   brew install asdf

   # Linux (using Git)
   git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1
   ```

2. **Add asdf plugins for Erlang and Elixir**:

   ```bash
   asdf plugin add erlang
   asdf plugin add elixir
   ```

3. **Install the required versions** (defined in `.tool-versions`):

   ```bash
   # From the project root directory
   asdf install
   ```

#### Manual Installation

If you prefer not to use asdf:

- **macOS (using Homebrew)**:
  ```bash
  brew install erlang elixir
  ```

- **Ubuntu/Debian**:
  ```bash
  wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
  sudo dpkg -i erlang-solutions_2.0_all.deb
  sudo apt-get update
  sudo apt-get install esl-erlang elixir
  ```

Verify your installation:
```bash
elixir --version
# Should show: Elixir 1.19.1 (compiled with Erlang/OTP 28)
```

### 2. Install Docker

Docker is required to run PostgreSQL with the Apache AGE extension.

- **macOS**: [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
- **Linux**: [Docker Engine](https://docs.docker.com/engine/install/)
- **Windows**: [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)

Verify Docker is installed:
```bash
docker --version
```

### 3. Clone the Repository

```bash
git clone https://github.com/your-org/guided.git
cd guided
```

## Database Setup

guided.dev uses PostgreSQL with the **Apache AGE** extension to provide native graph database capabilities alongside traditional relational data.

### Start PostgreSQL with Apache AGE

1. **Pull and run the Apache AGE Docker image**:

   ```bash
   docker run \
     --name age \
     -p 5455:5432 \
     -e POSTGRES_USER=postgresUser \
     -e POSTGRES_PASSWORD=postgresPW \
     -e POSTGRES_DB=postgresDB \
     -d \
     apache/age
   ```

   **Port Note**: We use port `5455` (not the default `5432`) to avoid conflicts with any existing PostgreSQL installations.

2. **Verify the container is running**:

   ```bash
   docker ps
   ```

   You should see the `age` container in the list.

### Access the PostgreSQL Database

To access the database directly using `psql`:

```bash
docker exec -it age psql -d postgresDB -U postgresUser
```

Once inside psql, you can verify AGE is installed:

```sql
SELECT * FROM pg_available_extensions WHERE name = 'age';
\q  -- to exit
```

### Database Configuration

The application is pre-configured to connect to the Docker database. Configuration is in `config/dev.exs`:

- **Host**: `localhost`
- **Port**: `5455`
- **Database**: `postgresDB`
- **User**: `postgresUser`
- **Password**: `postgresPW`

These can be overridden with environment variables if needed (see `.env.example`).

## Running the Application

### First-Time Setup

1. **Install dependencies**:

   ```bash
   mix deps.get
   ```

2. **Create and migrate the database**:

   ```bash
   mix ecto.setup
   ```

3. **Setup the graph schema**:

   ```bash
   mix graph.setup
   ```

4. **Seed the knowledge graph**:

   ```bash
   mix graph.seed
   ```

   This populates the graph with initial data including:
   - Technologies (Python, Streamlit, SQLite, FastAPI)
   - Use cases (web apps, dashboards, APIs)
   - Vulnerabilities (OWASP Top 10)
   - Security controls and best practices
   - Deployment patterns

### Start the Development Server

```bash
mix phx.server
```

Or start it inside IEx (Elixir's interactive shell) for debugging:

```bash
iex -S mix phx.server
```

The application will be available at [`http://localhost:4000`](http://localhost:4000).

### Verify Graph Database

You can test the graph database from IEx:

```elixir
iex> Guided.Graph.query("MATCH (t:Technology) RETURN t.name LIMIT 5")
{:ok, [["Python"], ["Streamlit"], ["SQLite"], ["FastAPI"]]}
```

## Common Tasks

### Reset the Database

To completely reset the database (drop, create, migrate, seed):

```bash
mix ecto.reset
mix graph.setup
mix graph.seed
```

### Run Tests

```bash
mix test
```

### Run the Full Pre-commit Check

This runs compilation with warnings as errors, format checking, and tests:

```bash
mix precommit
```

### Format Code

```bash
mix format
```

### Update Dependencies

```bash
mix deps.get
mix deps.update --all
```

### Compile Assets

Frontend assets (CSS, JS) are built using esbuild and Tailwind:

```bash
mix assets.build
```

### Database Operations

```bash
# Create the database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback the last migration
mix ecto.rollback

# Check migration status
mix ecto.migrations
```

### Graph Database Operations

```bash
# Setup graph schema (verify graph is accessible)
mix graph.setup

# Seed the knowledge graph with initial data
mix graph.seed

# Reset the graph (clears and re-seeds)
mix graph.seed  # This automatically clears existing data
```

## Troubleshooting

### Docker Container Issues

**Problem**: Docker container won't start or port is already in use.

**Solution**:
```bash
# Check if port 5455 is in use
lsof -i :5455

# Stop and remove existing container
docker stop age
docker rm age

# Start fresh
docker run --name age -p 5455:5432 \
  -e POSTGRES_USER=postgresUser \
  -e POSTGRES_PASSWORD=postgresPW \
  -e POSTGRES_DB=postgresDB \
  -d apache/age
```

### Database Connection Errors

**Problem**: Can't connect to the database.

**Solution**:
1. Verify Docker container is running: `docker ps`
2. Check the logs: `docker logs age`
3. Test connection manually:
   ```bash
   docker exec -it age psql -d postgresDB -U postgresUser
   ```

### Mix Setup Fails

**Problem**: `mix setup` or `mix ecto.setup` fails.

**Solution**:
1. Ensure Docker container is running
2. Try individual steps:
   ```bash
   mix deps.get
   mix ecto.create
   mix ecto.migrate
   mix graph.setup
   mix graph.seed
   ```

### AGE Extension Not Found

**Problem**: Error about AGE extension not being available.

**Solution**:
1. Verify you're using the `apache/age` Docker image
2. Check AGE is installed:
   ```bash
   docker exec -it age psql -d postgresDB -U postgresUser -c "SELECT * FROM pg_available_extensions WHERE name = 'age';"
   ```

### Port Already in Use

**Problem**: Port 4000 (Phoenix) or 5455 (Postgres) is already in use.

**Solution**:
```bash
# For Phoenix (port 4000)
lsof -i :4000
kill -9 <PID>

# Or set a different port
PORT=4001 mix phx.server

# For Postgres (port 5455)
docker stop age
# Or change the port mapping in the docker run command
```

### Compilation Errors

**Problem**: Compilation errors after pulling new code.

**Solution**:
```bash
# Clean and recompile
mix clean
mix deps.clean --all
mix deps.get
mix compile
```

### Asset Build Failures

**Problem**: CSS or JS assets not loading.

**Solution**:
```bash
# Reinstall and rebuild assets
mix assets.setup
mix assets.build
```

## Docker Management

### Useful Docker Commands

```bash
# List all containers
docker ps -a

# Stop the database container
docker stop age

# Start the existing container
docker start age

# Remove the container (data will be lost)
docker rm age

# View container logs
docker logs age

# Follow logs in real-time
docker logs -f age

# Execute a command in the running container
docker exec -it age bash
```

### Persisting Data

The current setup does not persist data between container restarts. For development, this is usually fine since you can re-seed quickly.

To persist data, add a volume mount:

```bash
docker run \
  --name age \
  -p 5455:5432 \
  -e POSTGRES_USER=postgresUser \
  -e POSTGRES_PASSWORD=postgresPW \
  -e POSTGRES_DB=postgresDB \
  -v guided_pgdata:/var/lib/postgresql/data \
  -d \
  apache/age
```

## Development Workflow

1. **Create a new branch** for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and test locally:
   ```bash
   mix test
   mix precommit
   ```

3. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

4. **Push and create a pull request**:
   ```bash
   git push origin feature/your-feature-name
   ```

## Additional Resources

- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix/overview.html)
- [Elixir Documentation](https://elixir-lang.org/docs.html)
- [Apache AGE Documentation](https://age.apache.org/age-manual/master/intro/overview.html)
- [openCypher Query Language](https://opencypher.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/your-org/guided/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-org/guided/discussions)
- **PRD and Architecture**: See `docs/implementation_plan.md` and GitHub Issue #1

## Project Structure

```
guided/
├── assets/              # Frontend assets (CSS, JS)
├── config/              # Application configuration
├── docs/                # Documentation
├── lib/
│   ├── guided/          # Core application code
│   │   ├── graph.ex    # Graph database interface
│   │   └── repo.ex     # Ecto repository
│   ├── guided_web/      # Web interface (controllers, views, LiveView)
│   └── mix/
│       └── tasks/       # Custom Mix tasks
├── priv/
│   ├── repo/           # Database migrations and seeds
│   └── static/         # Static assets
├── scripts/            # Utility scripts
└── test/               # Tests
```

Happy coding!
