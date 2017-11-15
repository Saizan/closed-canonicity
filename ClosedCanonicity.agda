{-# OPTIONS --postfix-projections #-}

-- Type theory with booleans

open import Level using (Level; _⊔_; Lift) renaming (zero to lzero; suc to lsuc)

open import Data.Bool.Base
open import Data.Fin using (Fin; zero; suc)
open import Data.Nat.Base
open import Data.Product using (∃; _×_; _,_; proj₁; proj₂)
open import Data.Unit using (⊤)

open import Function using (id; _on_)
open import Function.Bijection using (Bijective; Bijection); open Bijection using (to; bijective; surjection); open Bijective using (injective; surjective)
open import Function.Surjection using (Surjective; Surjection); open Surjection using (from; from-to);  open Surjective using (right-inverse-of)
open import Function.Equality using (_⟶_; _⟨$⟩_)

open import Relation.Binary using (Setoid)
import Relation.Binary.On as On
import Relation.Binary.PropositionalEquality as PE

Prop = Set

-- Raw syntax (well-scoped)

data Exp (n : ℕ) : Set where
  -- types
  bool   : Exp n
  fun    : (a b : Exp n) → Exp n
  univ   : (l : ℕ) → Exp n
  -- lambda-calculus
  var    : (x : Fin n) → Exp n
  abs    : (t : Exp (1 + n)) → Exp n
  app    : (t u : Exp n) → Exp n
  -- booleans
  bit    : (b : Bool) → Exp n
  ifthen : (C c t e : Exp n) → Exp n

-- Renaming

Ren : (n m : ℕ) → Set
Ren n m = Fin m → Fin n

liftr : ∀{n m} (ρ : Ren n m) → Ren (1 + n) (1 + m)
liftr ρ zero    = zero
liftr ρ (suc x) = suc (ρ x)

-- Order of arguments should be such that
-- ren (ρ ∘ ρ') t = ren ρ (ren ρ' t)
ren : ∀{n m} (ρ : Ren n m) (t : Exp m) → Exp n
ren ρ t = {!!}

-- Weakening

↑ : ∀{n} → Exp n → Exp (1 + n)
↑ e = ren suc e

-- Substitution

Sub : (n m : ℕ) → Set
Sub n m = Fin m → Exp n

head : ∀{n m} → Sub n (1 + m) → Exp n
head σ = σ zero

tail : ∀{n m} → Sub n (1 + m) → Sub n m
tail σ x = σ (suc x)

lifts : ∀{n m} (σ : Sub n m) → Sub (1 + n) (1 + m)
lifts σ zero = var zero
lifts σ (suc x) = ↑ (σ x)

ext : ∀{n m} (σ : Sub n m) (u : Exp n) → Sub n (1 + m)
ext σ u zero = u
ext σ u (suc x) = σ x

sg : ∀{n} (u : Exp n) → Sub n (1 + n)
sg = ext var

sub : ∀{n m} (ρ : Sub n m) (t : Exp m) → Exp n
sub ρ t = {!!}

sub1 : ∀{m} (u : Exp m) (t : Exp (1 + m)) → Exp m
sub1 u = sub (sg u)


-- Non-dependent function space

arr : ∀{n} (a b : Exp n) → Exp n
arr a b = fun a (abs (↑ b))

-- Contexts of given length

data Cxt : ℕ → Set where
  ε : Cxt zero
  _,_ : ∀{n} (Γ : Cxt n) (a : Exp n) → Cxt (1 + n)

-- Well-typed variables

data Var : ∀{n} (Γ : Cxt n) (x : Fin n) (a : Exp n) → Set where

  vz : ∀{n}{Γ : Cxt n} {a : Exp n}
    → Var (Γ , a) zero (↑ a)

  vs : ∀{n}{Γ : Cxt n} {a b : Exp n} {x : Fin n}
    → (dx : Var Γ x b)
    → Var (Γ , a) (suc x) (↑ b)

-- Typing and conversion

mutual

  data _⊢_∷_ : ∀{n} (Γ : Cxt n) (t a : Exp n) → Prop where

    var : ∀{n Γ} {a : Exp n} {x} (dx : Var Γ x a) → Γ ⊢ var x ∷ a

    app : ∀{n Γ} {a b t u : Exp n}
      → (dt : Γ ⊢ t ∷ fun a b)
      → (du : Γ ⊢ u ∷ a)
      → Γ ⊢ app t u ∷ app b u

    univ : ∀{n} {Γ : Cxt n} {l} → Γ ⊢ univ l ∷ univ (1 + l)

    bit : ∀{n} {Γ : Cxt n} (b : Bool) → Γ ⊢ bit b ∷ bool

    ifthen : ∀{n}{Γ : Cxt n} {l} {C c t e : Exp n}
      → (dC : Γ ⊢ C ∷ arr bool (univ l))
      → (dc : Γ ⊢ c ∷ bool)
      → (dt : Γ ⊢ t ∷ app C (bit true))
      → (de : Γ ⊢ e ∷ app C (bit false))
      → Γ ⊢ ifthen C c t e ∷ app C c

  data _⊢_≡_∷_ : ∀{n} (Γ : Cxt n) (t t' a : Exp n) → Prop where

    var :  ∀{n Γ} {a : Exp n} {x} (dx : Var Γ x a) → Γ ⊢ var x ≡ var x ∷ a

    app : ∀{n Γ} {a b t t' u u' : Exp n}
      → (dt : Γ ⊢ t ≡ t' ∷ fun a b)
      → (du : Γ ⊢ u ≡ u' ∷ a)
      → Γ ⊢ app t u ≡ app t' u' ∷ app b u

    univ : ∀{n} {Γ : Cxt n} {l} → Γ ⊢ univ l ≡ univ l ∷ univ (1 + l)

    bit : ∀{n} {Γ : Cxt n} (b : Bool) → Γ ⊢ bit b ≡ bit b ∷ bool

    ifthen : ∀{n}{Γ : Cxt n} {l} {C C' c c' t t' e e' : Exp n}
      → (dC : Γ ⊢ C ≡ C' ∷ arr bool (univ l))
      → (dc : Γ ⊢ c ≡ c' ∷ bool)
      → (dt : Γ ⊢ t ≡ t' ∷ app C (bit true))
      → (de : Γ ⊢ e ≡ e' ∷ app C (bit false))
      → Γ ⊢ ifthen C c t e ≡ ifthen C c t e ∷ app C c

    iftrue : ∀{n}{Γ : Cxt n} {l} {C t e : Exp n}
      → (dC : Γ ⊢ C ∷ arr bool (univ l))
      → (dt : Γ ⊢ t ∷ app C (bit true))
      → (de : Γ ⊢ e ∷ app C (bit false))
      → Γ ⊢ ifthen C (bit true) t e ≡ t ∷ app C (bit true)

    iffalse : ∀{n}{Γ : Cxt n} {l} {C t e : Exp n}
      → (dC : Γ ⊢ C ∷ arr bool (univ l))
      → (dt : Γ ⊢ t ∷ app C (bit true))
      → (de : Γ ⊢ e ∷ app C (bit false))
      → Γ ⊢ ifthen C (bit false) t e ≡ e ∷ app C (bit false)

    sym : ∀{n Γ} {a t u : Exp n}
      → (e  : Γ ⊢ t ≡ u ∷ a)
      → Γ ⊢ u ≡ t ∷ a

    trans : ∀{n Γ} {a t u v : Exp n}
      → (e  : Γ ⊢ t ≡ u ∷ a)
      → (e' : Γ ⊢ u ≡ v ∷ a)
      → Γ ⊢ t ≡ v ∷ a

refl : ∀{n} {Γ : Cxt n} {t a} (dt : Γ ⊢ t ∷ a) → Γ ⊢ t ≡ t ∷ a
refl = {!!}

-- Well-formed substitutions

_⊢ₛ_∷_ : ∀{n m} (Γ : Cxt n) (σ : Sub n m) (Δ : Cxt m) → Set
Γ ⊢ₛ σ ∷ ε = ⊤
Γ ⊢ₛ σ ∷ (Δ , a) = (Γ ⊢ₛ tail σ ∷ Δ) × (Γ ⊢ head σ ∷ sub (tail σ) a)

-- Equal substitutions

_⊢ₛ_≡_∷_ : ∀{n m} (Γ : Cxt n) (σ σ' : Sub n m) (Δ : Cxt m) → Set
Γ ⊢ₛ σ ≡ σ' ∷ ε = ⊤
Γ ⊢ₛ σ ≡ σ' ∷ (Δ , a) = (Γ ⊢ₛ tail σ ≡ tail σ' ∷ Δ) × (Γ ⊢ head σ ≡ head σ' ∷ sub (tail σ) a)

-- Closed terms of type a

Term : (a : Exp 0) → Setoid lzero lzero
Term a .Setoid.Carrier = ∃ λ t → ε ⊢ t ∷ a
Term a .Setoid._≈_ (t , dt) (t' , dt') = ε ⊢ t ≡ t' ∷ a
Term a .Setoid.isEquivalence .Relation.Binary.IsEquivalence.refl  {t , dt} = refl dt
Term a .Setoid.isEquivalence .Relation.Binary.IsEquivalence.sym   = sym
Term a .Setoid.isEquivalence .Relation.Binary.IsEquivalence.trans = trans

-- Embedding ℕ into Agda's levels

level : (n : ℕ) → Level
level zero    = lzero
level (suc n) = lsuc (level n)

-- Interpretation of the universes

record Type l (a : Exp 0) : Set (level (1 + l)) where
  field
    intp : ∀ {t} (dt : ε ⊢ t ∷ a) → Setoid (level l) (level l)  -- Formal dependency on derivation dt
    bij  : ∀ {t t'}
      (dt : ε ⊢ t ∷ a)
      (dt' : ε ⊢ t' ∷ a)
      (ett' : ε ⊢ t ≡ t' ∷ a) →
      Bijection (intp dt) (intp dt')  -- This includes irrelevance of dt
   --  BUT NOT IRRELEVANCE OF ett' !!
open Type

-- Candidates

Cand : ∀{l a} (A : Type l a) {t} (d : ε ⊢ t ∷ a) → Set (level l)
Cand A d = A .intp d .Setoid.Carrier

CandEq : ∀{l a} (A : Type l a) {t} (d : ε ⊢ t ∷ a) (i j : Cand A d) → Set (level l)
CandEq A d i j = A .intp d .Setoid._≈_ i j

Candrefl : ∀{l a} (A : Type l a) {t} (d : ε ⊢ t ∷ a) (i : Cand A d) → CandEq A d i i
Candrefl A d i = A .intp d .Setoid.refl {i}

Candsym : ∀{l a} (A : Type l a) {t} (d : ε ⊢ t ∷ a) {i j : Cand A d} (eq : CandEq A d i j) → CandEq A d j i
Candsym A d eq = A .intp d .Setoid.sym eq

Candtrans : ∀{l a} (A : Type l a) {t} (d : ε ⊢ t ∷ a) {i j k : Cand A d} (eq : CandEq A d i j) (eq' : CandEq A d j k) → CandEq A d i k
Candtrans A d eq eq' = A .intp d .Setoid.trans eq eq'

cast : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a)
  → (ett' : ε ⊢ t ≡ t' ∷ a)
  → (it : Cand A dt)
  → Cand A dt'
cast A dt dt' ett' it = A .bij dt dt' ett' .to ⟨$⟩ it

CandHEq : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) (i : Cand A dt) (i' : Cand A dt') → Set (level l)
CandHEq A dt dt' ett' i i' = CandEq A dt' (cast A dt dt' ett' i) i'

castEq : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) {i j : Cand A dt}
  → (eq : CandEq A dt i j)
  → CandEq A dt' (cast A dt dt' ett' i) (cast A dt dt' ett' j)
castEq A dt dt' ett' {i} {j} eq = A .bij dt dt' ett' .to .Function.Equality.cong eq

cast-inj : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) {i j : Cand A dt}
  → (eq : CandEq A dt' (cast A dt dt' ett' i) (cast A dt dt' ett' j))
  → CandEq A dt i j
cast-inj A dt dt' ett' {i} {j} eq = A .bij dt dt' ett' .Bijection.injective eq

cast' : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a)
  → (ett' : ε ⊢ t ≡ t' ∷ a)
  → (i : Cand A dt')
  → Cand A dt
cast' A dt dt' ett' i = from (surjection (A .bij dt dt' ett')) ⟨$⟩ i

cast'Eq : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) {i j : Cand A dt'}
  → (eq : CandEq A dt' i j)
  → CandEq A dt (cast' A dt dt' ett' i) (cast' A dt dt' ett' j)
cast'Eq A dt dt' ett' {i} {j} eq = from (surjection (A .bij dt dt' ett')) .Function.Equality.cong eq

cast-cast' : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) (i : Cand A dt')
  → CandEq A dt' (cast A dt dt' ett' (cast' A dt dt' ett' i)) i
cast-cast' A dt dt' ett' i = (A .bij dt dt' ett') .bijective .surjective .right-inverse-of i


-- castCancel : ∀{l a} (A : Type l a) {t t'} (dt : ε ⊢ t ∷ a) (dt' : ε ⊢ t' ∷ a) (ett' : ε ⊢ t ≡ t' ∷ a) (et't : ε ⊢ t' ≡ t ∷ a) (i : Cand A dt')
--   → CandEq A dt' (cast A dt dt' ett' (cast A dt' dt et't i)) i
-- castCancel A dt dt' ett' et't i = {! (A .bij dt dt' ett') .bijective .surjective .right-inverse-of i!}  -- NOT TRUE, need to prove that cast only depends on t and t'
--  -- from-to (surjection (A .bij dt dt' ett')) {!!}

-- CandS : ∀{l a} (T : Type l a) → Setoid (level (1 + l)) (level (1 + l))
-- CandS {l} {a} T = Function.Equality.setoid (Term a)
--   record { Carrier       =  λ tdt → T .intp (proj₂ tdt) .Setoid.Carrier
--          ; _≈_           =  λ {tdt} {tdt'} e e' → {! T .intp (proj₂ tdt) .Setoid._≈_ !}
--          ; isEquivalence =  {! λ tdt → T .intp (proj₂ tdt) .Setoid.isEquivalence !}
--          }


-- Interpretation of the function space

record Fam {l a} (A : Type l a) (b : Exp 0) : Set (level (1 + l)) where
  field
    intp : ∀ {u} {du : ε ⊢ u ∷ a} (iu : Cand A du) → Type l (app b u)
    bij  : ∀ {u u'}
      {du : ε ⊢ u ∷ a}
      {du' : ε ⊢ u' ∷ a}
      (iu : Cand A du)
      (euu' : ε ⊢ u ≡ u' ∷ a)
      (let iu' = A .bij du du' euu' .to  ⟨$⟩ iu)
      {t} (dt : ε ⊢ t ∷ app b u) (dt' : ε ⊢ t ∷ app b u') →
      Bijection (intp iu .Type.intp dt) (intp iu' .Type.intp dt')
      -- We do not need to generalize this to ε ⊢ t ≡ t' ∷ a
      -- since we already have this in Type
open Fam

⟦fun⟧ : ∀{a b l} (A : Type l a) (B : Fam A b) → Type l (fun a b)
⟦fun⟧ {a} A B .intp {t} dt .Setoid.Carrier  = ∀ {u} {du : ε ⊢ u ∷ a} (iu : Cand A du) → Cand   (B .intp iu) (app dt du)
⟦fun⟧ {a} A B .intp {t} dt .Setoid._≈_ f f' = ∀ {u} {du : ε ⊢ u ∷ a} (iu : Cand A du) → CandEq (B .intp iu) (app dt du) (f iu) (f' iu)
⟦fun⟧ {a} A B .intp {t} dt .Setoid.isEquivalence .Relation.Binary.IsEquivalence.refl          {f} {u} {du} iu = Candrefl   (B .intp iu) (app dt du) (f  iu)
⟦fun⟧ {a} A B .intp {t} dt .Setoid.isEquivalence .Relation.Binary.IsEquivalence.sym           eq  {u} {du} iu = Candsym    (B .intp iu) (app dt du) (eq iu)
⟦fun⟧ {a} A B .intp {t} dt .Setoid.isEquivalence .Relation.Binary.IsEquivalence.trans      eq eq' {u} {du} iu = Candtrans  (B .intp iu) (app dt du) (eq iu) (eq' iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .to ._⟨$⟩_                                                       f  {u} {du} iu = cast       (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (f  iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .to .Function.Equality.cong                                     eq {u} {du} iu = castEq     (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (eq iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .bijective .injective                                           eq {u} {du} iu = cast-inj   (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (eq iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .bijective .surjective .Surjective.from ._⟨$⟩_                   f  {u} {du} iu = cast'      (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (f  iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .bijective .surjective .Surjective.from .Function.Equality.cong eq {u} {du} iu = cast'Eq    (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (eq iu)
⟦fun⟧ {a} A B .bij dt dt' ett' .bijective .surjective .Surjective.right-inverse-of             f  {u} {du} iu = cast-cast' (B .intp iu) (app dt du) (app dt' du) (app ett' (refl du)) (f  iu)

-- Interpretation of application is just application of the meta-theory

⟦app⟧ : ∀{a b l} {A : Type l a} {B : Fam A b} {t u}
  (dt : ε ⊢ t ∷ fun a b) (it : Cand (⟦fun⟧ A B) dt) →
  (du : ε ⊢ u ∷ a      ) (iu : Cand A du) →
  Cand (B .intp iu) (app dt du)
⟦app⟧ dt it du iu = it iu

-- Interpretation of type bool

⟦bool⟧ : Type 0 bool
⟦bool⟧ .intp {t} dt .Setoid.Carrier       = ∃ λ b → ε ⊢ t ≡ bit b ∷ bool
⟦bool⟧ .intp {t} dt .Setoid._≈_           = PE._≡_ on proj₁
⟦bool⟧ .intp {t} dt .Setoid.isEquivalence = On.isEquivalence proj₁ PE.isEquivalence

⟦bool⟧ .bij dt dt' ett' .to ._⟨$⟩_ (b , eb)          = b , trans (sym ett') eb
⟦bool⟧ .bij dt dt' ett' .to .Function.Equality.cong = id
⟦bool⟧ .bij dt dt' ett' .bijective .injective       = id
⟦bool⟧ .bij dt dt' ett' .bijective .surjective .Surjective.from ._⟨$⟩_ (b , eb)          = b , trans ett' eb
⟦bool⟧ .bij dt dt' ett' .bijective .surjective .Surjective.from .Function.Equality.cong = id
⟦bool⟧ .bij dt dt' ett' .bijective .surjective .Surjective.right-inverse-of (b , eb)    = PE.refl

-- Interpretation of bits

⟦bit⟧ : ∀ b → Cand ⟦bool⟧ (bit b)
⟦bit⟧ b = b , bit b

-- Semantics of contexts

-- We have to restrict the level of the context, since we do not have Setω

data _⊢_ (l : ℕ) : ∀ {n} (Γ : Cxt n) → Prop where

  ε    : l ⊢ ε

  cext : ∀{n}{Γ : Cxt n} {a : Exp n}
   (dΓ : l ⊢ Γ)
   (da : Γ ⊢ a ∷ univ l)
   → l ⊢ (Γ , a)

-- Interpretation of contexts

record Con l {n} (Γ : Cxt n) : Set (level (1 + l)) where
  field
    intp : ∀ {σ} (ds : ε ⊢ₛ σ ∷ Γ) → Setoid (level l) (level l)  -- Formal dependency on derivation dt
    bij  : ∀ {σ σ'}
      (ds : ε ⊢ₛ σ ∷ Γ)
      (ds' : ε ⊢ₛ σ' ∷ Γ)
      (ess' : ε ⊢ₛ σ ≡ σ' ∷ Γ) →
      Bijection (intp ds) (intp ds')
open Con

-- Context candidates

Cond : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {σ} (d : ε ⊢ₛ σ ∷ Γ) → Set (level l)
Cond G d = G .intp d .Setoid.Carrier

CondEq : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {σ} (d : ε ⊢ₛ σ ∷ Γ) (i j : Cond G d) → Set (level l)
CondEq G d i j = G .intp d .Setoid._≈_ i j

Condrefl : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {σ} (d : ε ⊢ₛ σ ∷ Γ) (i : Cond G d) → CondEq G d i i
Condrefl G d i = G .intp d .Setoid.refl {i}

Condsym : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {σ} (d : ε ⊢ₛ σ ∷ Γ) {i j : Cond G d} (eq : CondEq G d i j) → CondEq G d j i
Condsym G d eq = G .intp d .Setoid.sym eq

Condtrans : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {σ} (d : ε ⊢ₛ σ ∷ Γ) {i j k : Cond G d} (eq : CondEq G d i j) (eq' : CondEq G d j k) → CondEq G d i k
Condtrans G d eq eq' = G .intp d .Setoid.trans eq eq'

-- Empty context

⟦ε⟧ : ∀{l} → Con l ε
⟦ε⟧ .intp ds .Setoid.Carrier = Lift ⊤
⟦ε⟧ .intp ds .Setoid._≈_ _ _ = Lift ⊤
⟦ε⟧ .intp ds .Setoid.isEquivalence .Relation.Binary.IsEquivalence.refl = _
⟦ε⟧ .intp ds .Setoid.isEquivalence .Relation.Binary.IsEquivalence.sym _ = _
⟦ε⟧ .intp ds .Setoid.isEquivalence .Relation.Binary.IsEquivalence.trans _ _ = _
⟦ε⟧ .bij ds ds' ess' .to ._⟨$⟩_ _ = _
⟦ε⟧ .bij ds ds' ess' .to .Function.Equality.cong _ = _
⟦ε⟧ .bij ds ds' ess' .bijective .injective _ = _
⟦ε⟧ .bij ds ds' ess' .bijective .surjective .Surjective.from = _
⟦ε⟧ .bij ds ds' ess' .bijective .surjective .right-inverse-of _ = _

-- Context extension

record SFam {l n} {Γ : Cxt n} (G : Con l Γ) (b : Exp n) : Set (level (1 + l)) where
  field
    intp : ∀ {σ} {ds : ε ⊢ₛ σ ∷ Γ} (γ : Cond G ds) → Type l (sub σ b)
    bij  : ∀ {σ σ'}
      {ds : ε ⊢ₛ σ ∷ Γ}
      {ds' : ε ⊢ₛ σ' ∷ Γ}
      (ess' : ε ⊢ₛ σ ≡ σ' ∷ Γ)
      (γ : Cond G ds)
      -- (γ' : Cond G ds')
      -- Need heterogenous equality!
      (let γ' = G .bij ds ds' ess' .to  ⟨$⟩ γ)
      {t} (dt : ε ⊢ t ∷ sub σ b) (dt' : ε ⊢ t ∷ sub σ' b) →
      Bijection (intp γ .Type.intp dt) (intp γ' .Type.intp dt')
      -- We do not need to generalize this to ε ⊢ t ≡ t' ∷ Γ
      -- since we already have this in Type
open SFam

hcast : ∀ {l n} {Γ : Cxt n} (G : Con l Γ) {b} (B : SFam G b) {σ} {ds : ε ⊢ₛ σ ∷ Γ} (γ γ' : Cond G ds) (φ : CondEq G ds γ γ')
  {u : Exp n} (du : ε ⊢ sub σ u ∷ sub σ b)
  → (i : Cand (B .intp γ) du)
  → Cand (B .intp γ') du
hcast {l} {n} {Γ} G {b} B {σ} {ds} γ γ' φ {u} du i = {!!}


Sigma : ∀{l n} {Γ : Cxt n} (G : Con l Γ) {b : Exp n} (B : SFam G b) → Con l (Γ , b)
Sigma G B .intp (ds , du) .Setoid.Carrier = ∃ λ (γ : Cond G ds) → Cand (B .intp γ) du
Sigma G B .intp (ds , du) .Setoid._≈_ (γ , i) (γ' , i') = ∃ λ (φ : CondEq G ds γ γ') → CandEq (B .intp γ') du {!B .bij i !} i'
Sigma G B .intp (ds , du) .Setoid.isEquivalence = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .to ._⟨$⟩_ = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .to .Function.Equality.cong = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .bijective .injective x₁ = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .bijective .surjective .Surjective.from ._⟨$⟩_ = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .bijective .surjective .Surjective.from .Function.Equality.cong = {!!}
Sigma G B .bij  (ds , du) (ds' , du') ess' .bijective .surjective .right-inverse-of (γ , i) = {!!}

-- Con : ∀{l n} {Γ : Cxt n} (dΓ : l ⊢ Γ) → Set (level (1 + l))
-- Con ε = {!!}
-- Con (cext dΓ da) = {!!}
