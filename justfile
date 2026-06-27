# Show available targets
help:
  just --list

start:
	docker compose up --detach --remove-orphans # --pull always

stop:
	docker compose down --remove-orphans

clean:
	docker compose down --volumes --remove-orphans

restart: stop start

logs:
	docker compose logs --follow lgtm
