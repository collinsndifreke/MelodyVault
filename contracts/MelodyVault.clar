;; MelodyVault: Musical Composition and Score Exchange Platform
;; Version: 1.0.0
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-COMPOSITION-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-PUBLISHED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-TEMPO (err u5))
(define-constant ERR-INVALID-GENRE (err u6))
(define-constant ERR-INVALID-DIFFICULTY (err u7))
(define-constant ERR-INVALID-COMPOSITION-TITLE (err u8))
(define-constant ERR-INVALID-NOTATION (err u9))
(define-constant MIN-TEMPO u60)
(define-data-var next-composition-id uint u1)
(define-map composition-library
    uint
    {
        composer: principal,
        composition-title: (string-utf8 50),
        notation: (string-utf8 200),
        genre: (string-utf8 15),
        difficulty: (string-utf8 10),
        publication-status: (string-utf8 15),
        tempo-bpm: uint
    }
)
(define-private (validate-genre (genre (string-utf8 15)))
    (or 
        (is-eq genre u"Classical")
        (is-eq genre u"Jazz")
        (is-eq genre u"Folk")
        (is-eq genre u"Contemporary")
        (is-eq genre u"Electronic")
        (is-eq genre u"World")
    )
)
(define-private (validate-difficulty (difficulty (string-utf8 10)))
    (or 
        (is-eq difficulty u"Elementary")
        (is-eq difficulty u"Easy")
        (is-eq difficulty u"Moderate")
        (is-eq difficulty u"Difficult")
        (is-eq difficulty u"Virtuoso")
    )
)
(define-private (validate-text-structure (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)
(define-public (publish-composition 
    (composition-title (string-utf8 50))
    (notation (string-utf8 200))
    (genre (string-utf8 15))
    (difficulty (string-utf8 10))
    (tempo-bpm uint)
)
    (let
        (
            (composition-id (var-get next-composition-id))
        )
        (asserts! (validate-text-structure composition-title u3 u50) ERR-INVALID-COMPOSITION-TITLE)
        (asserts! (validate-text-structure notation u10 u200) ERR-INVALID-NOTATION)
        (asserts! (>= tempo-bpm MIN-TEMPO) ERR-INVALID-TEMPO)
        (asserts! (validate-genre genre) ERR-INVALID-GENRE)
        (asserts! (validate-difficulty difficulty) ERR-INVALID-DIFFICULTY)
        
        (map-set composition-library composition-id {
            composer: tx-sender,
            composition-title: composition-title,
            notation: notation,
            genre: genre,
            difficulty: difficulty,
            publication-status: u"available",
            tempo-bpm: tempo-bpm
        })
        (var-set next-composition-id (+ composition-id u1))
        (ok composition-id)
    )
)
(define-public (withdraw-composition (composition-id uint))
    (let
        (
            (composition (unwrap! (map-get? composition-library composition-id) ERR-COMPOSITION-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get composer composition)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get publication-status composition) u"available") ERR-INVALID-STATUS)
        (ok (map-set composition-library composition-id (merge composition { publication-status: u"withdrawn" })))
    )
)
(define-read-only (get-composition (composition-id uint))
    (ok (map-get? composition-library composition-id))
)
(define-read-only (get-composer (composition-id uint))
    (ok (get composer (unwrap! (map-get? composition-library composition-id) ERR-COMPOSITION-NOT-FOUND)))
)