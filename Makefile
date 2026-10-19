.PHONY: up down logs check test migrate superuser seed

up:
	docker compose up -d --build --wait

down:
	docker compose down

logs:
	docker compose logs -f web

check:
	docker compose exec web python manage.py check

test:
	docker compose exec web python manage.py test --verbosity 2

migrate:
	docker compose exec web python manage.py migrate

superuser:
	docker compose exec web python manage.py createsuperuser

seed:
	docker compose exec web python manage.py seed_demo
