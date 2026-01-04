# Writing Arrays

[`Array`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html) write methods are separated based on two storage traits:
 - `[Async]WritableStorageTraits` methods perform write operations exclusively, and
 - `[Async]ReadableWritableStorageTraits` methods perform write operations and may perform read operations.

> [!WARNING]
> Misuse of `[Async]ReadableWritableStorageTraits` `Array` methods can result in data loss due to partial writes being lost.
> `zarrs` does not currently offer a “synchronisation” API for locking chunks or array subsets.

## Write-Only Methods

The [`[Async]WritableStorageTraits`](https://docs.rs/zarrs_storage/latest/zarrs_storage/trait.WritableStorageTraits.html) grouped methods exclusively perform *write operations*:
<!-- - [`store_metadata`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_metadata) -->
<!-- - [`erase_metadata`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_metadata) -->
- [`store_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunk)
- [`store_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunks)
- [`store_encoded_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_encoded_chunk)
- [`erase_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_chunk)
- [`erase_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_chunks)

### Store a Chunk

```rust
# extern crate zarrs;
# extern crate ndarray;
# use zarrs::array::{Array, ArrayBytes, ArrayBuilder, data_type};
# use ndarray::ArrayD;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array = ArrayBuilder::new(vec![8, 8], vec![4, 4], data_type::float32(), 0.0f32)
#     .build(store.clone(), "/array")?;
let chunk_indices: Vec<u64> = vec![1, 2];
let chunk_bytes: ArrayBytes = vec![0u8; 4 * 4 * 4].into(); // 4x4 chunk of f32
array.store_chunk(&chunk_indices, chunk_bytes)?;
let chunk_elements: Vec<f32> = vec![1.0; 4 * 4];
array.store_chunk(&chunk_indices, &chunk_elements)?;
let chunk_array = ArrayD::<f32>::from_shape_vec(
    vec![4, 4], // chunk shape
    chunk_elements
)?;
array.store_chunk(&chunk_indices, chunk_array)?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!TIP]
> If a chunk is written more than once, its element values depend on whichever operation wrote to the chunk last.

### Store Chunks

`store_chunks` (and variants) will dissasemble the input into chunks, and encode and store them in parallel.

```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBytes, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array = ArrayBuilder::new(vec![8, 8], vec![4, 4], data_type::float32(), 0.0f32)
#     .build(store.clone(), "/array")?;
let chunks_bytes: ArrayBytes = vec![0u8; 2 * 2 * 4 * 4 * 4].into(); // 2x2 chunks of 4x4 f32
array.store_chunks(&[0..2, 0..2], chunks_bytes)?;
// store_chunks_elements, store_chunks_ndarray...
# Ok::<_, Box<dyn std::error::Error>>(())
```

### Store an Encoded Chunk

An encoded chunk can be stored directly with [store_encoded_chunk](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_encoded_chunk), bypassing the `zarrs` codec pipeline.

```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array = ArrayBuilder::new(vec![8, 8], vec![4, 4], data_type::float32(), 0.0f32)
#     .build(store.clone(), "/array")?;
# let chunk_indices: Vec<u64> = vec![1, 2];
let encoded_chunk_bytes: Vec<u8> = vec![0u8; 4 * 4 * 4]; // pre-encoded bytes
// SAFETY: the encoded bytes are valid for the chunk (bytes codec only defaulted to native endianness)
unsafe { array.store_encoded_chunk(&chunk_indices, encoded_chunk_bytes.into())? };
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!TIP]
> Currently, the most performant path for uncompressed writing on Linux is to reuse page aligned buffers via `store_encoded_chunk` with direct IO enabled for the `FilesystemStore`.
> See [zarrs GitHub issue #58](https://github.com/zarrs/zarrs/pull/58) for a discussion of this method.

## Read-Write Methods

The [`[Async]ReadableWritableStorageTraits`](https://docs.rs/zarrs_storage/latest/zarrs_storage/trait.ReadableWritableStorageTraits.html) grouped methods perform write operations and *may perform read operations*:
   - [`store_chunk_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunk_subset)
   - [`store_array_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_array_subset)
   - [`partial_encoder`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.partial_encoder)

These methods perform partial encoding.
Codecs that do not support true partial encoding will retrieve chunks in their entirety, then decode, update, and store them.

It is the responsibility of zarrs consumers to ensure:

- `store_chunk_subset` is not called concurrently on the same chunk, and
- `store_array_subset` is not called concurrently on array subsets sharing chunks.

Partial writes to a chunk may be lost if these rules are not respected.

### Store a Chunk Subset

```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
let array = ArrayBuilder::new(vec![16, 8], vec![4, 4], data_type::float32(), 0.0f32)
    .build(store.clone(), "/array")?;
array.store_chunk_subset(
    // chunk indices
    &[3, 1],
    // subset within chunk
    &[1..2, 0..4],
    // subset elements
    &[-4.0f32; 4],
)?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

### Store an Array Subset

```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
let array = ArrayBuilder::new(vec![8, 8], vec![4, 4], data_type::float32(), 0.0f32)
    .build(store.clone(), "/array")?;
array.store_array_subset(&[0..8, 6..7], &[123.0f32; 8])?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

### Partial Encoding with the Sharding Codec

In `zarrs`, the `sharding_indexed` codec is the only codec that supports real partial encoding if the [`Experimental Partial Encoding`](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html#experimental-partial-decoding) option is enabled.
If disabled (default), chunks are always fully decoded and updated before being stored.

To enable partial encoding:
```rust
# extern crate zarrs;
# use zarrs::array::CodecOptions;
// Set experimental_partial_encoding to true by default
zarrs::config::global_config_mut().set_experimental_partial_encoding(true);

// Manually set experimental_partial_encoding to true for an operation
let mut options = CodecOptions::default();
options.set_experimental_partial_encoding(true);
```

> [!WARNING]
> The asynchronous API does not yet support partial encoding.

This enables `Array::store_array_subset`, `Array::store_chunk_subset`, `Array::partial_encoder`, and variants to use partial encoding for sharded arrays.
Inner chunks can be written in an append-only fashion without reading previously written inner chunks (if their elements do not require updating).

> [!WARNING]
> Since partial encoding is append-only for sharded arrays, updating a chunk does not remove the originally encoded data.
> Make sure to align writes to the inner chunks, otherwise your shards will be much larger than they should be.
