# Use the existing Supabase Realtime container structure
FROM ubuntu:22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-15 \
    postgresql-client-15 \
    curl \
    wget \
    gnupg \
    supervisor \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Erlang/Elixir
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i erlang-solutions_2.0_all.deb && \
    apt-get update && \
    apt-get install -y esl-erlang elixir && \
    rm erlang-solutions_2.0_all.deb && \
    rm -rf /var/lib/apt/lists/*

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Setup PostgreSQL
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER realtime WITH SUPERUSER PASSWORD 'realtime_pass_2024';" && \
    createdb -O realtime realtime_dev

USER root

# Create app directory  
WORKDIR /app

# Copy ALL the existing Supabase files
COPY . .

# Install dependencies and compile
RUN mix deps.get && \
    mix compile

# Expose ports
EXPOSE 5432 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD pg_isready -U realtime -d realtime_dev && curl -f http://localhost:4000/api/health || exit 1

# Use the existing supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]