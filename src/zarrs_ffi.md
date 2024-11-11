# C/C++ Bindings (zarrs_ffi)

`zarrs_ffi` is a single header library: `zarrs.h` [(API docs)](https://ldeakin.github.io/zarrs_ffi/zarrs_8h.html).

Currently `zarrs_ffi` only supports a subset of the `zarrs` API.
However, it is sufficient for typical reading and writing of Zarr hierarchies.

These bindings are used in production at the [Department of Materials Physics](https://physics.anu.edu.au/research/mp/), Australian National University, Canberra, Australia.

## CMake Quickstart
1. Install the Rust compiler (and cargo).
2. Put [Findzarrs.cmake](https://github.com/LDeakin/zarrs_ffi/blob/main/examples/cmake_project/Findzarrs.cmake) in your `CMAKE_MODULE_PATH`
3. `find_package(zarrs <version> REQUIRED COMPONENTS zarrs/bz2)`
   - Replace `<version>` with the latest release: [![Latest Version](https://img.shields.io/crates/v/zarrs_ffi.svg)](https://crates.io/crates/zarrs_ffi) (e.g., `0.8` or `0.8.4`)
   - `zarrs` is retrieved from `GitHub` using [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html) and built using [corrosion](https://github.com/corrosion-rs/corrosion)
   - Components are optional `zarrs` codecs
4. the `zarrs_ffi` library is available as the `zarrs::zarrs` or  `zarrs::zarrs-static` target

A complete `CMake` example can be found in [zarrs_ffi/examples/cmake_project](https://github.com/LDeakin/zarrs_ffi/tree/main/examples/cmake_project).

For more comprehensive build instructions, see the [zarrs_ffi/README.md](https://github.com/LDeakin/zarrs_ffi).

## Example
```C++
#include "zarrs.h"

void main() {
  // Open a filesystem store pointing to a zarr hierarchy
  ZarrsStorage storage = nullptr;
  zarrs_assert(zarrsCreateStorageFilesystem("/path/to/hierarchy.zarr", &storage));

  // Open an array in the hierarchy
  ZarrsArray array = nullptr;
  zarrsOpenArrayRW(storage, "/array", metadata, &array);

  // Get the array dimensionality
  size_t dimensionality;
  zarrs_assert(zarrsArrayGetDimensionality(array, &dimensionality));
  assert(dimensionality == 2);

  // Retrieve the decoded bytes of the chunk at [0, 0]
  size_t indices[] = {0, 0};
  size_t chunk_size;
  zarrs_assert(zarrsArrayGetChunkSize(array, 2, indices, &chunk_size));
  std::unique_ptr<uint8_t[]> chunk_bytes(new uint8_t[chunk_size]);
  zarrs_assert(zarrsArrayRetrieveChunk(array, 2, indices, chunk_size, chunk_bytes.get()));
}
```

Complete examples can be found in [zarrs_ffi/examples](https://github.com/LDeakin/zarrs_ffi/tree/main/examples).
