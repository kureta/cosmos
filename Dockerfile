# Base for production image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS prod-base

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

WORKDIR /app
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

# Create an `app` user and group
RUN groupadd -r app && useradd --no-log-init -r -g app app
# Set the working directory and ensure it is owned by the user `app`
WORKDIR /app

# Copy from the `builder` stage while setting ownership to `app:app`
COPY --from=prod-base --chown=app:app /app /app

# Switch to the app user
USER app

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"
RUN python -m compileall -f /app/src
CMD ["cosmos"]

# ===================================================================
# TODO: `development` image should have uv
# TODO: Make this into a development image based on `builder`
# Add all config files, zsh, nvim, etc. into this image.
# Then, use a final image without uv

# TODO: Make a `test` image to run all tests in
# Only add test dependencies, run tests, and exit.
