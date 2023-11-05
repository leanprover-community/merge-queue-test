/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin, Robert Y. Lewis
-/
import Mathlib.Algebra.CharP.Invertible
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.MvPolynomial.Variables
import Mathlib.Data.MvPolynomial.CommRing
import Mathlib.Data.MvPolynomial.Expand
import Mathlib.Data.ZMod.Basic

#align_import ring_theory.witt_vector.witt_polynomial from "leanprover-community/mathlib"@"c3019c79074b0619edb4b27553a91b2e82242395"

/-!
# Witt polynomials

xyz change

To endow `WittVector p R` with a ring structure,
we need to study the so-called Witt polynomials.

Fix a base value `p : ℕ`.
The `p`-adic Witt polynomials are an infinite family of polynomials
indexed by a natural number `n`, taking values in an arbitrary ring `R`.
The variables of these polynomials are represented by natural numbers.
The variable set of the `n`th Witt polynomial contains at most `n+1` elements `{0, ..., n}`,
with exactly these variables when `R` has characteristic `0`.

These polynomials are used to define the addition and multiplication operators
on the type of Witt vectors. (While this type itself is not complicated,
the ring operations are what make it interesting.)

When the base `p` is invertible in `R`, the `p`-adic Witt polynomials
form a basis for `MvPolynomial ℕ R`, equivalent to the standard basis.

## Main declarations

* `WittPolynomial p R n`: the `n`-th Witt polynomial, viewed as polynomial over the ring `R`
* `xInTermsOfW p R n`: if `p` is invertible, the polynomial `X n` is contained in the subalgebra
  generated by the Witt polynomials. `xInTermsOfW p R n` is the explicit polynomial,
  which upon being bound to the Witt polynomials yields `X n`.
* `bind₁_wittPolynomial_xInTermsOfW`: the proof of the claim that
  `bind₁ (xInTermsOfW p R) (W_ R n) = X n`
* `bind₁_xInTermsOfW_wittPolynomial`: the converse of the above statement

blahblahblah

## Notation

In this file we use the following notation

* `p` is a natural number, typically assumed to be prime.
* `R` and `S` are commutative rings
* `W n` (and `W_ R n` when the ring needs to be explicit) denotes the `n`th Witt polynomial

## References

* [Hazewinkel, *Witt Vectors*][Haze09]

* [Commelin and Lewis, *Formalizing the Ring of Witt Vectors*][CL21]
-/


open MvPolynomial

open Finset hiding map

open Finsupp (single)

open BigOperators

--attribute [-simp] coe_eval₂_hom

variable (p : ℕ)

variable (R : Type*) [CommRing R] [DecidableEq R]

/-- `wittPolynomial p R n` is the `n`-th Witt polynomial
with respect to a prime `p` with coefficients in a commutative ring `R`.
It is defined as:

`∑_{i ≤ n} p^i X_i^{p^{n-i}} ∈ R[X_0, X_1, X_2, …]`. -/
noncomputable def wittPolynomial (n : ℕ) : MvPolynomial ℕ R :=
  ∑ i in range (n + 1), monomial (single i (p ^ (n - i))) ((p : R) ^ i)
#align witt_polynomial wittPolynomial

theorem wittPolynomial_eq_sum_C_mul_X_pow (n : ℕ) :
    wittPolynomial p R n = ∑ i in range (n + 1), C ((p : R) ^ i) * X i ^ p ^ (n - i) := by
  apply sum_congr rfl
  rintro i -
  rw [monomial_eq, Finsupp.prod_single_index]
  rw [pow_zero]
set_option linter.uppercaseLean3 false in
#align witt_polynomial_eq_sum_C_mul_X_pow wittPolynomial_eq_sum_C_mul_X_pow

/-! We set up notation locally to this file, to keep statements short and comprehensible.
This allows us to simply write `W n` or `W_ ℤ n`. -/


-- mathport name: witt_polynomial
-- Notation with ring of coefficients explicit
set_option quotPrecheck false in
scoped[Witt] notation "W_" => wittPolynomial p

