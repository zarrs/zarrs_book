# Introduction

> [!NOTE]
> 🚧 This book is under construction!

## `zarrs` - A Rust Library for the Zarr Storage Format

`zarrs` is a Rust library for the Zarr V2 and Zarr V3 array storage formats.
If you don't know what Zarr is, check out:
- the official Zarr website: [zarr.dev](https://zarr.dev), and
- the [Zarr V3 specification](https://zarr-specs.readthedocs.io/en/latest/v3/core/v3.0.html).

`zarrs` was originally designed exclusively as a Rust library for Zarr V3.
However, it now supports a V3 compatible subset of Zarr V2, and has Python and C/C++ bindings.

This book focuses mostly on the Rust implementation.

## Using `zarrs` in the `zarr-python` Reference Implementation

If you are only interested in using `zarrs` from Python, skip ahead to the [Python Bindings (zarrs-python) Chapter](./zarrs_python.md).

The Python bindings ([![zarr-python](https://img.shields.io/badge/ilan--gold/zarrs--python-GitHub-blue?logo=github)](https://github.com/ilan-gold/zarrs-python)) expose a high-performance codec pipeline to the [![zarr-python](https://img.shields.io/badge/zarr--developers/zarr--python-GitHub-blue?logo=github)](https://github.com/zarr-developers/zarr-python) reference implementation that uses `zarrs` under the hood.
There is no need to learn a new API and it is supported by downstream libraries like `dask`.

> [!WARNING]
> The `zarrs-python` implementation is highly experimental and has some limitations.
> Consult the documentation for more information.

## 🚀 `zarrs` is Fast

The [![zarr_benchmarks](https://img.shields.io/badge/LDeakin/zarr__benchmarks-GitHub-blue?logo=github)](https://github.com/LDeakin/zarr_benchmarks) repository includes benchmarks `zarrs` against other Zarr V3 implementations.
Check out the benchmarks below that measure the time to round trip a \\(1024x2048x2048\\) `uint16` array encoded in various ways:

![benchmark standalone](./zarr_benchmarks/plots/benchmark_roundtrip.svg)

![benchmark dask](./zarr_benchmarks/plots/benchmark_roundtrip_dask.svg)

More information on these benchmarks can be found in the [![zarr_benchmarks](https://img.shields.io/badge/LDeakin/zarr__benchmarks-GitHub-blue?logo=github)](https://github.com/LDeakin/zarr_benchmarks) repository.
