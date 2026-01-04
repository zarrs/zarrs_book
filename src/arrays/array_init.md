# Array Initialisation

## Opening an Existing Array

An existing array can be opened with [`Array::open`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.open) (or [`async_open`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.async_open)):
```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
let array_path = "/group/array";
# let array = ArrayBuilder::new(
#     vec![8, 8], // array shape
#     vec![4, 4], // regular chunk shape
#     data_type::float32(),
#     f32::NAN,
# ).build(store.clone(), array_path)?;
# array.store_metadata()?;
let array = Array::open(store.clone(), array_path)?;
// let array = Array::async_open(store.clone(), array_path).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!NOTE]
> These methods will open a Zarr V2 or Zarr V3 array.
> If you only want to open a specific Zarr version, see [`open_opt`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.open_opt) and [`MetadataRetrieveVersion`](https://docs.rs/zarrs/latest/zarrs/config/enum.MetadataRetrieveVersion.html).

## Creating a Zarr V3 Array with the `ArrayBuilder`

> [!NOTE]
> The `ArrayBuilder` only supports Zarr V3 groups.

```rust
# extern crate zarrs;
# use std::sync::Arc;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
let array_path = "/group/array";
let array = ArrayBuilder::new(
    vec![8, 8], // array shape
    vec![4, 4], // regular chunk shape
    data_type::float32(),
    f32::NAN,
)
// .bytes_to_bytes_codecs(vec![]) // uncompressed
.bytes_to_bytes_codecs(vec![
    Arc::new(zarrs::array::codec::GzipCodec::new(5)?),
])
.dimension_names(["y", "x"].into())
// .attributes(...)
// .storage_transformers(vec![].into())
.build(store.clone(), array_path)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

`ArrayBuilder::new` supports more advanced initialisation from metadata, explicit extensions, etc.
Consult the documentation.

> [!TIP]
> The [Group Initialisation Chapter](./group_init.md) has tips for creating attributes.


## Remember to Store Metadata!
Array metadata must **always** be stored explicitly, otherwise an array cannot be opened.

> [!TIP]
> Consider deferring storage of array metadata until after chunks operations are complete.
> The presence of valid metadata can act as a signal that the data is ready.

## Creating a Zarr V3 Sharded Array

The [`ShardingCodecBuilder`](https://docs.rs/zarrs/latest/zarrs/array/codec/array_to_bytes/sharding/struct.ShardingCodecBuilder.html) is useful for creating an array that uses the `sharding_indexed` codec.

```rust
# extern crate zarrs;
# use std::sync::Arc;
# use std::num::NonZeroU64;
# use zarrs::array::{Array, ArrayBuilder, data_type, codec::array_to_bytes::sharding::ShardingCodecBuilder};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array_path = "/group/array";
let mut sharding_codec_builder = ShardingCodecBuilder::new(
    vec![NonZeroU64::new(2).unwrap(); 2].into(), // inner chunk shape
    &data_type::float32(),
);
sharding_codec_builder.bytes_to_bytes_codecs(vec![
    Arc::new(zarrs::array::codec::GzipCodec::new(5)?),
]);

let array = ArrayBuilder::new(
    vec![8, 8], // array shape
    vec![4, 4], // regular chunk shape
    data_type::float32(),
    f32::NAN,
)
.array_to_bytes_codec(sharding_codec_builder.build_arc())
.build(store.clone(), array_path)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

## Creating a Zarr V3 Array from Metadata

An array can be created from `ArrayMetadata` instead of an `ArrayBuilder` if needed.


```rust
# extern crate zarrs;
# use std::sync::Arc;
# use zarrs::array::Array;
# use zarrs::metadata::ArrayMetadata;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array_path = "/group/array";
let json: &str = r#"{
  "zarr_format": 3,
  "node_type": "array",
  "shape": [
    10000,
    1000
  ],
  "data_type": "float64",
  "chunk_grid": {
    "name": "regular",
    "configuration": {
      "chunk_shape": [
        1000,
        100
      ]
    }
  },
  "chunk_key_encoding": {
    "name": "default",
    "configuration": {
      "separator": "/"
    }
  },
  "fill_value": "NaN",
  "codecs": [
    {
      "name": "bytes",
      "configuration": {
        "endian": "little"
      }
    },
      {
        "name": "gzip",
        "configuration": {
            "level": 1
        }
    }
  ],
  "attributes": {
    "foo": 42,
    "bar": "apples",
    "baz": [
      1,
      2,
      3,
      4
    ]
  },
  "dimension_names": [
    "rows",
    "columns"
  ]
}"#;