-- mathport name: witt_polynomial.infer
-- Notation with ring of coefficients implicit
set_option quotPrecheck false in
scoped[Witt] notation "W" => wittPolynomial p _

open Witt

open MvPolynomial

/- The first observation is that the Witt polynomial doesn't really depend on the coefficient ring.
If we map the coefficients through a ring homomorphism, we obtain the corresponding Witt polynomial
over the target ring. -/
section

variable {R} {S : Type*} [CommRing S]

@[simp]
theorem map_wittPolynomial (f : R →+* S) (n : ℕ) : map f (W n) = W n := by
  rw [wittPolynomial, map_sum, wittPolynomial]
  refine sum_congr rfl fun i _ => ?_
  rw [map_monomial, RingHom.map_pow, map_natCast]
#align map_witt_polynomial map_wittPolynomial

variable (R)

@[simp]
theorem constantCoeff_wittPolynomial [hp : Fact p.Prime] (n : ℕ) :
    constantCoeff (wittPolynomial p R n) = 0 := by
  simp only [wittPolynomial, map_sum, constantCoeff_monomial]
  rw [sum_eq_zero]
  rintro i _
  rw [if_neg]
  rw [Finsupp.single_eq_zero]
  exact ne_of_gt (pow_pos hp.1.pos _)
#align constant_coeff_witt_polynomial constantCoeff_wittPolynomial

@[simp]
theorem wittPolynomial_zero : wittPolynomial p R 0 = X 0 := by
  simp only [wittPolynomial, X, sum_singleton, range_one, pow_zero, zero_add, tsub_self]
#align witt_polynomial_zero wittPolynomial_zero

@[simp]
theorem wittPolynomial_one : wittPolynomial p R 1 = C (p : R) * X 1 + X 0 ^ p := by
  simp only [wittPolynomial_eq_sum_C_mul_X_pow, sum_range_succ_comm, range_one, sum_singleton,
    one_mul, pow_one, C_1, pow_zero, tsub_self, tsub_zero]
#align witt_polynomial_one wittPolynomial_one

theorem aeval_wittPolynomial {A : Type*} [CommRing A] [Algebra R A] (f : ℕ → A) (n : ℕ) :
    aeval f (W_ R n) = ∑ i in range (n + 1), (p : A) ^ i * f i ^ p ^ (n - i) := by
  simp [wittPolynomial, AlgHom.map_sum, aeval_monomial, Finsupp.prod_single_index]
#align aeval_witt_polynomial aeval_wittPolynomial

/-- Over the ring `ZMod (p^(n+1))`, we produce the `n+1`st Witt polynomial
by expanding the `n`th Witt polynomial by `p`.
-/
@[simp]
theorem wittPolynomial_zmod_self (n : ℕ) :
    W_ (ZMod (p ^ (n + 1))) (n + 1) = expand p (W_ (ZMod (p ^ (n + 1))) n) := by
  simp only [wittPolynomial_eq_sum_C_mul_X_pow]
  rw [sum_range_succ, ← Nat.cast_pow, CharP.cast_eq_zero (ZMod (p ^ (n + 1))) (p ^ (n + 1)), C_0,
    zero_mul, add_zero, AlgHom.map_sum, sum_congr rfl]
  intro k hk
  rw [AlgHom.map_mul, AlgHom.map_pow, expand_X, algHom_C, ← pow_mul, ← pow_succ]
  congr
  rw [mem_range] at hk
  rw [add_comm, add_tsub_assoc_of_le (Nat.lt_succ_iff.mp hk), ← add_comm]
#align witt_polynomial_zmod_self wittPolynomial_zmod_self

section PPrime

variable [hp : NeZero p]

