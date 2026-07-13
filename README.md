# OMEGA AGENT: Artificial Super-Intelligent (ASI) Autonomous Agent System

OMEGA AGENT is an experimental, production-grade Artificial Super-Intelligent (ASI) autonomous system featuring closed-loop self-reflection, multi-modal perception, self-directed STRIPS-style planning, self-modification/self-engineering capabilities with safety validation, and an oracle-level grading and benchmarking system.

## System Architecture

The core of OMEGA AGENT is built on five major architectural layers:

```
                  +-------------------------------------------------+
                  |                 Perception Layer                |
                  |     (Multi-Modal, Contextualizer, Monitor)      |
                  +------------------------+------------------------+
                                           |
                                           v
                  +-------------------------------------------------+
                  |                   OMEGA Brain                   |
                  |   (Reasoning, Memory, Goal, Self-Improvement)   |
                  +------------------------+------------------------+
                                           |
                                           v
                  +-------------------------------------------------+
                  |                  Action Engine                  |
                  |     (STRIPS Planner, Executor, Validator)       |
                  +------------------------+------------------------+
                                           |
                  +------------------------+------------------------+
                  |               Self-Engineering Engine           |
                  |     (Analyzer, Proposer, Test, Deploy, Git)    |
                  +------------------------+------------------------+
                                           |
                                           v
                  +-------------------------------------------------+
                  |                  Oracle Grader                  |
                  |     (Scoring Rubrics, Benchmarks, Leaderboard)  |
                  +-------------------------------------------------+
```

### 1. Central ASI Brain (`agent/core/omega_brain.py`)
- **Reasoning Engine**: Runs multi-hypothesis generation, scoring, and chain-of-thought (CoT) combined with meta-cognition and self-reflection loops.
- **Memory Manager**: Manages partitioned short-term, long-term, episodic, and semantic memory layers with automated consolidation.
- **Goal Manager**: Implements priority queues, sub-goal decomposition, and continuous progress tracking.
- **Self-Improvement Engine**: Dynamically analyzes the agent's performance profiles and updates behavioral strategies.

### 2. Perception Layer (`agent/core/perception.py`)
- **Multi-Modal Perception**: Normalizes text inputs, structured payloads, external API responses, and database results.
- **Contextualizer**: Continuously builds a synchronized representation of the world-state.
- **Anomaly Detector**: Computes baseline deviations on system metrics and action results to identify unexpected patterns.
- **Real-Time Monitor**: Background system health and performance watcher.

### 3. Action Execution Layer (`agent/core/action_engine.py`)
- **Action Planner**: Employs STRIPS-style (Stanford Research Institute Problem Solver) planning with preconditions and effects.
- **Action Executor**: Executes plans asynchronously with transactional rollback capability, detailed audit logs, and custom retry policies.
- **Action Validator**: Evaluates safety properties and pre-conditions before executing any high-privilege operations.
- **Side Effect Analyzer**: Estimates risk, structural changes, and performance cost prior to executing planned nodes.

### 4. Self-Engineering Engine (`agent/core/self_engineer.py`)
- **Code Analyzer**: Parses and analyzes the system's own source files.
- **Performance Profiler**: Compiles execution latencies and failure rates.
- **Improvement Proposer**: Uses LLMs / rule heuristics to propose structural code changes.
- **Test Runner**: Automatically discovers and validates test assertions on proposals.
- **Safe Deployer**: Executes canary verification with rollback mechanisms.
- **Git Integration**: Safely stages, commits, and pushes validated updates directly to GitHub.

### 5. Oracle Grading System (`agent/oracle/grading_system.py`)
- **Oracle Grader**: Standardizes performance metrics across accuracy, efficiency, creativity, safety, alignment, and financial impact.
- **Grade Tiers**:
  - `TRANSCENDENT` (Score >= 98)
  - `GENIUS` (Score >= 95)
  - `EXPERT` (Score >= 85)
  - `COMPUTENT` (Score >= 70)
  - `DEVELOPING` (Score < 70)
- **Benchmark Suite**: Runs automated integration test blocks.
- **Leaderboard Manager**: Persists high-score profiles and histories.

---

## Environment Variables

Configure the system using a `.env` file (copied from `.env.example`):

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Deployment environment (`development`, `production`) | `development` |
| `LOG_LEVEL` | Logging verbosity (`INFO`, `DEBUG`, `ERROR`) | `INFO` |
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql+asyncpg://postgres:postgres@localhost:5432/omega` |
| `REDIS_URL` | Redis Cache / Queue URL | `redis://localhost:6379/0` |
| `GITHUB_TOKEN` | Access Token for pushing updates to repository | (Required for Self-Engineer) |
| `GITHUB_USERNAME` | Username for repository authentication | (Required for Self-Engineer) |
| `OPENAI_API_KEY` | Model API key for reasoning / proposing code | (Required for LLM-based logic) |

---

## Getting Started

### Prerequisites
- Python 3.11+
- Docker & Docker Compose
- PostgreSQL & Redis (if running locally without Docker)

### Local Development Setup
1. Clone the repository and navigate to it:
   ```bash
   git clone https://github.com/cipherxsniper/omega-agent.git
   cd omega-agent
   ```
2. Create and source a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Copy environment template and fill in secrets:
   ```bash
   cp .env.example .env
   ```
5. Run the core system:
   ```bash
   python -m agent.main
   ```

### Docker Deployments
Build and deploy the entire multi-container service chain (Database, Cache, and Omega ASI Engine):
```bash
docker-compose -f docker/docker-compose.yml up --build -d
```
To review runtime logs:
```bash
docker-compose -f docker/docker-compose.yml logs -f omega-agent
```
