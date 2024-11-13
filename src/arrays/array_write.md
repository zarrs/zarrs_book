# Writing Arrays

Array write methods are separated into two traits.
The `[Async]WritableStorageTraits` perform write operations exclusively.
Conversely, the `[Async]ReadableWritableStorageTraits` methods may need to read and decode existing data before performing a write operation.

> [!WARNING]
> Misuse of `[Async]ReadableWritableStorageTraits` methods can result in data loss due to partial writes being lost.
> `zarrs` does not currently offer a “synchronisation” API for locking chunks or array subsets.

## Write-Only Methods

The [`[Async]WritableStorageTraits`](https://docs.rs/zarrs_storage/latest/zarrs_storage/trait.WritableStorageTraits.html) consist of methods that exclusively perform *write operations*:
<!-- - [`store_metadata`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_metadata) -->
<!-- - [`erase_metadata`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_metadata) -->
- [`store_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunk)
- [`store_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunks)
- [`store_encoded_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_encoded_chunk)
- [`erase_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_chunk)
- [`erase_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.erase_chunks)

> [!TIP]
> If a chunk is written more than once, its element values depend on whichever operation wrote to the chunk last.

## Read-Write Methods

Conversely, the [`[Async]ReadableWritableStorageTraits`](https://docs.rs/zarrs_storage/latest/zarrs_storage/trait.ReadableWritableStorageTraits.html) methods *may additionally perform read operations*:
   - [`store_chunk_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_chunk_subset)
   - [`store_array_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.store_array_subset)
   - [`partial_encoder`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.partial_encoder)

These methods perform partial encoding.
Codecs that do not support true partial encoding will retrieve chunks in their entirety, then decode, update, and store them.

It is the responsibility of zarrs consumers to ensure:

- `store_chunk_subset` is not called concurrently on the same chunk, and
- `store_array_subset` is not called concurrently on array subsets sharing chunks.

Partial writes to a chunk may be lost if these rules are not respected.

### Partial Encoding with the Sharding Codec

In `zarrs`, the `sharding_indexed` codec is the only codec that supports real partial encoding.
Inner chunks can be written in an append-only fashion without reading previously written inner chunks (if their elements do not require updating).

> [!TIP]
> True partial encoding is currently experimental. The [`Experimental Partial Encoding`](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html#experimental-partial-decoding) option must be enabled.
> If disabled (default), chunks are always fully decoded and updated before being stored.

<!-- TODO: Warning about shards being much larger if chunks are updated -->
