.PHONY: dev dev-server dev-client build client test format check run docker clean

## dev: run the API server and the client dev server (with live reload) together
dev:
	@$(MAKE) -j2 dev-server dev-client

dev-server:
	cd server && gleam run

dev-client:
	cd client && gleam run -m lustre/dev start

## build: compile the client into server/priv/static
build client:
	cd client && gleam run -m lustre/dev build

## run: build the client, then serve everything from the Gleam server on :8000
run: build
	cd server && gleam run

## test: run every test suite (shared on both targets)
test:
	cd shared && gleam test --target erlang && gleam test --target javascript
	cd server && gleam test
	cd client && gleam test

## format: format all Gleam code
format:
	gleam format shared server client

## check: what CI runs
check:
	gleam format --check shared server client
	$(MAKE) test

## docker: build a production image
docker:
	docker build -t gleam-fullstack .

clean:
	rm -rf shared/build server/build client/build server/priv/static/*.js server/priv/static/*.css server/priv/static/*.html
