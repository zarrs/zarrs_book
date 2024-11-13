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

```rs
let chunk_indices: Vec<u64> = vec![1, 2];
let chunk_bytes: Vec<u8> = vec![...];
array.store_chunk(&chunk_indices, chunk_bytes.into())?;
let chunk_elements: Vec<f32> = vec![...];
array.store_chunk_elements(&chunk_indices, &chunk_elements)?;
let chunk_array = ArrayD::<f32>::from_shape_vec(
    vec![2, 2], // chunk shape
    chunk_elements
)?;
array.store_chunk_elements(&chunk_indices, chunk_array)?;
```

> [!TIP]
> If a chunk is written more than once, its element values depend on whichever operation wrote to the chunk last.

### Store Chunks

`store_chunks` (and variants) will dissasemble the input into chunks, and encode and store them in parallel.

```rs
let chunks = ArraySubset::new_with_ranges(&[0..2, 0..4]);
let chunks_bytes: Vec<u8> = vec![...];
array.store_chunks(&chunks, chunks_bytes.into())?;
// store_chunks_elements, store_chunks_ndarray...
```

### Store an Encoded Chunk

An encoded chunk can be stored directly with [store_encoded_chunk](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_encoded_chunk), bypassing the `zarrs` codec pipeline.

> [!TIP]
> Currently, the most performant path for uncompressed writing on Linux is to reuse page aligned buffers via `store_encoded_chunk` with direct IO enabled for the `FilesystemStore`.
> See [zarrs GitHub issue #58](https://github.com/LDeakin/zarrs/pull/58) for a discussion of this method.

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

<!-- TODO -->

### Store an Array Subset

<!-- TODO -->

### Store Array Subsets

<!-- TODO -->

### Partial Encoding with the Sharding Codec

In `zarrs`, the `sharding_indexed` codec is the only codec that supports real partial encoding.
Inner chunks can be written in an append-only fashion without reading previously written inner chunks (if their elements do not require updating).

> [!TIP]
> True partial encoding is currently experimental. The [`Experimental Partial Encoding`](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html#experimental-partial-decoding) option must be enabled.
> If disabled (default), chunks are always fully decoded and updated before being stored.

<!-- TODO: Warning about shards being much larger if chunks are updated -->
