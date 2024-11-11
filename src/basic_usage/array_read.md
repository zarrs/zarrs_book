# Reading Arrays

## Overview

Array operations are divided into several categories based on the traits implemented for the backing storage.
The core array methods are:
 - [`ReadableStorageTraits`](crate::storage::ReadableStorageTraits): read array data and metadata
   - [`retrieve_chunk_if_exists`](Array::retrieve_chunk_if_exists)
   - [`retrieve_chunk`](Array::retrieve_chunk)
   - [`retrieve_chunks`](Array::retrieve_chunks)
   - [`retrieve_chunk_subset`](Array::retrieve_chunk_subset)
   - [`retrieve_array_subset`](Array::retrieve_array_subset)
   - [`retrieve_encoded_chunk`](Array::retrieve_encoded_chunk)
   - [`partial_decoder`](Array::partial_decoder)
 - [`WritableStorageTraits`](crate::storage::WritableStorageTraits): store/erase array data and store metadata
   - [`store_metadata`](Array::store_metadata)
   - [`store_chunk`](Array::store_chunk)
   - [`store_chunks`](Array::store_chunks)
   - [`store_encoded_chunk`](Array::store_encoded_chunk)
   - [`erase_chunk`](Array::erase_chunk)
   - [`erase_chunks`](Array::erase_chunks)
 - [`ReadableWritableStorageTraits`](crate::storage::ReadableWritableStorageTraits): store operations requiring reading *and* writing
   - [`store_chunk_subset`](Array::store_chunk_subset)
   - [`store_array_subset`](Array::store_array_subset)
   - [`partial_encoder`](Array::partial_encoder)

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
let chunk_bytes: Vec<u8> = array.retrieve_chunk(&chunk_indices)?;
let chunk_elements: Vec<f32> =
    array.retrieve_chunk_elements(&chunk_indices)?;
let chunk_array: ndarray::ArrayD<f32> =
    array.retrieve_chunk_ndarray(&chunk_indices)?;
```

> [!WARNING]
> `_element` variants will fail if the element type does not match the array data type.
> They do not perform any conversion.

### Codec Parallelism

<!-- TODO: Discuss codec parallelism -->

### Skipping Empty Chunks

### Retrieving an Encoded Chunk

An encoded chunk can be retrieved without decoding with `retrieve_encoded_chunk`:
```rs
let chunk_bytes_encoded: Option<Vec<u8>> =
    array.retrieve_encoded_chunk(&chunk_indices);
```
This returns `None` if a chunk does not exist.


## Reading Chunks

<!-- TODO -->

`retrieve_encoded_chunks` executes with chunk parallelism
```rs
let chunk_bytes_encoded: Vec<Option<Vec<u8>>> =
    array.retrieve_encoded_chunks(&chunk_indices, &CodecOptions::defualt());
```
The chunks returned are in order of the chunk indices returned by chunks.indices().into_iter().

### Chunk Parallelism


## Iterating Over Chunks
```rs
let indices = chunks.indices();
for chunk_indices in indices {
    ...
}
```

```rs
let indices = chunks.indices();
chunks.into_par_iter().try_for_each(|chunk_indices| {
    ...
})?;
```

## Reading a Subset

An [`ArraySubset`](https://docs.rs/zarrs/latest/zarrs/array_subset/struct.ArraySubset.html) represents a subset (region) of an array or chunk.
It encodes a starting coordinate and a shape, and is a foundation for many array operations.

The below array subsets are all identical:
```rs
let subset = ArraySubset::new_with_ranges(&[2..6, 3..5]);
let subset = ArraySubset::new_with_start_shape(vec![2, 3], vec![4, 2])?;
let subset = ArraySubset::new_with_start_end_exc(vec![2, 3], vec![6, 5])?;
let subset = ArraySubset::new_with_start_end_inc(vec![2, 3], vec![5, 4])?;
```

Like the `retrieve_chunk` methods, `retrieve_array_subset` methods with similar variants:
```rs
let subset_bytes: Vec<u8> = array.retrieve_array_subset(&subset)?;
let subset_elements: Vec<f32> =
    array.retrieve_array_subset_elements(&subset)?;
let subset_array: ndarray::ArrayD<f32> =
    array.retrieve_array_subset_ndarray(&subset)?;
```

<!-- TODO: Discuss parallelism -->
<!-- TODO: Discuss partial decoding -->


## Reading Inner Chunks (Sharded Arrays)

## Reading Encoded Chunks


