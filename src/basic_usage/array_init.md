# Array Initialisation

## The Sync and Async API
See the [Group Initialisation Chapter](./group_init.md).

## Opening an Existing Array

Opening an existing array is as simple as calling [`Array::open`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.open) (or [`async_open`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.async_open)):
```rs
let array_path = "/group/array";
let array = Array::open(store.clone(), array_path)?;
// let array = Array::async_open(store.clone(), array_path).await?;
```

These methods will open a Zarr V2 or Zarr V3 array.
If you only want to open a specific Zarr version, see [`open_opt`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html#method.open_opt) and [`MetadataRetrieveVersion`](https://docs.rs/zarrs/latest/zarrs/config/enum.MetadataRetrieveVersion.html).

## Creating an Array with the `ArrayBuilder`

> [!NOTE]
> The `ArrayBuilder` only supports Zarr V3 groups.

```rs
let array_path = "/group/array";
let array = zarrs::array::ArrayBuilder::new(
    vec![8, 8], // array shape
    DataType::Float32,
    vec![4, 4].try_into()?, // regular chunk shape
    FillValue::from(ZARR_NAN_F32),
)
// .bytes_to_bytes_codecs(vec![]) // uncompressed
.bytes_to_bytes_codecs(vec![
    Arc::new(GzipCodec::new(5)?),
])
.dimension_names(["y", "x"].into())
// .attributes(...)
// .storage_transformers(vec![].into())
.build(store.clone(), array_path)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
```

> [!TIP]
> The [Group Initialisation Chapter](./group_init.md) has tips for creating attributes.


### Remember to Store Metadata!
`store_metadata` is explicitly called after creating an array in the examples above.

> [!WARNING]
> Array metadata must **always** be stored explicitly, otherwise an array cannot be opened.

> [!TIP]
> Consider deferring storage of array metadata until after chunks operations are complete.
> The presence of valid metadata can act as a signal that the data is ready.

## Creating a Sharded Array

The [`ShardingCodecBuilder`](https://docs.rs/zarrs/latest/zarrs/array/codec/array_to_bytes/sharding/struct.ShardingCodecBuilder.html) is useful for creating an array that uses the `sharding_indexed` codec.

```rs
let mut sharding_codec_builder = ShardingCodecBuilder::new(
    vec![4, 4].try_into()? // inner chunk shape
);
sharding_codec_builder.bytes_to_bytes_codecs(vec![
    Arc::new(codec::GzipCodec::new(5)?),
]);

let array = zarrs::array::ArrayBuilder::new(
    ...
)
.array_to_bytes_codec(sharding_codec_builder.build_arc())
.build(store.clone(), array_path)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
```

## Creating an Array from `ArrayMetadata`

An array can be created from `ArrayMetadata` instead of an `ArrayBuilder`.
However, it is much more verbose.

### Zarr V3

```rs
let json = const JSON_ARRAY: &str = r#"{
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
let array = zarrs::array::Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata.into(),
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
```


```rs
/// Specify the array metadata
let array_metadata = ArrayMetadataV3::new(
    serde_json::from_str("[10, 10]"),
    serde_json::from_str(r#"{"name": "regular", "configuration":{"chunk_shape": [5, 5]}}"#)?,
    serde_json::from_str(r#""float32""#)?,
    serde_json::from_str("0.0")?,
    serde_json::from_str(r#"[ { "name": "blosc", "configuration": { "cname": "blosclz", "clevel": 9, "shuffle": "bitshuffle", "typesize": 2, "blocksize": 0 } } ]"#)?,
).with_chunk_key_encoding(
    serde_json::from_str(r#"{"name": "default", "configuration": {"separator": "/"}}"#)?,
).with_attributes(
    serde_json::from_str(r#"{"foo": 42, "bar": "apples", "baz": [1, 2, 3, 4]}"#)?,
).with_dimension_names(
    Some(serde_json::from_str(r#"["y", "x"]"#)?),
);

/// Create the array
let array = zarrs::array::Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata.into(),
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
```

### Zarr V2

```rs
/// Specify the array metadata
let array_metadata = ArrayMetadataV2::new(
    vec![10, 10], // array shape
    vec![5, 5].try_into()?, // regular chunk shape
    ">f4".into(), // big endian float32
    FillValueMetadataV2::NaN, // fill value
    None, // compressor
    None, // filters
)
.with_dimension_separator(ChunkKeySeparator::Slash)
.with_order(ArrayMetadataV2Order::F)
.with_attributes(attributes.clone());

/// Create the array
let array = zarrs::array::Array::new_with_metadata(
    store.clone(),
    "/group/array",
    array_metadata.into(),
)?;
array.store_metadata()?;
// array.async_store_metadata().await?;
```

The next chapters detail the reading and writing of array data.