/// Parse the JSON metadata
let array_metadata: ArrayMetadata = serde_json::from_str(json)?;

/// Create the array
let array = Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata.into(),
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

Alternatively, `ArrayMetadataV3` can be constructed with `ArrayMetadataV3::new()` and subsequent `with_` methods:

```rust
# extern crate zarrs;
# use std::sync::Arc;
# use zarrs::array::Array;
# use zarrs::metadata::{ArrayMetadata, v3::ArrayMetadataV3};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
/// Specify the array metadata
let array_metadata: ArrayMetadata = ArrayMetadataV3::new(
    serde_json::from_str("[10, 10]")?,
    serde_json::from_str(r#"{"name": "regular", "configuration":{"chunk_shape": [5, 5]}}"#)?,
    serde_json::from_str(r#""float32""#)?,
    serde_json::from_str("0.0")?,
    serde_json::from_str(r#"[ {"name": "bytes", "configuration": { "endian": "little" } }, { "name": "blosc", "configuration": { "cname": "blosclz", "clevel": 9, "shuffle": "bitshuffle", "typesize": 2, "blocksize": 0 } } ]"#)?,
).with_chunk_key_encoding(
    serde_json::from_str(r#"{"name": "default", "configuration": {"separator": "/"}}"#)?,
).with_attributes(
    serde_json::from_str(r#"{"foo": 42, "bar": "apples", "baz": [1, 2, 3, 4]}"#)?,
)
// .with_dimension_names(
//     Some(serde_json::from_str(r#"["y", "x"]"#)?),
// )
.into();

/// Create the array
let array = Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata,
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

## Creating a Zarr V2 Array

The `ArrayBuilder` does not support Zarr V2 arrays.
Instead, they must be built from `ArrayMetadataV2`.

```rust
# extern crate zarrs;
# use std::sync::Arc;
# use std::num::NonZeroU64;
# use zarrs::array::Array;
# use zarrs::metadata::{ArrayMetadata, ChunkKeySeparator, v2::ArrayMetadataV2, v2::FillValueMetadataV2, v2::ArrayMetadataV2Order};
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
/// Specify the array metadata
let array_metadata: ArrayMetadata = ArrayMetadataV2::new(
    vec![10, 10], // array shape
    vec![NonZeroU64::new(5).unwrap(); 2].into(), // regular chunk shape
    ">f4".into(), // big endian float32
    FillValueMetadataV2::from(f32::NAN), // fill value
    None, // compressor
    None, // filters
)
.with_dimension_separator(ChunkKeySeparator::Slash)
.with_order(ArrayMetadataV2Order::F)
.into();

/// Create the array
let array = Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata,
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!WARNING]
> `Array::new_with_metadata` can fail if Zarr V2 metadata is unsupported by `zarrs`.

## Mutating Array Metadata

The shape, dimension names, attributes, and additional fields of an array are mutable.
- [`Array::set_shape`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.set_shape)
- [`Array::set_dimension_names`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.set_dimension_names)
- [`Array::attributes_mut`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.attributes_mut)
- [`Array::additional_fields_mut`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.additional_fields_mut)

Don't forget to write the metadata after mutating array metadata!

---

The next chapters detail the reading and writing of array data.
