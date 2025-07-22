
;; STX-Dripstream
;; error codes
(define-constant ERR_UNAUTHORIZED (err u0))
(define-constant ERR_INVALID_SIGNATURE (err u1))
(define-constant ERR_STREAM_STILL_ACTIVE (err u2))
(define-constant ERR_INVALID_STREAM_ID (err u3))

;; data vars
(define-data-var latest-stream-id uint u0)

;; streams mapping
(define-map streams 
    uint ;; stream-id
    {
        sender: principal,
        recipient: principal,
        balance: uint,
        withdrawn-balance: uint,
        payment-per-block: uint,
        timeframe: (tuple (start-block uint) (stop-block uint))
    }
)

;; Create a new stream
(define-public (stream-to
    (recipient principal)
    (initial-balance uint)
    (timeframe (tuple (start-block uint) (stop-block uint)))
    (payment-per-block uint)
   )
    (let (
       (stream {
            sender: contract-caller,
            recipient: recipient,
            balance: initial-balance,
            withdrawn-balance: u0,
            payment-per-block: payment-per-block,
            timeframe: timeframe
        })
        (current-stream-id (var-get latest-stream-id))
    )
        ;; stx-transfer takes in (amount, sender, recipient) arguments
        ;; for the `recipient` - we do `(as-contract tx-sender)`
        ;; `as-contract` switches the `tx-sender` variable to be the contract principal
        ;; inside it's scope
        ;; so doing `as-contract tx-sender` gives us the contract address itself
        ;; this is like doing address(this) in Solidity

        (try! (stx-transfer? initial-balance contract-caller (as-contract tx-sender)))
        (map-set streams current-stream-id stream)
        (var-set latest-stream-id (+ current-stream-id u1))
        (ok current-stream-id)
    )
)

;; Increase the locked STX balance for a stream 
(define-public (refuel (stream-id uint) (amount uint))
    (let (
        (stream (unwrap! (map-get? streams stream-id) ERR_INVALID_STREAM_ID))
    )
    (asserts! (is-eq contract-caller (get sender stream)) ERR_UNAUTHORIZED)
    (try! (stx-transfer? amount contract-caller (as-contract tx-sender)))
    (map-set streams stream-id
        (merge stream {balance: (+ (get balance stream) amount)})
    )
    (ok amount)
    )
)

;; Calculate the number of blocks a stream has been active
(define-read-only (calculate-block-delta (timeframe (tuple (start-block uint) (stop-block uint))))
    (let (
        (start-block (get start-block timeframe))
        (stop-block (get stop-block timeframe))

        (delta
            (if (<= stacks-block-height start-block)
                ;; then
                u0 
                ;; else
                (if (< stacks-block-height stop-block)
                    ;; then
                    (- stacks-block-height start-block)
                    ;; else
                    (- stop-block start-block)
                )
            )
        )
    )
    delta
    )
)
