# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-04-02

### Breaking

- `PeriodicArray` gained a fifth type parameter `G` for the inverse map (`imap`).
  The type signature changed from `PeriodicArray{T,N,A,F}` to
  `PeriodicArray{T,N,A,F,G}`.  Any code with explicit type annotations,
  dispatch rules, or type introspection on the four-parameter form will need
  to be updated.
- The internal field previously named `.map` is now named `.fmap`; a new field
  `.imap` holds the inverse map.  Direct field access must be updated accordingly.
- The module was reorganised into separate source files
  (`types.jl`, `indexing.jl`, `broadcast.jl`, `vector_interface.jl`,
  `repeat.jl`, `circshift.jl`, `reverse.jl`, `mapped_ref.jl`).

### Added

- `PeriodicArray` now accepts an explicit `imap` argument (the inverse map used by
  `setindex!`).  When omitted, `imap` defaults to `NegatedShiftMap(fmap)`, i.e.
  `(x, shifts...) -> fmap(x, -shifts...)`, preserving the previous behaviour.
  Supplying a custom `imap` is useful when `fmap` is not self-inverse under shift
  negation, or when mutation should be explicitly forbidden (pass an `imap` that throws).
- New `MappedRef` type and `mapped_ref(arr, I...)` function.  `mapped_ref` returns a
  lazy, mutable wrapper for an out-of-bounds element that applies the forward map on
  reads and the inverse map on writes, solving the long-standing limitation where
  iterated indexing for mutation silently did nothing (e.g. `x[i][j] = v`).