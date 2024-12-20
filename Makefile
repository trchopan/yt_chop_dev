SHELL := /bin/bash

help:
	@echo "Available commands:"
	@echo "  make up           - Turn on the dev environment"
	@echo "  make prod-up      - Turn on the prod environment"
	@echo "  make dev          - Run the iex environment"
	@echo "  make down         - Turn off the dev environment"
	@echo "  make gen-release  - Gen Release"
	@echo "  make release      - Release"
	@echo "  make prod         - Run prod"

# Build or rebuild services
up:
	docker compose up -d

prod-up:
	docker compose -f docker-compose.prod.yaml up -d

dev:
	source .env && iex -S mix phx.server

down:
	docker compose down

migrate:
	_build/prod/rel/yt_chop_dev/bin/yt_chop_dev eval "YtChopDev.Release.migrate"

gen-release:
	 mix phx.gen.release

release:
	source .env
	mix deps.get --prod
	MIX_ENV=prod mix compile
	MIX_ENV=prod mix assets.deploy
	MIX_ENV=prod mix release

prod:
	_build/prod/rel/yt_chop_dev/bin/yt_chop_dev start

reload-systemd:
	sudo systemctl daemon-reload && sudo systemctl reload-or-restart yt-chop-dev.service



