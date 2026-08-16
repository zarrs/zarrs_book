# Introduction

`zarrs` is a Rust library for the Zarr V2 and Zarr V3 array storage formats.
If you don't know what Zarr is, check out:
- the official Zarr website: [zarr.dev](https://zarr.dev), and
- the [Zarr V3 specification](https://zarr-specs.readthedocs.io/en/latest/v3/core/v3.0.html).

`zarrs` was originally designed exclusively as a Rust library for Zarr V3.
However, it now supports a V3 compatible subset of Zarr V2, and has Python and C/C++ bindings.
The community has since built `zarrs`-backed bindings for [other languages](#community-third-party), such as MATLAB, R, and Julia.
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

Below is an overview of the crate structure.
Crates highlighted in orange are [community (third party)](#community-third-party) projects.
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

Most Zarr [extension points](./extensions.md) also have their own API crate:
- `zarrs_data_type` [![zarrs_data_type_ver]](https://crates.io/crates/zarrs_data_type) [![zarrs_data_type_doc]](https://docs.rs/zarrs_data_type) [![zarrs_data_type_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_data_type)
- `zarrs_codec` [![zarrs_codec_ver]](https://crates.io/crates/zarrs_codec) [![zarrs_codec_doc]](https://docs.rs/zarrs_codec) [![zarrs_codec_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_codec)
- `zarrs_chunk_grid` [![zarrs_chunk_grid_ver]](https://crates.io/crates/zarrs_chunk_grid) [![zarrs_chunk_grid_doc]](https://docs.rs/zarrs_chunk_grid) [![zarrs_chunk_grid_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_chunk_grid)
- `zarrs_chunk_key_encoding` [![zarrs_chunk_key_encoding_ver]](https://crates.io/crates/zarrs_chunk_key_encoding) [![zarrs_chunk_key_encoding_doc]](https://docs.rs/zarrs_chunk_key_encoding) [![zarrs_chunk_key_encoding_repo]](https://github.com/zarrs/zarrs/tree/main/zarrs_chunk_key_encoding)

> [!TIP]
> The supplementary crates are transitive dependencies of `zarrs`, and are re-exported by it.
> You do not need to add them as direct dependencies.
> The extension point API crates are re-exported as `zarrs::array::{data_type,codec,chunk_grid,chunk_key_encoding}::api`, and their key types are re-exported directly in `zarrs::array`.
> The storage transformer API is the exception: it lives in `zarrs` itself as `zarrs::array::storage_transformer`.

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

[zarrs_codec_ver]: https://img.shields.io/crates/v/zarrs_codec
[zarrs_codec_doc]: https://docs.rs/zarrs_codec/badge.svg
[zarrs_codec_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__codec-GitHub-blue?logo=github

[zarrs_chunk_grid_ver]: https://img.shields.io/crates/v/zarrs_chunk_grid
[zarrs_chunk_grid_doc]: https://docs.rs/zarrs_chunk_grid/badge.svg
[zarrs_chunk_grid_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__chunk__grid-GitHub-blue?logo=github

[zarrs_chunk_key_encoding_ver]: https://img.shields.io/crates/v/zarrs_chunk_key_encoding
[zarrs_chunk_key_encoding_doc]: https://docs.rs/zarrs_chunk_key_encoding/badge.svg
[zarrs_chunk_key_encoding_repo]: https://img.shields.io/badge/zarrs/zarrs/zarrs__chunk__key__encoding-GitHub-blue?logo=github

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

## Community (Third Party)

A growing ecosystem of projects builds on `zarrs`: bindings that expose it to other languages, and crates that extend it with additional stores, codecs, conventions, and format support.

> [!NOTE]
> The projects in this section are developed and maintained by the community, independently of `zarrs`.
> Zarr feature coverage, maturity, and support vary considerably, so consult each project's own documentation.
> Please [open an issue](https://github.com/zarrs/zarrs_book/issues) to add a project to this list.

### Language Bindings

- `zarrista` (Python) [![zarrista_ver]](https://pypi.org/project/zarrista/) [![zarrista_doc]](https://developmentseed.org/zarrista) [![zarrista_repo]](https://github.com/developmentseed/zarrista)
- `zarr-matlab` (MATLAB) [![zarr_matlab_repo]](https://github.com/scalableminds/zarr-matlab)
- `pizzarr` (R) [![pizzarr_ver]](https://cran.r-project.org/package=pizzarr) [![pizzarr_doc]](https://zarr.dev/pizzarr/) [![pizzarr_repo]](https://github.com/zarr-developers/pizzarr)
- `Rzarrs` (R) [![Rzarrs_repo]](https://github.com/RGenomicsETL/Rzarrs)
- `Zarrs.jl` (Julia) [![Zarrs_jl_repo]](https://github.com/earth-mover/Zarrs.jl)

[zarrista_ver]: https://img.shields.io/pypi/v/zarrista
[zarrista_doc]: https://img.shields.io/badge/docs-developmentseed.org-blue
[zarrista_repo]: https://img.shields.io/badge/developmentseed/zarrista-GitHub-blue?logo=github

[zarr_matlab_repo]: https://img.shields.io/badge/scalableminds/zarr--matlab-GitHub-blue?logo=github

[pizzarr_ver]: https://www.r-pkg.org/badges/version/pizzarr
[pizzarr_doc]: https://img.shields.io/badge/docs-zarr.dev/pizzarr-blue
[pizzarr_repo]: https://img.shields.io/badge/zarr--developers/pizzarr-GitHub-blue?logo=github

[Rzarrs_repo]: https://img.shields.io/badge/RGenomicsETL/Rzarrs-GitHub-blue?logo=github

[Zarrs_jl_repo]: https://img.shields.io/badge/earth--mover/Zarrs.jl-GitHub-blue?logo=github

#### `zarrista` (Python)

A low-level Zarr API for Python built directly on `zarrs`, in the style of `zarrita`.
Unlike [`zarrs-python`](#python-bindings-zarrs-python), which slots a `zarrs`-backed codec pipeline underneath `zarr-python`, `zarrista` exposes `zarrs` itself: it has its own API with synchronous and asynchronous variants, zero-copy `numpy` interoperability, and support for `icechunk` and `object_store` stores.
The Python API is not yet stable.

#### `zarr-matlab` (MATLAB)

A Zarr V2 and V3 implementation for MATLAB based on `zarrs`, which is called through a Rust MEX layer.
It supports reading and writing arrays and groups, chunking and sharding, a range of codecs, and filesystem and read-only HTTP stores.

#### `pizzarr` (R)

A Zarr implementation for R that ships in two builds of the same version.
The CRAN build is pure R with no compiled dependencies, whereas the [r-universe](https://zarr-developers.r-universe.dev/pizzarr) build links `zarrs` through [`extendr`](https://extendr.github.io/) as a backend, adding parallel decompression, additional codec support, and cloud stores.

#### `Rzarrs` (R)

R bindings to `zarrs` through the [`savvy`](https://github.com/yutannihilation/savvy) crate, distributed via [r-universe](https://sounkou-bioinfo.r-universe.dev/Rzarrs).
It is reader-first, supporting filesystem, HTTP/HTTPS, S3, and `.zarr.zip` stores.

#### `Zarrs.jl` (Julia)

Zarr V2 and V3 arrays for Julia backed by `zarrs` through a C FFI shim, including `icechunk` support.

> [!NOTE]
> `Zarrs.jl` is experimental.
> Its README recommends [`Zarr.jl`](https://github.com/JuliaIO/Zarr.jl) if a mature pure-Julia implementation is needed.

### Extension Crates

These crates extend `zarrs` through its [extension points](./extensions.md) and [storage API](./stores.md).

- `zarrs_n5` [![zarrs_n5_ver]](https://crates.io/crates/zarrs_n5) [![zarrs_n5_doc]](https://docs.rs/zarrs_n5) [![zarrs_n5_repo]](https://github.com/clbarnes/zarrs_n5)
  - Read-only [N5](https://github.com/saalfeldlab/n5) support, including the `gzip`, `bzip2`, `zstd`, and `blosc` N5 compressors.
- `zarrs_conventions` [![zarrs_conventions_ver]](https://crates.io/crates/zarrs_conventions) [![zarrs_conventions_doc]](https://docs.rs/zarrs_conventions) [![zarrs_conventions_repo]](https://github.com/clbarnes/zarrs_conventions)
  - An implementation of the [zarr-conventions](https://github.com/zarr-conventions/zarr-conventions-spec) specification, which standardises how conventions are declared in Zarr attributes.
  - Companion crates implement individual conventions:
    - `zarrs_conventions_license` [![zarrs_conventions_license_ver]](https://crates.io/crates/zarrs_conventions_license) [![zarrs_conventions_license_doc]](https://docs.rs/zarrs_conventions_license) implements the [license](https://github.com/clbarnes/zarr-convention-license) convention, which communicates the licence(s) of the data in a group or array.
    - `zarrs_conventions_thumbnails` [![zarrs_conventions_thumbnails_ver]](https://crates.io/crates/zarrs_conventions_thumbnails) [![zarrs_conventions_thumbnails_doc]](https://docs.rs/zarrs_conventions_thumbnails) implements the [thumbnails](https://github.com/clbarnes/zarr-convention-thumbnails) convention, which references images representing a node for use in galleries and previews.
    - `zarrs_conventions_uom` [![zarrs_conventions_uom_ver]](https://crates.io/crates/zarrs_conventions_uom) [![zarrs_conventions_uom_doc]](https://docs.rs/zarrs_conventions_uom) implements the [units of measure](https://github.com/clbarnes/zarr-convention-uom) convention, which communicates the units of a numeric array.
- `ndic-zarr` [![ndic_zarr_ver]](https://crates.io/crates/ndic-zarr) [![ndic_zarr_doc]](https://docs.rs/ndic-zarr) [![ndic_zarr_repo]](https://github.com/fideus-labs/nd-image-codecs)
  - Zarr V3 codecs for multidimensional scientific images: `nd_lift`, `htj2k`, and `nd_zfp`.
- `zarrs_sqlite` [![zarrs_sqlite_repo]](https://github.com/clbarnes/zarrs_sqlite)
  - An SQLite-based Zarr store with `rusqlite` and `turso` backends, tracking a [store specification proposal](https://github.com/auxym/zarr-sqlite-python/pull/4).
- `zarrs_jpeg` [![zarrs_jpeg_repo]](https://github.com/clbarnes/zarrs_jpeg)
  - An implementation of the proposed [`jpeg` codec](https://github.com/zarr-developers/zarr-extensions/pull/66) backed by `libjpeg-turbo`.

> [!WARNING]
> Some of these crates are works in progress that have not been published to [crates.io](https://crates.io).

[zarrs_n5_ver]: https://img.shields.io/crates/v/zarrs_n5
[zarrs_n5_doc]: https://docs.rs/zarrs_n5/badge.svg
[zarrs_n5_repo]: https://img.shields.io/badge/clbarnes/zarrs__n5-GitHub-blue?logo=github

[zarrs_conventions_ver]: https://img.shields.io/crates/v/zarrs_conventions
[zarrs_conventions_doc]: https://docs.rs/zarrs_conventions/badge.svg
[zarrs_conventions_repo]: https://img.shields.io/badge/clbarnes/zarrs__conventions-GitHub-blue?logo=github

[zarrs_conventions_license_ver]: https://img.shields.io/crates/v/zarrs_conventions_license
[zarrs_conventions_license_doc]: https://docs.rs/zarrs_conventions_license/badge.svg

[zarrs_conventions_thumbnails_ver]: https://img.shields.io/crates/v/zarrs_conventions_thumbnails
[zarrs_conventions_thumbnails_doc]: https://docs.rs/zarrs_conventions_thumbnails/badge.svg

[zarrs_conventions_uom_ver]: https://img.shields.io/crates/v/zarrs_conventions_uom
[zarrs_conventions_uom_doc]: https://docs.rs/zarrs_conventions_uom/badge.svg

[ndic_zarr_ver]: https://img.shields.io/crates/v/ndic-zarr
[ndic_zarr_doc]: https://docs.rs/ndic-zarr/badge.svg
[ndic_zarr_repo]: https://img.shields.io/badge/fideus--labs/nd--image--codecs-GitHub-blue?logo=github

[ndic_cli_ver]: https://img.shields.io/crates/v/ndic-cli

[zarrs_sqlite_repo]: https://img.shields.io/badge/clbarnes/zarrs__sqlite-GitHub-blue?logo=github

[zarrs_jpeg_repo]: https://img.shields.io/badge/clbarnes/zarrs__jpeg-GitHub-blue?logo=github

