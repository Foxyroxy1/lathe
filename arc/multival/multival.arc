; multival.arc
;
; ===== Multival implementation and bare API =========================

(packed:using-rels-as ut "../utils.arc"


(= my.reducers* (table))
  ; A table mapping a symbol to a reducer.
  ;
  ; A reducer accepts a list of contribution details (tables of the
  ; form (obj val ... name ... label ... meta ...), where 'val maps
  ; to the essential contribution value) and returns a value of the
  ; form (obj val ... cares ...), where the val is the observable
  ; value of the multival and the cares is the list of symbols
  ; corresponding to other multivals whose values were needed while
  ; calculating the reduction, but not necessarily including any
  ; multivals which were only needed because some other cared-about
  ; multivalue needed them.
  ;
  ; If a reducer has side effects, no guarantees are made about when
  ; or how often those side effects will happen. This disclaimer
  ; exists mainly so that the reductions can be cached.
  ;
  ; NOTE: The 'cares bit accomplishes cache invalidation cascading,
  ; but it's kind of a hack; it might be possible to accomplish this
  ; some other way and let the reducer definitions be simpler. Then
  ; again, it might be possible to facilitate reducer definitions just
  ; as simple *on top of* this interface, and reducers are supposed to
  ; be abstracted away most of the time anyway, so it's probably
  ; better to do what's easiest here so that anyone who needs to
  ; unwrap the abstractions has it just as easy.

; A table mapping each multival name to a list of contribution
; details (tables with 'name, 'label, 'val, and 'meta fields, where
; 'val is the essential value of the contribution). The list of
; details is eventually passed to the multival's reducer.
(= my.contribs* (table))


(= my.multival-cache* (table))

(=fn my.get-multival (name)
  ; NOTE: Ar parses !a:b:c as (get 'a:b:c).
  (!val (car:or= my.multival-cache*.name
    (list ((car my.reducers*.name) my.contribs*.name)))))

(=fn my.invalidate-multival names
  (while names
    (each name names
      (wipe my.multival-cache*.name))
    (= names (keep [whenlet (reduction) my.multival-cache*._
                     (some [mem _ names] do.reduction!cares)]
                   (keys my.multival-cache*)))))

(=fn my.invalidate-all-multivals ()
  (each key (keys my.multival-cache*)
    (wipe my.multival-cache*.key)))


(=fn my.submit-reducer (name reducer)
  (iflet (existing-reducer) my.reducers*.name
    (unless (iso reducer existing-reducer)
      (err:+ "Multiple reducers have been submitted for the same "
             "multivalue. (This probably means the multivalue has "
             "been defined in multiple parts, where the parts are of "
             "completely different kinds.)"))
    (= my.reducers*.name list.reducer)))

(=fn my.submit-contribution (name label val (o meta))
  (zap [cons (obj name name label label val val meta meta)
             (rem [iso _!label label] _)]
       my.contribs*.name)
  my.invalidate-multival.name)

(=fn my.contribute (name label reducer contribution)
  (my.submit-reducer name reducer)
  (my.submit-contribution name label contribution))

(=fn my.fn-defmultifn-stub (name (o reducer))
  (when reducer
    (my.submit-reducer name reducer))
  (=fn global.name args
    (apply my.get-multival.name args)))

(=mc my.defmultifn-stub (name (o reducer))
  `(,my!fn-defmultifn-stub ',deglobalize.name ,reducer))


)
