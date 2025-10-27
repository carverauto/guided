# Security Configuration

## Environment Variables

This project uses environment variables to manage sensitive configuration. **Never commit secrets to version control.**

### Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Update `.env` with your actual values:
   ```bash
   # Database Configuration
   DATABASE_USERNAME=postgres
   DATABASE_PASSWORD=your_secure_password_here
   DATABASE_HOSTNAME=localhost
   DATABASE_PORT=5455
   DATABASE_NAME=guided

   # Phoenix Configuration
   PORT=4000
   SECRET_KEY_BASE=$(mix phx.gen.secret)
   ```

3. Generate a secure secret key base:
   ```bash
   mix phx.gen.secret
   ```

4. The `.env` file is already in `.gitignore` and will not be committed.

### Development

The development environment (`config/dev.exs`) will fall back to default values if environment variables are not set, making it easy to get started. However, for production deployments, all required environment variables must be set.

### Production

Production configuration (`config/runtime.exs`) requires these environment variables:

- `DATABASE_URL` - Full database connection string
- `SECRET_KEY_BASE` - Secret key for signing/encrypting cookies
- `PHX_HOST` - Public hostname
- `PORT` - HTTP port (default: 4000)

### Scripts Directory

The `/scripts` directory contains development-only scripts with hard-coded credentials for testing. This directory is excluded from version control via `.gitignore`.

Do not use these scripts in production environments.
