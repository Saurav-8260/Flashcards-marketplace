;; Flashcard Marketplace - Clarity Smart Contract

(define-map flashcard-decks
  ((deck-id uint))
  (
    (owner principal)
    (price uint)
    (title (string-ascii 50))
    (description (string-ascii 200))
    (is-listed bool)
  )
)

(define-map purchases
  ((deck-id uint) (buyer principal))
  bool
)

(define-data-var next-deck-id uint u1)

;; Error constants
(define-constant err-not-owner (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-deck-not-found (err u102))
(define-constant err-deck-not-listed (err u103))
(define-constant err-already-bought (err u104))
(define-constant err-transfer-failed (err u105))

;; -------------------------------
;; Add new deck
(define-public (add-deck (price uint) (title (string-ascii 50)) (description (string-ascii 200)))
  (if (> price u0)
    (let ((deck-id (var-get next-deck-id)))
      (begin
        (map-set flashcard-decks
          ((deck-id deck-id))
          (
            (owner tx-sender)
            (price price)
            (title title)
            (description description)
            (is-listed true)
          )
        )
        (var-set next-deck-id (+ deck-id u1))
        (ok deck-id)
      )
    )
    err-invalid-price
  )
)

;; -------------------------------
;; Buy a deck
(define-public (buy-deck (deck-id uint))
  (match (map-get flashcard-decks ((deck-id deck-id)))
    deck
    (if (is-eq deck.is-listed true)
      (if (is-none (map-get? purchases ((deck-id deck-id) (buyer tx-sender))))
        (begin
          (match (stx-transfer? deck.price tx-sender deck.owner)
            transfer-result
            (if (is-ok transfer-result)
              (begin
                (map-set purchases ((deck-id deck-id) (buyer tx-sender)) true)
                (ok true)
              )
              err-transfer-failed
            )
          )
        )
        err-already-bought
      )
      err-deck-not-listed
    )
    err-deck-not-found
  )
)