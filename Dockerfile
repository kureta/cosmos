# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

# Install the project into `/app`
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Install the project's dependencies using the lockfile and settings
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=uv.lock,target=uv.lock \
  --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
  uv sync --frozen --no-install-project --no-dev

# TODO: Separate below section into a `production` image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS production
# Then, add the rest of the project source code and install it
# Installing separately from its dependencies allows optimal layer caching
COPY --from=builder /app /app
COPY . /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

WORKDIR /app
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --frozen --no-dev

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"
RUN python -m compileall -f /app/src
# Run the FastAPI application by default
CMD ["cosmos"]


# TODO: Make this into a development image based on `builder`
# Add all config files, zsh, nvim, etc. into this image.
# Then, use a final image without uv
FROM python:3.12-slim-bookworm AS runtime
# It is important to use the image that matches the builder, as the path to the
# Python executable must be the same, e.g., using `python:3.11-slim-bookworm`
# will fail.

# Copy the application from the builder
COPY --from=builder /app /app

# Create a user to run the application
RUN useradd -m app \
  && chown -R app /app

# Switch to the user
USER app

# Place executables in the environment at the front of the path
ENV PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Remove jupyter news prompt
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

# Run the FastAPI application by default
CMD ["python", "/app/hello.py"]


# TODO: Make a `test` image to run all tests in
# Only add test dependencies, run tests, and exit.
