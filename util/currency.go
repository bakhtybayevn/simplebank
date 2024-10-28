package util

const (
	USD = "USD"
	EUR = "EUR"
	KZT = "KZT"
)

func IsSupportedCurrency(currency string) bool {
	switch currency {
	case USD, EUR, KZT:
		return true
	}
	return false
}