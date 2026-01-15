# MedAgentBench AgentBeats Leaderboard

This repository hosts the official leaderboard runner for **MedAgentBench**, evaluating medical agents on clinical tasks using FHIR data and expert validation.

## Architecture

The benchmark consists of:

1.  **Green Agent** (`medagentbench-green-agent`): The environment/evaluator.
2.  **FHIR Server** (`medagentbench-fhir-server`): Provides the medical data context.
3.  **Purple Agent** (`medagentbench-purple-agent`): The participating agent being evaluated.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running.
- [Python 3.11+](https://www.python.org/)
- Make (optional, for automation)

## Quick Start

### 1. Setup

Install required Python dependencies:

```bash
make setup
```

### 2. Configure Credentials

Create a `.env` file or export the necessary API keys defined in `scenario.toml`:

```bash
export OPENROUTER_API_KEY=sk-...
export NEBIUS_API_KEY=sk-...
```

**Note**: You must be logged into GitHub Container Registry (GHCR) to pull the agent images:

```bash
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
```

### 3. Run the Benchmark

Generate configuring and run the assessment:

```bash
make run
```

This will:

- Generate `docker-compose.yml` from `scenario.toml`.
- Start the Green Agent, FHIR Server, and Purple Agent.
- Execute the assessment tasks.
- Output results to `output/results.json`.

## Configuration

The assessment is defined in `scenario.toml`.

### Agents

- **Green Agent**: `019bbe64-089b-7e12-b003-61c1ffb61999` (MedAgentBench Environment)
- **Purple Agent**: `019bbb38-e885-7000-8bd2-68e312757711` (Reference Participant)

### FHIR Server Access & GHCR Authentication

The Green Agent relies on a dedicated **FHIR Server** (`ghcr.io/udapy/medagentbench-fhir-server:latest`).

**Critical for Evalution**:
Since the FHIR server image is hosted on GHCR (possibly private), the environment running the leaderboard (GitHub Actions or local machine) MUST have valid credentials to pull `ghcr.io` images.

- **Local**: Run `docker login ghcr.io` before starting.
- **CI/CD (GitHub Actions)**: Ensure the `GHCR_TOKEN` secret is available to the workflow. The `run-scenario.yml` is already configured to login if this token is present.
- **Green Agent Connectivity**: The Green Agent container talks to the FHIR server internally via the Docker network. No extra authentication is needed _between_ these containers, but the _runner_ must be able to pull both images.

## Project Structure

- `scenario.toml`: Main configuration file.
- `generate_compose.py`: Generates the Docker Compose file, injecting the FHIR server dependency.
- `leaderboard-query.sql`: Reference SQL for querying top scores.
- `Makefile`: Automation commands.
