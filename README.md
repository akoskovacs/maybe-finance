![Finachy Dashboard](/docs/common/finachy_dash.png)

# :moneybag: Finachy
| **Self-Hosted Financial Freedom**

## :wave: Hey!
Finachy is a fully working personal finance app that can be [self hosted with Docker](#whale-running-the-application-via-docker).

## :whale: Running the application via Docker

Finachy is easiest to run using Docker. Below you will find examples for both Docker Compose and the `docker` CLI, as well as a reference for all available environment variables.

### Docker CLI Example

If you prefer to run the container directly (requires a separate Postgres and Redis instance), you can use the following command:

```bash
docker run -d \
  -p 3000:3000 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e DB_HOST=postgres_host \
  -e POSTGRES_PASSWORD=my_password \
  -e REDIS_URL=redis://redis_host:6379/1 \
  finachium/finachy:latest
```

### Docker Compose Example

If you don't have Postgres and Redis running, you can use the following Docker Compose configuration, which configures them as well to work with the instance:

```yaml
x-db-env: &db_env
  POSTGRES_USER: ${POSTGRES_USER:-finachy_user}
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-finachy_password}
  POSTGRES_DB: ${POSTGRES_DB:-finachy_production}

x-rails-env: &rails_env
  <<: *db_env
  SECRET_KEY_BASE: ${SECRET_KEY_BASE:-a7523c3d0ae56415046ad8abae168d71074a79534a7062258f8d1d51ac2f76d3c3bc86d86b6b0b307df30d9a6a90a2066a3fa9e67c5e6f374dbd7dd4e0778e13}
  SELF_HOSTED: "true"
  RAILS_FORCE_SSL: "false"
  RAILS_ASSUME_SSL: "false"
  DB_HOST: db
  DB_PORT: 5432
  REDIS_URL: redis://redis:6379/1
# NOTE: enabling OpenAI will incur costs when you use AI-related features in the app (chat, rules).  Make sure you have set appropriate spend limits on your account before adding this.
  OPENAI_ACCESS_TOKEN: ${OPENAI_ACCESS_TOKEN:-}

services:
  web:
    image: finachium/finachy:latest
    volumes:
      - app-storage:/rails/storage
    ports:
      - 3000:3000
    restart: unless-stopped
    environment:
      <<: *rails_env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - finachy_net

  worker:
    image: finachium/finachy:latest
    command: bundle exec sidekiq
    restart: unless-stopped
    depends_on:
      redis:
        condition: service_healthy
    environment:
      <<: *rails_env
    networks:
      - finachy_net

  db:
    image: postgres:16
    restart: unless-stopped
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      <<: *db_env
    healthcheck:
      test: [ "CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB" ]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - finachy_net

  redis:
    image: redis:latest
    restart: unless-stopped
    volumes:
      - redis-data:/data
    healthcheck:
      test: [ "CMD", "redis-cli", "ping" ]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - finachy_net

volumes:
  app-storage:
  postgres-data:
  redis-data:

networks:
  finachy_net:
    driver: bridge
```

### .env Example

> [!IMPORTANT]
> **Security**: Always generate a new `SECRET_KEY_BASE` using `openssl rand -hex 64` for production deployments. Never use the example value shown above.

Create a `.env` file alongside your `compose.yml` with the following content. Customize the values as needed:

```bash
# ================================
# Database Configuration
# ================================
POSTGRES_USER=finachy_user
POSTGRES_PASSWORD=finachy_password
POSTGRES_DB=finachy_production

# ================================
# Application Security
# ================================
# Regenerate the secure random key with: openssl rand -hex 64
SECRET_KEY_BASE=a7523c3d0ae56415046ad8abae168d71074a79534a7062258f8d1d51ac2f76d3c3bc86d86b6b0b307df30d9a6a90a2066a3fa9e67c5e6f374dbd7dd4e0778e13

# ================================
# Optional: OpenAI Integration
# ================================
# NOTE: Enabling OpenAI will incur costs when you use AI-related features (chat, rules).
# Make sure you have set appropriate spend limits on your OpenAI account before adding this.
# OPENAI_ACCESS_TOKEN=sk-your-openai-api-key-here

# ================================
# Optional: Custom Configuration
# ================================
# Uncomment and customize these if needed:
# APP_DOMAIN=finachy.yourdomain.com
# PORT=3000
# SMTP_ADDRESS=smtp.example.com
# SMTP_PORT=465
# SMTP_USERNAME=your-smtp-username
# SMTP_PASSWORD=your-smtp-password
# EMAIL_SENDER=noreply@yourdomain.com
# SYNTH_API_KEY=your-synth-api-key
```
> [!TIP]
> The Docker Compose configuration automatically sets `SELF_HOSTED=true`, `RAILS_FORCE_SSL=false`, `RAILS_ASSUME_SSL=false`, `DB_HOST=db`, `DB_PORT=5432`, and `REDIS_URL=redis://redis:6379/1` for you. You don't need to include these in your `.env` file.


Then just start the containers with:

```bash
docker compose up
```

or in detached mode:

```bash
docker compose up -d
```

### Environment Variables

Create an `.env` file alongside your `compose.yml` to customize your installation.

| Variable | Description | Default |
|----------|-------------|---------|
| **General** | | |
| `SELF_HOSTED` | Set to `true` to enable self-hosting features. | `true` |
| `SECRET_KEY_BASE` | Secret key for encryption. Generate with `openssl rand -hex 64`. | *(Example provided)* |
| `PORT` | Port for the application server (if not using Docker). | `3000` |
| `APP_DOMAIN` | The domain where your instance is hosted. | |
| **Database** | | |
| `DB_HOST` | Database hostname. | `db` (Docker) or `localhost` |
| `DB_PORT` | Database port. | `5432` |
| `POSTGRES_USER` | Postgres username. | `postgres` |
| `POSTGRES_PASSWORD` | Postgres password. | |
| **Email (SMTP)** | | |
| `SMTP_ADDRESS` | SMTP server address. | |
| `SMTP_PORT` | SMTP server port. | `465` |
| `SMTP_USERNAME` | SMTP username. | |
| `SMTP_PASSWORD` | SMTP password. | |
| `EMAIL_SENDER` | Email address displayed as sender. | |
| **Storage** | | |
| `ACTIVE_STORAGE_SERVICE` | `amazon` (S3) or `cloudflare` (R2). Defaults to disk. | |
| `S3_ACCESS_KEY_ID` | AWS Access Key ID. | |
| `S3_SECRET_ACCESS_KEY` | AWS Secret Access Key. | |
| `S3_REGION` | AWS Region. | `us-east-1` |
| `S3_BUCKET` | AWS Bucket Name. | |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare Account ID. | |
| `CLOUDFLARE_ACCESS_KEY_ID` | Cloudflare R2 Access Key ID. | |
| `CLOUDFLARE_SECRET_ACCESS_KEY`| Cloudflare R2 Secret Access Key. | |
| `CLOUDFLARE_BUCKET` | Cloudflare R2 Bucket Name. | |
| **Integrations** | | |
| `SYNTH_API_KEY` | Key for [Synth Finance](https://synthfinance.com/) (exchange rates/stocks). | |
| `OPENAI_ACCESS_TOKEN` | (Optional) OpenAI API Key for AI features. | |

### Troubleshooting

**Database initialization error**: If you see `initdb: error: directory "/var/lib/postgresql/data" exists but is not empty`, remove the old volumes:

```bash
docker compose down -v
docker compose up -d
```

**Note**: This will delete all existing database data.


## :wrench: Local Development Setup

[!WARNING] The instructions below are for developers to get started with contributing to the app.

### :bricks: Requirements

- See `.ruby-version` file for required Ruby version
- PostgreSQL >9.3 (ideally, latest stable version)

After cloning the repo, the basic setup commands are:

```sh
cd finachy

make up
make setup
make dev

# Optionally, load demo data
rake demo_data:default
```

And visit http://localhost:3000 to see the app. You can use the following
credentials to log in (generated by DB seed):

- Email: `user@finachy.local`
- Password: `password`

To stop the development services, you can run:
```sh
make down
```

You can also use `make help` to gather additional information.

#### Detailed description of each command

The first command is:
```sh
make up
```

This will download and start the required services (`PostgreSQL` and `redis` in particular) via `docker`.
Both of these run on unusual ports by design, in order to avoid conflicts with the host system,
since their network are bridge to it.

The description of the services can be found in `compose.dev.yml`.

Then you have to run:
```sh
make setup
```

Which will setup the development and testing databases. The configuration can be found in `.env.local` and `.env.test` respectively.

The last command is:
```sh
make dev
```

It will start the application and the background job handler. It will only work properly if the `DBMS` and `redis` are already running.

This command will not use `docker`, so it is much easier to update the application code or to start a fresh
environment without stopping the database.


<!-- ### Setup Guides
TODO:
- [Mac dev setup guide](https://github.com/finachium/finachy/wiki/Mac-Dev-Setup-Guide)
- [Linux dev setup guide](https://github.com/finachium/finachy/wiki/Linux-Dev-Setup-Guide)
- [Windows dev setup guide](https://github.com/finachium/finachy/wiki/Windows-Dev-Setup-Guide)
- Dev containers - visit [this guide](https://code.visualstudio.com/docs/devcontainers/containers) to learn more -->


## :copyright: Copyright & license

Finachy is distributed under
an [AGPLv3 license](https://github.com/finachium/finachy/blob/main/LICENSE).

This software is based on Maybe Finance but is not affiliated with or endorsed by Maybe Finance Inc. `Maybe` is a trademark of Maybe Finance Inc.
