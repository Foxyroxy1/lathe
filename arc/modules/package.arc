; package.arc
;
; At runtime, some packages are prepared, and some of those packages
; are active. The point of this distinction is so that packages that
; interfere with each other (particularly when overwriting global
; bindings) can be activated over and over in different sequences as
; the program requires.
;
; It's assumed that activating a package twice will have no particular
; benefit. Accordingly, when 'activate is called, that doesn't
; necessarily activate a package. First, currently activated packages
; are checked to see if they already fit the bill, and only if they
; don't does the activation actually take place.


(= prepared-packages* '())
(def prepared (dependency)
  (let compiled compile-dependency-mandatory.dependency
    (find [package-satisfies _ compiled] prepared-packages*)))

(= activated-packages* '())
(def activated (dependency)
  (let compiled compile-dependency-mandatory.dependency
    (find [package-satisfies _ compiled] activated-packages*)))

; This returns the package object.
(def prepare (dependency)
  (let compiled compile-dependency-mandatory.dependency
    (or prepared.compiled
        (iflet package (do.compiled!prepare)
          (do (push package prepared-packages*)
              package)
          ; The error message gives the *uncompiled* dependency.
          (err:+ "Couldn't prepare " dependency ".")))))

; This returns a procedure which will undo the activation.
(def activate (dependency)
  (let compiled compile-dependency-mandatory.dependency
    (unless activated.compiled
      (once-at-a-time `(activate ,dependency)  ; NOT compiled
        (let package prepare.compiled
          (do1 (do.package!activate)
               (zap [cons package (rem [deactivates package _] _)]
                    activated-packages*)))))))

(mac using-as withbody
  (withs ((binds . body) (parse-magic-withlike withbody
                           (+ "An odd-sized list of bindings was "
                              "given to using-as."))
          result `(tldo ,@body))
    (each (name dependency) rev.binds
      (= result `(w/global ,name (prepare-nspace ,dependency)
                   ,result)))
    result))

(mac use-as bindings
  (when (odd:len bindings)
    (err "An odd-sized list of bindings was given to use-as."))
  `(= ,@(mappend [do `(,_.0 (prepare-nspace ,_.1))] pair.bindings)))


; Each of these rules should behave like this, as far as types go:
;
; (fn (dependency)
;   (when (this-rule-applies)
;     (obj type 'compiled-dependency
;          prepare (thunk:when (can-get-resources)
;                    (obj nspace (thunk:return-an-nspace-macro)
;                         activate
;                           (fn ()
;                             (have-side-effects)
;                             (thunk:undo-those-side-effects))))
;          accepts (fn (package)
;                    (bool-implementation))))
;
; Note that 'accepts should return t for any package which 'prepare
; ould return, and preferably for only those packages, unless there's
; a good reason for this dependency to be satisfied by a package
; prepared from some other dependency.
;
(= compile-dependency-rules* '(()))
(def compile-dependency (dependency)
  (if (and (isa dependency 'table)
           (is do.dependency!type 'compiled-dependency))
    dependency
    (some [_ dependency] car.compile-dependency-rules*)))

(def compile-dependency-mandatory (dependency)
  (or compile-dependency.dependency
      (err:+ "Not a valid dependency: " dependency)))

(def package-satisfies (package dependency)
  (let compiled compile-dependency-mandatory.dependency
    do.compiled!accepts.package))

; Each of these rules should behave like this, as far as types go:
;
; (fn (package-one package-two)
;   (when (this-rule-applies)
;     (list (bool-implementation))))
;
; By default, every package deactivates every other one. Furthermore,
; no package can deactivate one iso to it, even if a rule would
; suggest otherwise.
;
(= deactivates-rules* '(()))
(def deactivates (package-one package-two)
  (aif (iso package-one package-two)
    nil
       (some [_ package-one package-two] car.deactivates-rules*)
    car.it
    t))


(def prepare-nspace (dependency)
  (prepare.dependency!nspace))

(def pack-nmap (nmap)
  (let export (obj nmap nmap)
    (= !nspace.export (let ns (nspace-indirect:fn () do.export!nmap)
                        thunk.ns))
    (=fn !activate.export ()
      (let overwritten-sobj (import-nmap do.export!nmap)
        (fn ()
          (zap [rem [is export _] _] activated-packages*)
          import-sobj.overwritten-sobj)))
    export))

(mac packed body
  `(let nmap (table)
     (w/global my nspace.nmap
       (tldo ,@body))
     pack-nmap.nmap))
