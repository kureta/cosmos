# Base for production image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS prod-base

# Set the working directory and ensure it is owned by the user `app`
WORKDIR /app

# Compile for faster startup and set link mode to copy
# since `.cache` is mounted as a, well, cache
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev

# Install the application
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen --no-dev

# ===================================================================
# Production image
FROM python:3.12-slim-bookworm AS production

# Set the working directory and ensure it is owned by the user `app`
WORKDIR /app

# Create a user and group with a fixed UID and GID of 1000
RUN groupadd -g 1000 app && useradd -m -u 1000 -g app -s /bin/bash app

# Copy from the `builder` stage while setting ownership to `app:app`
# NOTE: Using `RUN chmod ...` causes the image to be larger
#      because it creates a new layer with the changes.
COPY --chown=app:app --from=prod-base /app /app

# Switch to the app user
USER app

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"
RUN python -m compileall -f /app/src
CMD ["cosmos"]

# ===================================================================
# TODO: Make this into a development image based on `builder`
# Add all config files, zsh, nvim, etc. into this image.
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS dev-base

# Set the working directory and ensure it is owned by the user `app`
WORKDIR /app

# Set link mode to copy since `.cache` is mounted as cache
ENV UV_LINK_MODE=copy

# Install all dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --no-install-project

# Install the application
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync

# Development image
# ===================================================================
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS development

# Set the working directory and ensure it is owned by the user `app`
WORKDIR /app

# App is in a bind mount, cache is in the container
ENV UV_LINK_MODE=copy

# Create a user and group with a fixed UID and GID of 1000
RUN groupadd -g 1000 app && useradd -m -u 1000 -g app -s /bin/bash app

# Copy from the `builder` stage while setting ownership to `app:app`
COPY --chown=app:app --from=dev-base /app /app

# # Switch to the app user
USER app

CMD ["uv", "run", "cosmos"]

# TODO: Make a `test` image to run all tests in
# Only add test dependencies, run tests, and exit.
