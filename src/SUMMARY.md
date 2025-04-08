# Summary

[Introduction](introduction.md)

# Rust (zarrs)
- [Installation](installation.md)
- [Stores](./stores.md)
- [Groups](./groups.md)
- [Arrays](./arrays.md)
  - [Initialisation](./arrays/array_init.md)
  - [Reading](./arrays/array_read.md)
  - [Writing](./arrays/array_write.md)
- [Converting Zarr V2 to V3](v2_to_v3.md)
- [Extension Points](extensions.md)
  - [Codecs](./extensions/codec.md)
  <!-- - [Data Types](./extensions/data_type.md) -->
  <!-- - [Chunk Grids] -->
  <!-- - [Chunk Key Encodings] -->
  <!-- - [Storage Transformers] -->
  <!-- - [Custom Stores] -->

# Bindings

- [Python (zarrs_python)](zarrs_python.md)
- [C/C++ (zarrs_ffi)](zarrs_ffi.md)

# CLI Tools

- [zarrs_tools](zarrs_tools.md)
  - [zarrs_reencode: reencode/rechunk Zarr arrays](zarrs_tools/docs/zarrs_reencode.md)
  - [zarrs_ome: convert to OME-Zarr multiscales](zarrs_tools/docs/zarrs_ome.md)
  - [zarrs_filter: apply image transformations](zarrs_tools/docs/zarrs_filter.md)
  - [zarrs_validate: validate array equivalence](zarrs_tools/docs/zarrs_validate.md)
  - [zarrs_info: get array/group information](zarrs_tools/docs/zarrs_info.md)
  - [zarrs_binary2zarr: convert piped binary data to Zarr](zarrs_tools/docs/zarrs_binary2zarr.md)
