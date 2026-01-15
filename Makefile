.PHONY: setup generate run clean

VENV_BIN = .venv/bin/python

setup:
	uv venv
	uv pip install tomli tomli-w requests pyyaml

generate:
	$(VENV_BIN) generate_compose.py --scenario scenario.toml

run: generate
	docker compose up --build --abort-on-container-exit --exit-code-from agentbeats-client

clean:
	docker compose down -v
	rm -rf output/* docker-compose.yml a2a-scenario.toml .env .venv
