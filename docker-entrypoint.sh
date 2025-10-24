#!/bin/sh
set -e

# Error handling function
handle_error() {
    echo "Error occurred in docker-entrypoint.sh at line $1"
    exit 1
}

# Set error trap
trap 'handle_error $LINENO' ERR

echo "Starting eSIM Enterprise Management System..."

# Validate required environment variables
if [ -z "$DATABASE_URL" ]; then
    echo "ERROR: DATABASE_URL environment variable is required"
    exit 1
fi

if [ -z "$JWT_SECRET" ]; then
    echo "ERROR: JWT_SECRET environment variable is required"
    exit 1
fi

# Wait for database to be ready
echo "Waiting for database connection..."
timeout=30
counter=0

while [ $counter -lt $timeout ]; do
    if node -e "
        const { Client } = require('pg');
        const client = new Client({ connectionString: process.env.DATABASE_URL });
        client.connect()
            .then(() => {
                console.log('Database connection successful');
                client.end();
                process.exit(0);
            })
            .catch((err) => {
                console.log('Database connection failed:', err.message);
                process.exit(1);
            });
    " 2>/dev/null; then
        echo "Database is ready"
        break
    fi
    
    counter=$((counter + 1))
    echo "Waiting for database... ($counter/$timeout)"
    sleep 1
done

if [ $counter -eq $timeout ]; then
    echo "ERROR: Database connection timeout after $timeout seconds"
    exit 1
fi

# Run database migrations if needed
echo "Running database migrations..."
cd /app/backend
if [ -f "dist/migrate.js" ]; then
    node dist/migrate.js || {
        echo "ERROR: Database migration failed"
        exit 1
    }
    echo "Database migrations completed"
else
    echo "No migration script found, skipping..."
fi

# Start services based on environment
if [ "$NODE_ENV" = "production" ]; then
    echo "Starting production services..."
    
    # Start backend server in background
    echo "Starting backend server on port $PORT..."
    cd /app/backend
    node dist/server.js &
    BACKEND_PID=$!
    
    # Verify backend is running
    sleep 5
    if ! kill -0 $BACKEND_PID 2>/dev/null; then
        echo "ERROR: Backend server failed to start"
        exit 1
    fi
    echo "Backend server started successfully (PID: $BACKEND_PID)"
    
    # Start frontend server
    echo "Starting frontend server on port $FRONTEND_PORT..."
    cd /app/frontend
    
    # Use serve to host the built frontend
    npx serve -s build -l $FRONTEND_PORT &
    FRONTEND_PID=$!
    
    # Verify frontend is running
    sleep 3
    if ! kill -0 $FRONTEND_PID 2>/dev/null; then
        echo "ERROR: Frontend server failed to start"
        kill $BACKEND_PID 2>/dev/null || true
        exit 1
    fi
    echo "Frontend server started successfully (PID: $FRONTEND_PID)"
    
    # Function to handle shutdown
    shutdown() {
        echo "Shutting down services..."
        kill $BACKEND_PID 2>/dev/null || true
        kill $FRONTEND_PID 2>/dev/null || true
        wait $BACKEND_PID 2>/dev/null || true
        wait $FRONTEND_PID 2>/dev/null || true
        echo "Services stopped"
        exit 0
    }
    
    # Set up signal handlers
    trap shutdown SIGTERM SIGINT
    
    echo "All services started successfully"
    echo "Backend: http://localhost:$PORT"
    echo "Frontend: http://localhost:$FRONTEND_PORT"
    echo "Health check: http://localhost:$PORT/health"
    
    # Wait for services
    wait $BACKEND_PID $FRONTEND_PID
    
else
    echo "Starting development services..."
    cd /app/backend
    exec node dist/server.js
fi