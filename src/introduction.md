# Introduction

`zarrs` is a Rust library for the Zarr V2 and Zarr V3 array storage formats.
If you don't know what Zarr is, check out:
- the official Zarr website: [zarr.dev](https://zarr.dev), and
- the [Zarr V3 specification](https://zarr-specs.readthedocs.io/en/latest/v3/core/v3.0.html).

`zarrs` was originally designed exclusively as a Rust library for Zarr V3.
However, it now supports a V3 compatible subset of Zarr V2, and has Python and C/C++ bindings.
This book details the Rust implementation.

## 🚀 `zarrs` is Fast 🚀

The [![zarr_benchmarks](https://img.shields.io/badge/zarrs/zarr__benchmarks-GitHub-blue?logo=github)](https://github.com/zarrs/zarr_benchmarks) repository includes benchmarks of `zarrs` against other Zarr V3 implementations.
Check out the benchmarks below that measure the time to round trip a \\(1024x2048x2048\\) `uint16` array encoded in various ways.
The `zarr_benchmarks` repository includes additional benchmarks.

![benchmark standalone](./zarr_benchmarks/plots/benchmark_roundtrip.svg)

<!-- ![benchmark dask](./zarr_benchmarks/plots/benchmark_roundtrip_dask.svg) -->

## Python Bindings: `zarrs-python` [![zarrs_python_ver]](https://pypi.org/project/zarrs/) [![zarrs_python_doc]](https://zarrs-python.readthedocs.io/en/latest/) [![zarrs_python_repo]](https://github.com/zarrs/zarrs-python)
[zarrs_python_ver]: https://img.shields.io/pypi/v/zarrs
[zarrs_python_doc]: https://img.shields.io/readthedocs/zarrs-python
[zarrs_python_repo]: https://img.shields.io/badge/zarrs/zarrs--python-GitHub-blue?logo=github

`zarrs-python` exposes a high-performance `zarrs`-backed codec pipeline to the reference [![zarr-python](https://img.shields.io/badge/zarr--developers/zarr--python-GitHub-blue?logo=github)](https://github.com/zarr-developers/zarr-python) Python package. It is enabled as follows:

```python
from zarr import config
import zarrs # noqa: F401

config.set({"codec_pipeline.path": "zarrs.ZarrsCodecPipeline"})
```

That's it!
There is no need to learn a new API and it is supported by downstream libraries like `dask`.
However, `zarrs-python` has some limitations.
Consult the [`zarrs-python` README](https://github.com/zarrs/zarrs-python) or [`PyPi` docs](https://pypi.org/project/zarrs/) for more details.

## Rust Crates

The Zarr specification is inherently unstable.
It is under active development and new extensions are regularly being introduced.

The `zarrs` crate has been split into multiple crates to:
- allow external implementations of stores and extensions points to target a relatively stable API compatible with a range of `zarrs` versions,
- enable automatic backporting of metadata compatibility fixes and changes due to standardisation,
- stay up-to-date with unstable public dependencies (e.g. `opendal`, `object_store`, `icechunk`, etc) without impacting the release cycle of `zarrs`, and
- improve compilation times.

Below is an overview of the crate structure:
<object data="./crates.svg" type="image/svg+xml"></object>

The core crate is:
- `zarrs` [![zarrs_ver]](https://crates.io/crates/zarrs) [![zarrs_doc]](https://docs.rs/zarrs) [![zarrs_repo]](https://github.com/zarrs/zarrs)

[zarrs_ver]: https://img.shields.io/crates/v/zarrs
[zarrs_doc]: https://docs.rs/zarrs/badge.svg
[zarrs_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs-GitHub-blue?logo=github

For local filesystem stores (referred to as *native Zarr*), this is the only crate you need to depend on.

`zarrs` has quite a few supplementary crates:
- `zarrs_metadata` [![zarrs_metadata_ver]](https://crates.io/crates/zarrs_metadata) [![zarrs_metadata_doc]](https://docs.rs/zarrs_metadata) [![zarrs_metadata_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_metadata)
- `zarrs_metadata_ext` [![zarrs_metadata_ext_ver]](https://crates.io/crates/zarrs_metadata_ext) [![zarrs_metadata_ext_doc]](https://docs.rs/zarrs_metadata_ext) [![zarrs_metadata_ext_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_metadata_ext)
- `zarrs_storage` [![zarrs_storage_ver]](https://crates.io/crates/zarrs_storage) [![zarrs_storage_doc]](https://docs.rs/zarrs_storage) [![zarrs_storage_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_storage)
- `zarrs_plugin` [![zarrs_plugin_ver]](https://crates.io/crates/zarrs_plugin) [![zarrs_plugin_doc]](https://docs.rs/zarrs_plugin) [![zarrs_plugin_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_plugin)
- `zarrs_data_type` [![zarrs_data_type_ver]](https://crates.io/crates/zarrs_data_type) [![zarrs_data_type_doc]](https://docs.rs/zarrs_data_type) [![zarrs_data_type_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_data_type)
- `zarrs_registry` [![zarrs_registry_ver]](https://crates.io/crates/zarrs_registry) [![zarrs_registry_doc]](https://docs.rs/zarrs_registry) [![zarrs_registry_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_registry)

> [!TIP]
> The supplementary crates are transitive dependencies of `zarrs`, and are re-exported in the crate root.
> You do not need to add them as direct dependencies.

> [!NOTE]
> The supplementary crates are separated from `zarrs` to enable development of Zarr extensions and stores targeting a more stable API than `zarrs` itself.

[zarrs_metadata_ver]: https://img.shields.io/crates/v/zarrs_metadata
[zarrs_metadata_doc]: https://docs.rs/zarrs_metadata/badge.svg
[zarrs_metadata_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__metadata-GitHub-blue?logo=github

[zarrs_metadata_ext_ver]: https://img.shields.io/crates/v/zarrs_metadata_ext
[zarrs_metadata_ext_doc]: https://docs.rs/zarrs_metadata_ext/badge.svg
[zarrs_metadata_ext_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__metadata_ext-GitHub-blue?logo=github

[zarrs_storage_ver]: https://img.shields.io/crates/v/zarrs_storage
[zarrs_storage_doc]: https://docs.rs/zarrs_storage/badge.svg
[zarrs_storage_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__storage-GitHub-blue?logo=github

[zarrs_plugin_ver]: https://img.shields.io/crates/v/zarrs_plugin
[zarrs_plugin_doc]: https://docs.rs/zarrs_plugin/badge.svg
[zarrs_plugin_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__plugin-GitHub-blue?logo=github

[zarrs_data_type_ver]: https://img.shields.io/crates/v/zarrs_data_type
[zarrs_data_type_doc]: https://docs.rs/zarrs_data_type/badge.svg
[zarrs_data_type_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__data_type-GitHub-blue?logo=github

[zarrs_registry_ver]: https://img.shields.io/crates/v/zarrs_registry
[zarrs_registry_doc]: https://docs.rs/zarrs_registry/badge.svg
[zarrs_registry_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__registry-GitHub-blue?logo=github

Additional crates need to be added as dependencies in order to use:
- remote stores (e.g. HTTP, S3, GCP, etc.),
- `zip` stores, or
- `icechunk` transactional storage.

The [Stores](./stores.md) chapter details the various types of stores and their associated crates.

## C/C++ Bindings: `zarrs_ffi` [![zarrs_ffi_ver]](https://crates.io/crates/zarrs_ffi) [![zarrs_ffi_doc]](https://docs.rs/zarrs_ffi) [![zarrs_ffi_repo]](https://github.com/zarrs/zarrs_ffi)
[zarrs_ffi_ver]: https://img.shields.io/crates/v/zarrs_ffi
[zarrs_ffi_doc]: https://docs.rs/zarrs_ffi/badge.svg
[zarrs_ffi_repo]: https://img.shields.io/badge/zarrs/zarrs__ffi-GitHub-blue?logo=github

A subset of `zarrs` exposed as a C/C++ API.
`zarrs_ffi` is a single header library: `zarrs.h`.
Consult the [`zarrs_ffi` README](https://github.com/zarrs/zarrs_ffi) and [API docs](https://zarrs.github.io/zarrs_ffi/zarrs_8h.html) for more information.

## CLI Tools: `zarrs_tools` [![zarrs_tools_ver]](https://crates.io/crates/zarrs_tools) [![zarrs_tools_doc]](https://docs.rs/zarrs_tools) [![zarrs_tools_repo]](https://github.com/zarrs/zarrs_tools)
[zarrs_tools_ver]: https://img.shields.io/crates/v/zarrs_tools
[zarrs_tools_doc]: https://docs.rs/zarrs_tools/badge.svg
[zarrs_tools_repo]: https://img.shields.io/badge/zarrs/zarrs__tools-GitHub-blue?logo=github

Various tools for creating and manipulating Zarr v3 data with the `zarrs` rust crate.
This crate is detailed in the [zarrs_tools](./zarrs_tools.md) chapter.

## Zarr Metadata Conventions

### `ome_zarr_metadata` [![ome_zarr_metadata_ver]](https://crates.io/crates/ome_zarr_metadata) [![ome_zarr_metadata_doc]](https://docs.rs/ome_zarr_metadata) [![ome_zarr_metadata_repo]](https://github.com/zarrs/ome_zarr_metadata)
[ome_zarr_metadata_ver]: https://img.shields.io/crates/v/ome_zarr_metadata
[ome_zarr_metadata_doc]: https://docs.rs/ome_zarr_metadata/badge.svg
[ome_zarr_metadata_repo]: https://img.shields.io/badge/zarrs/rust__ome__zarr__metadata-GitHub-blue?logo=github

A Rust library for [OME-Zarr](https://ngff.openmicroscopy.org/latest/) (previously OME-NGFF) metadata.

OME-Zarr, formerly known as OME-NGFF (Open Microscopy Environment Next Generation File Format), is a specification designed to support modern scientific imaging needs.
It is widely used in microscopy, bioimaging, and other scientific fields requiring high-dimensional data management, visualisation, and analysis.

