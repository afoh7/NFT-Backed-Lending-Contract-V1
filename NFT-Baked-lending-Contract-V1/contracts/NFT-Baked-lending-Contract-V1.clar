;; NFT-Backed Lending Contract V1
;; Implements decentralized peer-to-peer NFT lending with collateral and loan management

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-EXPIRED (err u1))
(define-constant ERR-INVALID-AMOUNT (err u2))
(define-constant ERR-UNAUTHORIZED (err u3))
(define-constant ERR-NFT-NOT-FOUND (err u4))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u5))
(define-constant ERR-ALREADY-REPAID (err u6))
(define-constant ERR-INVALID-PRICE (err u7))
(define-constant ERR-LOAN-NOT-ACTIVE (err u8))

;; Loan Types
(define-constant FIXED u1)
(define-constant FLEXIBLE u2)

;; Data Maps
(define-map NFTBalances
    { holder: principal }
    { nft-id: uint }
)

(define-map Loans
    { loan-id: uint }
    {
        lender: principal,
        borrower: (optional principal),
        loan-type: uint,
        loan-amount: uint,
        collateral-nft: uint,
        interest-rate: uint,
        expiry: uint,
        is-active: bool,
        is-repaid: bool,
        creation-height: uint
    }
)

(define-map UserLoans
    { user: principal }
    { lent: (list 20 uint), borrowed: (list 20 uint) }
)

;; Data Variables
(define-data-var next-loan-id uint u0)
(define-data-var nft-price uint u0)

;; Authorization
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT-OWNER)
)

;; NFT Balance Management
(define-public (deposit-nft (nft-id uint))
    (let
        ((sender tx-sender)
         (current-nft (default-to { nft-id: u0 } (map-get? NFTBalances { holder: sender })) ))
        (asserts! (> nft-id u0) ERR-INVALID-AMOUNT)
        (map-set NFTBalances
            { holder: sender }
            { nft-id: nft-id })
        (ok true)
    )
)

(define-public (withdraw-nft (nft-id uint))
    (let
        ((sender tx-sender)
         (current-nft (default-to { nft-id: u0 } (map-get? NFTBalances { holder: sender })) ))
        (asserts! (is-eq nft-id (get nft-id current-nft)) ERR-NFT-NOT-FOUND)
        (map-set NFTBalances
            { holder: sender }
            { nft-id: u0 })
        (ok true)
    )
)

;; Loan Management
(define-public (create-loan 
    (loan-type uint)
    (loan-amount uint)
    (collateral-nft uint)
    (interest-rate uint)
    (expiry uint))
    (let
        ((loan-id (+ (var-get next-loan-id) u1))
         (sender tx-sender)
         (current-nft (default-to { nft-id: u0 } (map-get? NFTBalances { holder: sender })) ))
         
        ;; Validate inputs
        (asserts! (or (is-eq loan-type FIXED) (is-eq loan-type FLEXIBLE)) ERR-INVALID-AMOUNT)
        (asserts! (> loan-amount u0) ERR-INVALID-PRICE)
        (asserts! (> interest-rate u0) ERR-INVALID-PRICE)
        (asserts! (> expiry stacks-block-height) ERR-EXPIRED)
        (asserts! (> collateral-nft u0) ERR-INVALID-AMOUNT)

        ;; Ensure the lender has the NFT they want to use as collateral
        (asserts! (is-eq (get nft-id current-nft) collateral-nft) ERR-INSUFFICIENT-COLLATERAL)

        ;; Create loan
        (map-set Loans
            { loan-id: loan-id }
            {
                lender: sender,
                borrower: none,
                loan-type: loan-type,
                loan-amount: loan-amount,
                collateral-nft: collateral-nft,
                interest-rate: interest-rate,
                expiry: expiry,
                is-active: true,
                is-repaid: false,
                creation-height: stacks-block-height
            })

        ;; Lock NFT as collateral and update state
        (try! (transfer-nft sender (as-contract tx-sender) collateral-nft))
        (var-set next-loan-id loan-id)
        (try! (update-user-loans sender loan-id true))
        (ok loan-id)
    )
)

