# Simple PostgreSQL + basic API container
FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install PostgreSQL and basic tools
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-client \
    postgresql-contrib \
    curl \
    wget \
    supervisor \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install simple Python web framework for API
RUN pip3 install flask flask-cors psycopg2-binary

# Setup PostgreSQL
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER streaming WITH SUPERUSER PASSWORD 'streaming_pass_2024';" && \
    createdb -O streaming streaming_hub && \
    psql streaming_hub --command "CREATE TABLE cameras (id SERIAL PRIMARY KEY, name VARCHAR(255), stream_url VARCHAR(500), created_at TIMESTAMP DEFAULT NOW());"

USER root

# Create app directory  
WORKDIR /app

# Create simple API server
COPY <<EOF /app/api_server.py
#!/usr/bin/env python3
from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import json

app = Flask(__name__)
CORS(app)

DB_CONFIG = {
    'host': 'localhost',
    'database': 'streaming_hub', 
    'user': 'streaming',
    'password': 'streaming_pass_2024'
}

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "service": "streaming-hub"})

@app.route('/api/cameras', methods=['GET'])
def get_cameras():
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("SELECT id, name, stream_url, created_at FROM cameras")
        cameras = []
        for row in cur.fetchall():
            cameras.append({
                'id': row[0],
                'name': row[1], 
                'stream_url': row[2],
                'created_at': str(row[3])
            })
        cur.close()
        conn.close()
        return jsonify(cameras)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/cameras', methods=['POST'])
def add_camera():
    try:
        data = request.get_json()
        name = data.get('name')
        stream_url = data.get('stream_url')
        
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("INSERT INTO cameras (name, stream_url) VALUES (%s, %s) RETURNING id", 
                   (name, stream_url))
        camera_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"id": camera_id, "name": name, "stream_url": stream_url})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4000, debug=True)
EOF

# Create supervisor config
COPY <<EOF /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgresql]
command=su postgres -c '/usr/lib/postgresql/14/bin/postgres -D /var/lib/postgresql/14/main -c config_file=/etc/postgresql/14/main/postgresql.conf'
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/postgresql.err.log
stdout_logfile=/var/log/supervisor/postgresql.out.log

[program:api_server]
command=python3 /app/api_server.py
directory=/app
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/api.err.log
stdout_logfile=/var/log/supervisor/api.out.log
EOF

# Make API server executable
RUN chmod +x /app/api_server.py

# Expose ports
EXPOSE 5432 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD pg_isready -U streaming -d streaming_hub && curl -f http://localhost:4000/api/health || exit 1

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]