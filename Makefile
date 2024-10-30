postgres:
	docker run --name postgres12 --network bank-network -e POSTGRES_USER=root -e POSTGRES_PASSWORD=secret -p 5433:5432 -d postgres:12-alpine

createdb:
	docker exec -it postgres12 createdb --username=root --owner=root simple_bank

dropdb:
	docker exec -it postgres12 dropdb simple_bank

migrate-up:
	migrate -path db/migration -database "postgresql://root:mastersecret@simple-bank.cd0acww8evw4.eu-west-1.rds.amazonaws.com:5432/simple_bank" -verbose up

migrate-up1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5433/simple_bank?sslmode=disable" -verbose up 1

migrate-down:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5433/simple_bank?sslmode=disable" -verbose down

migrate-down1:
	migrate -path db/migration -database "postgresql://root:secret@localhost:5433/simple_bank?sslmode=disable" -verbose down 1

sqlc:
	sqlc generate

test:
	go test -v -cover ./...

server:
	go run main.go

mock:
	mockgen -package mockdb -destination db/mock/store.go github.com/bakhtybayevn/simplebank/db/sqlc Store

.PHONY: postgres createdb dropdb migrate-up migrate-up1 migrate-down migrate-down1 sqlc test server