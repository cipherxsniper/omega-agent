# Use standard official slim Python image
FROM python:3.11-slim

# Set system environment dependencies
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DEBIAN_FRONTEND=noninteractive

# Set build workspaces
WORKDIR /app

# Install standard Linux package requirements (git, curl, compilers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy python dependencies and compile
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy current directory codebase
COPY . /app/

# Expose service ports if any API routers are present
EXPOSE 8000

# Set entry runner script
CMD ["python", "-m", "agent.main"]