theorem wittPolynomial_vars [CharZero R] (n : ℕ) : (wittPolynomial p R n).vars = range (n + 1) := by
  have : ∀ i, (monomial (Finsupp.single i (p ^ (n - i))) ((p : R) ^ i)).vars = {i} := by
    intro i
    refine' vars_monomial_single i (pow_ne_zero _ hp.1) _
    rw [← Nat.cast_pow, Nat.cast_ne_zero]
    exact pow_ne_zero i hp.1
  rw [wittPolynomial, vars_sum_of_disjoint]
  · simp only [this, biUnion_singleton_eq_self]
  · simp only [this]
    intro a b h
    apply disjoint_singleton_left.mpr
    rwa [mem_singleton]
#align witt_polynomial_vars wittPolynomial_vars

theorem wittPolynomial_vars_subset (n : ℕ) : (wittPolynomial p R n).vars ⊆ range (n + 1) := by
  rw [← map_wittPolynomial p (Int.castRingHom R), ← wittPolynomial_vars p ℤ]
  apply vars_map
#align witt_polynomial_vars_subset wittPolynomial_vars_subset

end PPrime

end

/-!

## Witt polynomials as a basis of the polynomial algebra

If `p` is invertible in `R`, then the Witt polynomials form a basis
of the polynomial algebra `MvPolynomial ℕ R`.
The polynomials `xInTermsOfW` give the coordinate transformation in the backwards direction.
-/


/-- The `xInTermsOfW p R n` is the polynomial on the basis of Witt polynomials
that corresponds to the ordinary `X n`. -/
noncomputable def xInTermsOfW [Invertible (p : R)] : ℕ → MvPolynomial ℕ R
  | n => (X n - ∑ i : Fin n,
          have := i.2
          C ((p : R) ^ (i : ℕ)) * xInTermsOfW i ^ p ^ (n - (i : ℕ))) * C ((⅟ p : R) ^ n)
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W xInTermsOfW

theorem xInTermsOfW_eq [Invertible (p : R)] {n : ℕ} :
    xInTermsOfW p R n =
      (X n - ∑ i in range n, C ((p: R) ^ i) * xInTermsOfW p R i ^ p ^ (n - i)) * C ((⅟p : R) ^ n) :=
  by rw [xInTermsOfW, ← Fin.sum_univ_eq_sum_range]
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W_eq xInTermsOfW_eq

@[simp]
theorem constantCoeff_xInTermsOfW [hp : Fact p.Prime] [Invertible (p : R)] (n : ℕ) :
    constantCoeff (xInTermsOfW p R n) = 0 := by
  apply Nat.strongInductionOn n; clear n
  intro n IH
  rw [xInTermsOfW_eq, mul_comm, RingHom.map_mul, RingHom.map_sub, map_sum, constantCoeff_C,
    constantCoeff_X, zero_sub, mul_neg, neg_eq_zero]
  -- porting note: here, we should be able to do `rw [sum_eq_zero]`, but the goal that
  -- is created is not what we expect, and the sum is not replaced by zero...
  -- is it a bug in `rw` tactic?
  refine' Eq.trans (_ : _ = ((⅟↑p : R) ^ n)* 0) (mul_zero _)
  congr 1
  rw [sum_eq_zero]
  intro m H
  rw [mem_range] at H
  simp only [RingHom.map_mul, RingHom.map_pow, map_natCast, IH m H]
  rw [zero_pow, mul_zero]
  apply pow_pos hp.1.pos
set_option linter.uppercaseLean3 false in
#align constant_coeff_X_in_terms_of_W constantCoeff_xInTermsOfW

@[simp]
theorem xInTermsOfW_zero [Invertible (p : R)] : xInTermsOfW p R 0 = X 0 := by
  rw [xInTermsOfW_eq, range_zero, sum_empty, pow_zero, C_1, mul_one, sub_zero]
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W_zero xInTermsOfW_zero

section PPrime

variable [hp : Fact p.Prime]

