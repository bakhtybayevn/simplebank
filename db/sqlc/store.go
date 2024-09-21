package db

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Store provides all functions to execute db queries and transactions
type Store struct {
	*Queries
	connPool *pgxpool.Pool
}

// NewStore creates a new Store
func NewStore(connPool *pgxpool.Pool) *Store {
	return &Store{
		Queries:  New(connPool),
		connPool: connPool,
	}
}

// ExecTx executes a function within a database transaction
func (store *Store) execTx(fn func(*Queries) error) error {
	tx, err := store.connPool.Begin(context.Background())
	if err != nil {
		return err
	}

	q := New(tx)
	err = fn(q)
	if err != nil {
		if rbErr := tx.Rollback(context.Background()); rbErr != nil {
			return fmt.Errorf("tx error: %v, rb error: %v", err, rbErr)
		}
		return err
	}

	return tx.Commit(context.Background())
}

type TransferTxParams struct {
	FromAccountID int64 `json:"from_account_id"`
	ToAccountID   int64 `json:"to_account_id"`
	Amount        int64 `json:"amount"`
}

type TransferTxResult struct {
	Transfer Transfer `json:"transfer"`
	FromAccount Account `json:"from_account"`
	ToAccount   Account `json:"to_account"`
	FromEntry   Entry `json:"from_entry"`
	ToEntry     Entry `json:"to_entry"`
}

// TransferTx performs a money transfer from one account to the other
// It creates a transfer record and update account balance within a single database transaction
func (store *Store) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error) {
	var transfer TransferTxResult
	err := store.execTx(func(q *Queries) error {
		var err error
		transfer.Transfer, err = q.CreateTransfer(ctx, CreateTransferParams{
			FromAccountID: arg.FromAccountID,
			ToAccountID:   arg.ToAccountID,
			Amount:        arg.Amount,
		})
		if err != nil {
			return err
		}

		transfer.FromEntry, err = q.CreateEntry(ctx, CreateEntryParams{
			AccountID: arg.FromAccountID,
			Amount:    -arg.Amount,
		})
		if err != nil {
			return err
		}

		transfer.ToEntry, err = q.CreateEntry(ctx, CreateEntryParams{
			AccountID: arg.ToAccountID,
			Amount:    arg.Amount,
		})
		if err != nil {
			return err
		}
		
		return nil
	})
	return transfer, err
}