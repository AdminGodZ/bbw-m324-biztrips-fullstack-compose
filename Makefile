.PHONY: init up up-ecr smoke logs down reset
init:      ## clone/update the frontend and backend submodules (pinned release tags)
	git submodule update --init --recursive
up: init   ## build both images from the submodules and start everything
	docker compose up --build --wait
up-ecr:    ## start the released images from Amazon ECR (needs ECR_REGISTRY, see scripts/ecr-login.sh)
	docker compose -f compose.yaml -f compose.ecr.yaml up --wait
smoke:     ## end-to-end check (frontend, API, MariaDB, S3 photo round trip)
	./scripts/smoke-test.sh
logs:
	docker compose logs -f backend frontend
down:      ## stop, keep data
	docker compose down
reset:     ## stop and delete database + photos
	docker compose down -v
