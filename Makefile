DB_URL=postgresql://root:secret@localhost:5433/simple_bank?sslmode=disable

network:
	docker network create bank-network

postgres:
	docker run --name postgres12 --network bank-network -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -p 5433:5432 -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

migrate-up:
	migrate -path db/migration -database "$(DB_URL)" -verbose up

migrate-up1:
	migrate -path db/migration -database "$(DB_URL)" -verbose up 1

migrate-down:
	migrate -path db/migration -database "$(DB_URL)" -verbose down

migrate-down1:
	migrate -path db/migration -database "$(DB_URL)" -verbose down 1

db_docs:
	dbdocs build doc/db.dbml

db_schema:
	dbml2sql --postgres -o doc/schema.sql doc/db.dbml

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/bakhtybayevn/simplebank/db/sqlc Store

.PHONY: postgres createdb dropdb migrate-up migrate-up1 migrate-down migrate-down1 db_docs db_schema sqlc test server