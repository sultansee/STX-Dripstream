

# STX-DripStream -  Streaming STX Contract

A Clarity smart contract that enables **streaming STX payments** over time. Inspired by concepts like [Sablier](https://sablier.finance/) on Ethereum, this contract allows users to create, fund, refuel, update, and withdraw from time-based STX payment streams.

---

## 🛠 Features

* Create a **streaming STX payment** with a start and stop block.
* **Withdraw** funds that have accrued to a recipient.
* **Refund** unspent tokens to the sender after the stream ends.
* **Refuel** an active stream to add more funds.
* **Update** payment rate and duration with a valid off-chain signature from the counterparty.
* **Signature verification** via secp256k1 recovery.

---

## 🧱 Data Structures

### `streams` Map

Each stream is stored as a record:

```clojure
(stream-id uint) => {
  sender: principal,
  recipient: principal,
  balance: uint,
  withdrawn-balance: uint,
  payment-per-block: uint,
  timeframe: (tuple (start-block uint) (stop-block uint))
}
```

### `latest-stream-id` Variable

Keeps track of the latest used stream ID.

---

## 🚦 Functions

### 🔹 Public Functions

#### `stream-to`

Create a new stream.

```clojure
(stream-to recipient initial-balance timeframe payment-per-block)
```

* Transfers `initial-balance` STX from the sender to the contract.
* Stores stream metadata and increments the stream ID.

#### `refuel`

Add more funds to an existing stream.

```clojure
(refuel stream-id amount)
```

Only the original sender can call this.

#### `withdraw`

Withdraw accrued STX tokens.

```clojure
(withdraw stream-id)
```

Only the stream **recipient** can call this.

#### `refund`

Refund leftover STX after stream ends.

```clojure
(refund stream-id)
```

Only the **sender** can call this and only after the stop block.

#### `update-details`

Update `payment-per-block` and `timeframe`.

```clojure
(update-details stream-id payment-per-block timeframe signer signature)
```

Requires an off-chain **signature** from the counterparty to authorize the change.

### 🔹 Read-Only Functions

#### `balance-of`

Get the available balance for either sender or recipient.

```clojure
(balance-of stream-id who)
```

#### `calculate-block-delta`

Get how many blocks the stream has been active.

```clojure
(calculate-block-delta timeframe)
```

#### `hash-stream`

Generate a hash of the stream’s new settings for signing.

```clojure
(hash-stream stream-id new-payment-per-block new-timeframe)
```

#### `validate-signature`

Verify an ECDSA signature over a given hash.

```clojure
(validate-signature hash signature signer)
```

---

## 🧪 Error Codes

| Code | Meaning             |
| ---- | ------------------- |
| `u0` | Unauthorized        |
| `u1` | Invalid Signature   |
| `u2` | Stream Still Active |
| `u3` | Invalid Stream ID   |

---

## 🔐 Security Considerations

* Signature verification uses `secp256k1-recover?` for identity validation.
* `as-contract` is used to securely manage fund custody.
* All state mutations are permissioned by checking sender or recipient roles.
* Only one side needs to sign updates — simplifying off-chain negotiation.

---

## 📋 Usage Example

```clojure
;; Alice creates a stream to Bob
(stream-to tx-sender 'SP3FBR... 1000000 (tuple (start-block u100) (stop-block u200)) 1000)

;; Bob checks his balance mid-stream
(balance-of u0 'SP2C2R...)

;; Bob withdraws funds
(withdraw u0)

;; Alice refuels the stream
(refuel u0 500000)

;; After stream ends, Alice refunds remaining balance
(refund u0)
```

---