theorem xInTermsOfW_vars_aux (n : ℕ) :
    n ∈ (xInTermsOfW p ℚ n).vars ∧ (xInTermsOfW p ℚ n).vars ⊆ range (n + 1) := by
  apply Nat.strongInductionOn n; clear n
  intro n ih
  rw [xInTermsOfW_eq, mul_comm, vars_C_mul _ (nonzero_of_invertible _),
    vars_sub_of_disjoint, vars_X, range_succ, insert_eq]
  on_goal 1 =>
    simp only [true_and_iff, true_or_iff, eq_self_iff_true, mem_union, mem_singleton]
    intro i
    rw [mem_union, mem_union]
    apply Or.imp id
  on_goal 2 => rw [vars_X, disjoint_singleton_left]
  all_goals
    intro H
    replace H := vars_sum_subset _ _ H
    rw [mem_biUnion] at H
    rcases H with ⟨j, hj, H⟩
    rw [vars_C_mul] at H
    swap
    · apply pow_ne_zero
      exact_mod_cast hp.1.ne_zero
    rw [mem_range] at hj
    replace H := (ih j hj).2 (vars_pow _ _ H)
    rw [mem_range] at H
  · rw [mem_range]
    linarith
  · linarith
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W_vars_aux xInTermsOfW_vars_aux

theorem xInTermsOfW_vars_subset (n : ℕ) : (xInTermsOfW p ℚ n).vars ⊆ range (n + 1) :=
  (xInTermsOfW_vars_aux p n).2
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W_vars_subset xInTermsOfW_vars_subset

end PPrime

theorem xInTermsOfW_aux [Invertible (p : R)] (n : ℕ) :
    xInTermsOfW p R n * C ((p : R) ^ n) =
      X n - ∑ i in range n, C ((p : R) ^ i) * xInTermsOfW p R i ^ p ^ (n - i) := by
  rw [xInTermsOfW_eq, mul_assoc, ← C_mul, ← mul_pow, invOf_mul_self,
    one_pow, C_1, mul_one]
set_option linter.uppercaseLean3 false in
#align X_in_terms_of_W_aux xInTermsOfW_aux

@[simp]
theorem bind₁_xInTermsOfW_wittPolynomial [Invertible (p : R)] (k : ℕ) :
    bind₁ (xInTermsOfW p R) (W_ R k) = X k := by
  rw [wittPolynomial_eq_sum_C_mul_X_pow, AlgHom.map_sum]
  simp only [Nat.cast_pow, AlgHom.map_pow, C_pow, AlgHom.map_mul, algHom_C]
  rw [sum_range_succ_comm, tsub_self, pow_zero, pow_one, bind₁_X_right, mul_comm, ← C_pow,
    xInTermsOfW_aux]
  simp only [Nat.cast_pow, C_pow, bind₁_X_right, sub_add_cancel]
set_option linter.uppercaseLean3 false in
#align bind₁_X_in_terms_of_W_witt_polynomial bind₁_xInTermsOfW_wittPolynomial

@[simp]
theorem bind₁_wittPolynomial_xInTermsOfW [Invertible (p : R)] (n : ℕ) :
    bind₁ (W_ R) (xInTermsOfW p R n) = X n := by
  apply Nat.strongInductionOn n
  clear n
  intro n H
  rw [xInTermsOfW_eq, AlgHom.map_mul, AlgHom.map_sub, bind₁_X_right, algHom_C, AlgHom.map_sum,
    show X n = (X n * C ((p : R) ^ n)) * C ((⅟p : R) ^ n) by
      rw [mul_assoc, ← C_mul, ← mul_pow, mul_invOf_self, one_pow, map_one, mul_one]]
  congr 1
  rw [wittPolynomial_eq_sum_C_mul_X_pow, sum_range_succ_comm,
    tsub_self, pow_zero, pow_one, mul_comm (X n), add_sub_assoc, add_right_eq_self, sub_eq_zero]
  apply sum_congr rfl
  intro i h
  rw [mem_range] at h
  rw [AlgHom.map_mul, AlgHom.map_pow, algHom_C, H i h]
set_option linter.uppercaseLean3 false in
#align bind₁_witt_polynomial_X_in_terms_of_W bind₁_wittPolynomial_xInTermsOfW
