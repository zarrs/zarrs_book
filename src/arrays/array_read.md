# Reading Arrays

## Overview

Array operations are divided into several categories based on the traits implemented for the backing storage.
This section focuses on the [`[Async]ReadableStorageTraits`](https://docs.rs/zarrs_storage/latest/zarrs_storage/trait.ReadableStorageTraits.html) methods:
- [`retrieve_chunk_if_exists`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_chunk_if_exists)
- [`retrieve_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_chunk)
- [`retrieve_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_chunks)
- [`retrieve_chunk_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_chunk_subset)
- [`retrieve_array_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_array_subset)
- [`retrieve_encoded_chunk`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.retrieve_encoded_chunk)
- [`partial_decoder`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.partial_decoder)

Additional methods are offered by extension traits:
 - [`ArrayShardedExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedExt.html) and [`ArrayShardedReadableExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedReadableExt.html): see [Reading Sharded Arrays](#reading-inner-chunks-sharded-arrays)
 - [`ArrayChunkCacheExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayChunkCacheExt.html): see [Chunk Caching](#chunk-caching)

## Method Variants

Many `retrieve` and `store` methods have multiple variants:
  - Standard variants store or retrieve data represented as [`ArrayBytes`](https://docs.rs/zarrs/latest/zarrs/array/enum.ArrayBytes.html) (representing fixed or variable length bytes).
  - `_elements` suffix variants can store or retrieve chunks with a known type.
  - `_ndarray` suffix variants can store or retrieve an [`ndarray::Array`](https://docs.rs/ndarray/latest/ndarray/type.Array.html) (requires `ndarray` feature).
  - `_opt` suffix variants have a [`CodecOptions`](https://docs.rs/zarrs/latest/zarrs/array/codec/options/struct.CodecOptions.html) parameter for fine-grained concurrency control and more.
  - Variants without the `_opt` suffix use default `CodecOptions`.
  - `async_` prefix variants can be used with async stores (requires `async` feature).

## Reading a Chunk

### Reading and Decoding a Chunk
```rs
let chunk_indices: Vec<u64> = vec![1, 2];
let chunk_bytes: ArrayBytes = array.retrieve_chunk(&chunk_indices)?;
let chunk_elements: Vec<f32> =
    array.retrieve_chunk_elements(&chunk_indices)?;
let chunk_array: ndarray::ArrayD<f32> =
    array.retrieve_chunk_ndarray(&chunk_indices)?;
```

> [!WARNING]
> `_element` and `_ndarray` variants will fail if the element type does not match the array data type.
> They do not perform any conversion.

### Skipping Empty Chunks

Use `retrieve_chunk_if_exists` to only retrieve a chunk if it exists (i.e. is not composed entirely of the fill value, or has yet to be written to the store):
```rs
let chunk_bytes: Option<ArrayBytes> =
    array.retrieve_chunk_if_exists(&chunk_indices)?;
let chunk_elements: Option<Vec<f32>> =
    array.retrieve_chunk_elements_if_exists(&chunk_indices)?;
let chunk_array: Option<ndarray::ArrayD<f32>> =
    array.retrieve_chunk_ndarray_if_exists(&chunk_indices)?;
```

### Retrieving an Encoded Chunk

An encoded chunk can be retrieved without decoding with `retrieve_encoded_chunk`:
```rs
let chunk_bytes_encoded: Option<Vec<u8>> =
    array.retrieve_encoded_chunk(&chunk_indices)?;
```
This returns `None` if a chunk does not exist.

## Parallelism and Concurrency

### Codec and Chunk Parallelism

Codecs run in parallel on a threadpool.
Array store and retrieve methods will also run in parallel when they involve multiple chunks.
`zarrs` will automatically choose where to prioritise parallelism between codecs/chunks based on the codecs and number of chunks.

By default, all available CPU cores will be used (where possible/efficient).
Concurrency can be limited globally with [`Config::set_codec_concurrent_target`](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html#method.set_codec_concurrent_target) or as required using `_opt` methods with [`CodecOptions`](https://docs.rs/zarrs/latest/zarrs/array/codec/options/struct.CodecOptions.html) populated with [`CodecOptions::set_concurrent_target`](https://docs.rs/zarrs/latest/zarrs/array/codec/options/struct.CodecOptions.html#method.set_concurrent_target).

### Async API Concurrency
This crate is async runtime-agnostic.
Async methods do not spawn tasks internally, so asynchronous storage calls are concurrent but not parallel.
Codec encoding and decoding operations still execute in parallel (where supported) in an asynchronous context.

Due the lack of parallelism, methods like [`async_retrieve_array_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.async_retrieve_array_subset) or [`async_retrieve_chunks`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.async_retrieve_chunks) do not parallelise over chunks and can be slow compared to the  API.
Parallelism over chunks can be achieved by spawning tasks outside of `zarrs`.
If executing many tasks concurrently, consider reducing the codec [`concurrent_target`](https://docs.rs/zarrs/latest/zarrs/array/codec/options/struct.CodecOptions.html#method.set_concurrent_target).

## Reading Chunks in Parallel

The `retrieve_chunks` methods perform chunk retrieval with chunk parallelism.

Rather than taking a `&[u64]` parameter of the indices of a single chunk, these methods take an `ArraySubset` representing the chunks.
Rather than returning a `Vec` for each chunk, the chunks are assembled into a single output for the entire region they cover:
```rs
let chunks = ArraySubset::new_with_ranges(&[0..2, 0..4]);
let chunks_bytes: ArrayBytes = array.retrieve_chunks(&chunks)?;
let chunks_elements: Vec<f32> = array.retrieve_chunks_elements(&chunks)?;
let chunks_array: ndarray::ArrayD<f32> =
    array.retrieve_chunks_ndarray(&chunks)?;
```

`retrieve_encoded_chunks` differs in that it does not assemble the output.
Chunks returned are in order of the chunk indices returned by `chunks.indices().into_iter()`:
```rs
let chunk_bytes_encoded: Vec<Option<Vec<u8>>> =
    array.retrieve_encoded_chunks(&chunk_indices, &CodecOptions::default()?);
```

## Reading a Chunk Subset

An [`ArraySubset`](https://docs.rs/zarrs/latest/zarrs/array_subset/struct.ArraySubset.html) represents a subset (region) of an array or chunk.
It encodes a starting coordinate and a shape, and is foundational for many array operations.

The below array subsets are all identical:
```rs
let subset = ArraySubset::new_with_ranges(&[2..6, 3..5]);
let subset = ArraySubset::new_with_start_shape(vec![2, 3], vec![4, 2])?;
let subset = ArraySubset::new_with_start_end_exc(vec![2, 3], vec![6, 5])?;
let subset = ArraySubset::new_with_start_end_inc(vec![2, 3], vec![5, 4])?;
```

The `retrieve_chunk_subset` methods can be used to retrieve a subset of a chunk:
```rs
let chunk_subset: ArraySubset = ...;
let chunk_subset_bytes: ArrayBytes =
    array.retrieve_chunk_subset(&chunk_indices, &chunk_subset)?;
let chunk_subset_elements: Vec<f32> =
    array.retrieve_chunk_subset_elements(&chunk_indices, &chunk_subset)?;
let chunk_subset_array: ndarray::ArrayD<f32> =
    array.retrieve_chunk_subset_ndarray(&chunk_indices, &chunk_subset)?;
```

It is important to understand what is going on behind the scenes in these methods.
A partial decoder is created that decodes the requested subset.

> [!WARNING]
> Many codecs **do not support partial decoding**, so partial decoding may result in reading and decoding entire chunks!

## Reading Multiple Chunk Subsets

If multiple chunk subsets are needed from a chunk, prefer to create a partial decoder and reuse it for each chunk subset.

```rs
let partial_decoder = array.partial_decoder(&chunk_indices)?;
let chunk_subsets_bytes_a_b: Vec<ArrayBytes> =
    partial_decoder.partial_decode(&[chunk_subset_a, chunk_subset_b, ...])?;
let chunk_subsets_bytes_c: Vec<ArrayBytes> =
    partial_decoder.partial_decode(&[chunk_subset_c])?;
```

On initialisation, **partial decoders may insert a cache** (depending on the codecs).
For example, if a codec does not support partial decoding, its output (or an output of one of its predecessors in the codec chain) will be cached, and subsequent partial decoding operations will not access the store.

## Reading an Array Subset

An arbitrary subset of an array can be read with the `retrieve_chunk` methods:
```rs
let array_subset: ArraySubset = ...;
let subset_bytes: Vec<u8> =
    array.retrieve_array_subset(&array_subset)?;
let subset_elements: Vec<f32> =
    array.retrieve_array_subset_elements(&array_subset)?;
let subset_array: ndarray::ArrayD<f32> =
    array.retrieve_array_subset_ndarray(&array_subset)?;
```

Internally, these methods identify the overlapping chunks, call `retrieve_chunk` / `retrieve_chunk_subset` with chunk parallelism, and assemble the output.

## Reading Inner Chunks (Sharded Arrays)

The `sharding_indexed` codec enables multiple sub-chunks ("inner chunks") to be stored in a single chunk ("shard").
With a sharded array, the [`chunk_grid`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunk_grid) and chunk indices in store/retrieve methods reference the chunks ("shards") of an array.

The [`ArrayShardedExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedExt.html) trait provides additional methods to `Array` to query if an array is sharded and retrieve the inner chunk shape.
Additionally, the *inner chunk grid* can be queried, which is a [`ChunkGrid`](https://docs.rs/zarrs/latest/zarrs/array/chunk_grid/struct.ChunkGrid.html) where chunk indices refer to inner chunks rather than shards.

The [`ArrayShardedReadableExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedReadableExt.html) trait adds `Array` methods to conveniently and efficiently access the data in a sharded array (with `_elements` and `_ndarray` variants):
 - [`retrieve_inner_chunk_opt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedReadableExt.html#tymethod.retrieve_inner_chunk_opt)
 - [`retrieve_inner_chunks_opt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedReadableExt.html#tymethod.retrieve_inner_chunks_opt)
 - [`retrieve_array_subset_sharded_opt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayShardedReadableExt.html#tymethod.retrieve_array_subset_sharded_opt)

For unsharded arrays, these methods gracefully fallback to referencing standard chunks.
Each method has a `cache` parameter ([`ArrayShardedReadableExtCache`](https://docs.rs/zarrs/latest/zarrs/array/struct.ArrayShardedReadableExtCache.html)) that stores shard indexes so that they do not have to be repeatedly retrieved and decoded.

## Querying Chunk Bounds

Several convenience methods are available for querying the underlying chunk grid:
 - [`chunk_origin`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunk_origin): Get the origin of a chunk.
 - [`chunk_shape`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunk_shape): Get the shape of a chunk.
 - [`chunk_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunk_subset): Get the `ArraySubset` of a chunk.
 - [`chunk_subset_bounded`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunk_subset_bounded): Get the `ArraySubset` of a chunk, bounded by the array shape.
 - [`chunks_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunks_subset) / [`chunks_subset_bounded`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunks_subset_bounded): Get the `ArraySubset` of a group of chunks.
 - [`chunks_in_array_subset`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.chunks_in_array_subset): Get the chunks in an `ArraySubset`.

An `ArraySubset` spanning an array can be retrieved with [`subset_all`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.subset_all).

## Iterating Over Chunks / Regions

Iterating over chunks or regions is a common pattern.
There are several approaches.

### Serial Chunk Iteration
```rs
let indices = chunks.indices();
for chunk_indices in indices {
    ...
}
```

### Parallel Chunk Iteration
```rs
let indices = chunks.indices();
chunks.into_par_iter().try_for_each(|chunk_indices| {
    ...
})?;
```

> [!WARNING]
> Reading chunks in parallel (as above) can use a lot of memory if chunks are large.

The `zarrs` crate internally uses a macro from the [`rayon_iter_concurrent_limit`](https://docs.rs/rayon_iter_concurrent_limit/latest/rayon_iter_concurrent_limit/) crate to limit chunk parallelism where reasonable.
This macro is a simple wrapper over `.into_par_iter().chunks(...).<func>`.
For example:
```rs
let chunk_concurrent_limit: usize = 4;
rayon_iter_concurrent_limit::iter_concurrent_limit!(
    chunk_concurrent_limit,
    indices,
    try_for_each,
    |chunk_indices| { 
        ...
    }
)?;
```

<!-- TODO more types of iteration -->

## Chunk Caching

The standard `Array` retrieve methods do not perform any chunk caching.
This means that requesting the same chunk again will result in another read from the store.

The [`ArrayChunkCacheExt`](https://docs.rs/zarrs/latest/zarrs/array/trait.ArrayChunkCacheExt.html) trait adds `Array` retrieve methods that support chunk caching.
Various type of chunk caches are supported (e.g. encoded cache, decoded cache, chunk limited, size limited, thread local, etc.).
See the [Chunk Caching](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#chunk-caching) section of the `Array` docs for more information on these methods.

Chunk caching is likely to be effective for remote stores where redundant retrievals are costly.
However, chunk caching may not outperform disk caching with a filesystem store.
The caches use internal locking to support multithreading, which has a performance overhead.

> [!WARNING]
> Prefer not to use a chunk cache if chunks are not accessed repeatedly.
> Cached retrieve methods do not use partial decoders, and any intersected chunk is fully decoded if not present in the cache.

For many access patterns, chunk caching may reduce performance.
**Benchmark your algorithm/data**.

## Reading a String Array

A string array can be read as normal with any of the array retrieve methods.

```rs
let chunks_elements: Vec<String> = array.retrieve_chunks_elements(&chunks)?;
let chunks_array: ndarray::ArrayD<String> =
    array.retrieve_chunks_ndarray(&chunks)?;
```

However, this results in a string allocation per element.
This can be avoided by retrieving the bytes directly and converting them to a `Vec` of string references.
For example:
```rs
let chunks_bytes: ArrayBytes = array.retrieve_chunks(&chunks)?;
let (bytes, offsets) = chunks_bytes.into_variable()?;
let string = String::from_utf8(bytes.into_owned())?;
let chunks_elements: Vec<&str> = offsets
    .iter()
    .tuple_windows()
    .map(|(&curr, &next)| &string[curr..next])
    .collect();
let chunks_array =
    ArrayD::<&str>::from_shape_vec(subset_all.shape_usize(), chunks_elements)?;
```