(define-public (borrow-loan (loan-id uint))
    (let
        ((loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-NFT-NOT-FOUND))
         (borrower tx-sender))

        ;; Validate loan ID exists
        (asserts! (<= loan-id (var-get next-loan-id)) ERR-NFT-NOT-FOUND)
        
        ;; Validate loan state
        (asserts! (not (get is-repaid loan)) ERR-ALREADY-REPAID)
        (asserts! (not (some borrower)) ERR-UNAUTHORIZED)
        (asserts! (< stacks-block-height (get expiry loan)) ERR-EXPIRED)

        ;; Borrower receives loan amount and updates state
        (try! (stx-transfer? (get loan-amount loan) borrower (get lender loan)))
        
        ;; Update loan state
        (map-set Loans
            { loan-id: loan-id }
            (merge loan { borrower: some borrower, is-active: true }))
        (ok true)
    )
)

(define-public (repay-loan (loan-id uint))
    (let
        ((loan (unwrap! (map-get? Loans { loan-id: loan-id }) ERR-NFT-NOT-FOUND))
         (borrower tx-sender))

        ;; Validate loan state
        (asserts! (is-eq (some borrower) (get borrower loan)) ERR-UNAUTHORIZED)
        (asserts! (not (get is-repaid loan)) ERR-ALREADY-REPAID)

        ;; Transfer loan amount + interest to lender
        (let ((total-repayment (+ (get loan-amount loan) (* (get loan-amount loan) (get interest-rate loan)))))
            (try! (stx-transfer? total-repayment borrower (get lender loan))))
        
        ;; Return collateral NFT to borrower
        (try! (transfer-nft (as-contract tx-sender) borrower (get collateral-nft loan)))
        
        ;; Update loan state to 'repaid'
        (map-set Loans
            { loan-id: loan-id }
            (merge loan { is-repaid: true, is-active: false }))
        (ok true)
    )
)

;; Private helper functions
(define-private (transfer-nft (from principal) (to principal) (nft-id uint))
    (let
        ((from-nft (default-to { nft-id: u0 } (map-get? NFTBalances { holder: from })))
         (to-nft (default-to { nft-id: u0 } (map-get? NFTBalances { holder: to }))))
        (asserts! (is-eq nft-id (get nft-id from-nft)) ERR-NFT-NOT-FOUND)
        (map-set NFTBalances
            { holder: from }
            { nft-id: u0 })
        (map-set NFTBalances
            { holder: to }
            { nft-id: nft-id })
        (ok true)
    )
)

(define-private (update-user-loans (user principal) (loan-id uint) (is-lender bool))
    (let
        ((user-loans (default-to 
            { lent: (list ), borrowed: (list ) }
            (map-get? UserLoans { user: user })) ))
        (if is-lender
            (ok (map-set UserLoans
                { user: user }
                { lent: (unwrap! (as-max-len? (append (get lent user-loans) loan-id) u20) ERR-UNAUTHORIZED),
                  borrowed: (get borrowed user-loans) }))
            (ok (map-set UserLoans
                { user: user }
                { lent: (get lent user-loans),
                  borrowed: (unwrap! (as-max-len? (append (get borrowed user-loans) loan-id) u20) ERR-UNAUTHORIZED) })))
    )
)

;; Read-only functions
(define-read-only (get-loan (loan-id uint))
    (map-get? Loans { loan-id: loan-id })
)

(define-read-only (get-nft-balance (holder principal))
    (default-to { nft-id: u0 }
        (map-get? NFTBalances { holder: holder }))
)

(define-read-only (get-user-loans (user principal))
    (default-to
        { lent: (list ), borrowed: (list ) }
        (map-get? UserLoans { user: user }))
)

;; Oracle functions
(define-public (set-nft-price (price uint))
    (begin
        (asserts! (is-contract-owner) ERR-UNAUTHORIZED)
        (asserts! (> price u0) ERR-INVALID-PRICE) 
        (var-set nft-price price)
        (ok true))
)

(define-read-only (get-nft-price)
    (var-get nft-price)
)
