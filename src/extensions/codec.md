# Codec Extensions

> [!NOTE]
> This page is written against `zarrs` 0.20, which is unreleased at the time of writing.

Among the most impactful and frequently utilised extension points are **codecs**. At their core, codecs define the transformations applied to array chunk data as it moves between its logical, in-memory representation and its serialized, stored representation as a sequence of bytes.

Codecs are the workhorses behind essential Zarr features like **compression** (reducing storage size and transfer time) and **filtering** (rearranging or modifying data to improve compression effectiveness). The Zarr v3 specification allows for a **pipeline of codecs** to be defined for each array, where the output of one codec becomes the input for the next during encoding, and the process is reversed during decoding.

## Types of Codecs

The Zarr v3 specification categorizes codecs based on the type of data they operate on and produce:

1.  **Array-to-Array (A->A) Codecs:** These codecs transform an array chunk *before* it is serialized into bytes. They operate on an in-memory array representation and produce another in-memory array representation. Examples could include codecs that transpose data within a chunk, change the data type (e.g., `float32` to `float16`), or apply operations that make an array more amenable to compression.

2.  **Array-to-Bytes (A->B) Codecs:** This type of codec handles the crucial step of converting an in-memory array chunk into a sequence of bytes. This typically involves flattening the multidimensional array data and handling endianness conversions if necessary. Every codec pipeline must include at least one `A->B` codec.

3.  **Bytes-to-Bytes (B->B) Codecs:** These codecs take a sequence of bytes as input and produce a sequence of bytes as output. This is the category where most common compression algorithms (like `blosc`, `zstd`, `gzip`) and byte-level filters (like `shuffle` for improving compressibility, or checksums) reside. Multiple `B->B` codecs can be chained together.

## Codecs in `zarrs`

The `zarrs` library mirrors these conceptual types using a set of Rust **traits**. To implement a custom codec, you must implement the following traits depending on the codec type:

- `A->A`: `CodecTraits` + `ArrayCodecTraits` + `ArrayToArrayCodecTraits`
- `A->B`: `CodecTraits` + `ArrayCodecTraits` + `ArrayToBytesCodecTraits`
- `B->B`: `CodecTraits` + `BytesToBytesCodecTraits`

The traits are:

- `CodecTraits`: Defines the codec `configuration` creation method, the unique `zarrs` codec `identifier`, and some hints related to partial decoding.
- `ArrayCodecTraits`: defines the `recommended_concurrency` and `partial_decode_granularity`.
- `ArrayToArrayCodecTraits` / `ArrayToBytesCodecTraits` / `BytesToBytesCodecTraits`: Defines the codec `encode` and `decode` methods (including partial encoding and decoding), as well as methods for querying the encoded representation.

These traits define the necessary `encode` and `decode` methods (complete and partial), methods for inspecting the encoded chunk representation, hints for concurrent processing, and more.

The best way to learn to implement a new codec is to look at the existing codecs implemented in `zarrs`.

## Example: An `LZ4` Bytes-to-Bytes Codec

`LZ4` is common lossless compression algorithm.
Let's implement the `numcodecs.lz4` codec, which is supported by `zarr-python` 3.0.0+ for Zarr V3 data.

### The `Lz4CodecConfiguration` Struct

Looking at the [docs for the `numcodecs` `LZ4` codec](https://numcodecs.readthedocs.io/en/stable/compression/lz4.html), it has a single `"acceleration"` parameter.
The valid range for `"accleration"` is not documented, but the `LZ4` library itself will [clamp the acceleration between 1 and the maximum supported compression level](https://github.com/lz4/lz4/blob/fa1634e2ccd41ac09c087ab65e96bcbbd003fd20/lib/lz4.h#L228-L235).
So, any `i32` can be permitted here and there is no need follow [New Type Idiom](https://doc.rust-lang.org/rust-by-example/generics/new_types.html).

The expected form of the codec in array metadata is:
```json
[
    ...
    {
        "name": "numcodecs.lz4",
        "configuration": {
            "acceleration": 1
        }
    }
    ...
]
```

The configuration can be represented by a simple struct:
```rust
/// `lz4` codec configuration parameters
#[derive(Serialize, Deserialize, Clone, Eq, PartialEq, Debug, Display)]
pub struct Lz4CodecConfiguration {
    pub acceleration: i32
}
```
Note that codec configurations in [`zarrs_metadata`](https://docs.rs/zarrs_metadata/latest/zarrs_metadata/) are versioned so that they can adapt to potential codec specification revisions.

`Lz4CodecConfiguration` is JSON serialisable, so implement the `MetadataConfigurationSerialize` trait:
```rust
impl MetadataConfigurationSerialize for Lz4CodecConfiguration {}
```

This trait requires `Serialize + DeserializeOwned`, and enables any implementing struct to be infallibly converted from a JSON object or anything convertible to a JSON object.
A codec configuration must not be able to hold unrepresentable JSON state, otherwise such a conversion could panic at runtime.

### The `Lz4Codec` Struct

Now create the codec struct.
For encoding, the `acceleration` needs to be known, so this must be a field of the struct:

```rust
pub struct Lz4Codec {
    acceleration: i32
}
```

Next we define two constructors.
These are not officially required for the codec to be used, but it is common practice in `zarrs` to include constructors based on the underlying codec parameters as well as a constructor from configuration.
```rust
impl Lz4Codec {
    #[must_use]
    pub fn new(acceleration: i32) -> Self {
        Self { acceleration }
    }

    #[must_use]
    pub fn new_with_configuration(
        configuration: &Lz4CodecConfiguration,
    ) -> Self {
        Self { acceleration: configuration.acceleration }
    }
}
```

### `CodecTraits`

Now we implement the `CodecTraits`, which are required for every codec.

```rust
/// Unique identifier for the LZ4 codec
pub const LZ4: &str = "example.lz4";

impl CodecTraits for Lz4Codec {
    /// Unique identifier for the codec.
    fn identifier(&self) -> &str {
        LZ4
    }

    /// Create the codec configuration.
    fn configuration_opt(
        &self,
        _name: &str,
        _options: &CodecMetadataOptions,
    ) -> Option<MetadataConfiguration> {
        // The into comes from the auto implementation of From<T: MetadataConfigurationSerialize> for MetadataConfiguration
        Some(Lz4CodecConfiguration::new(self.acceleration).into())
    }

    /// Indicates if the input to a codecs partial decoder should be cached for optimal performance.
    /// If true, a cache may be inserted *before* it in a [`CodecChain`] partial decoder.
    fn partial_decoder_should_cache_input(&self) -> bool {
        false
    }

    /// Indicates if a partial decoder decodes all bytes from its input handle and its output should be cached for optimal performance.
    /// If true, a cache will be inserted at some point *after* it in a [`CodecChain`] partial decoder.
    fn partial_decoder_decodes_all(&self) -> bool {
        true
    }
}
```

A unique identifier is defined for the LZ4 codec, which is chosen as to not conflict with a potential future codec that may be implemented in `zarrs` itself (likely `lz4`).
This is returned by the `identifier()` method.
The identifier is used in codec registration, and enables features such as renaming of codecs for serialisation, and supporting multiple codec aliases.

The `configuration_opt` method creates the codec configuration.
Note that this takes a `name` and `options` which are typically unneeded.
However, there are cases where the configuration may be dependent on the codec `name`, or a runtime option could impact serialisation behaviour.

While the `lz4` codec may actually support partial decoding, this needs to be implemented by the wrapper (and it may not be efficient anyway, depending on the access pattern).
For simplicity in this example, let us indicate that partial decoding is NOT supported and make `partial_decoder_decodes_all()` return `true`.
This ensures that a cache is inserted at the appropriate location in a partial decoder codec chain.

### `BytesToBytesCodecTraits`

The `BytesToBytesCodecTraits` are where the encoding and decoding methods are implemented.

```rust
impl BytesToBytesCodecTraits for BloscCodec {
    /// Return a dynamic version of the codec.
    fn into_dyn(self: Arc<Self>) -> Arc<dyn BytesToBytesCodecTraits> {
        self as Arc<dyn BytesToBytesCodecTraits>
    }

    /// Return the maximum internal concurrency supported for the requested decoded representation.
    fn recommended_concurrency(
        &self,
        _decoded_representation: &BytesRepresentation,
    ) -> Result<RecommendedConcurrency, CodecError> {
        Ok(RecommendedConcurrency::new_maximum(1))
    }

    /// Returns the size of the encoded representation given a size of the decoded representation.
    fn encoded_representation(
        &self,
        decoded_representation: &BytesRepresentation,
    ) -> BytesRepresentation {
        todo!()
    }

    fn encode<'a>(
        &self,
        decoded_value: RawBytes<'a>,
        _options: &CodecOptions,
    ) -> Result<RawBytes<'a>, CodecError> {
        todo!()
    }

    fn decode<'a>(
        &self,
        encoded_value: RawBytes<'a>,
        _decoded_representation: &BytesRepresentation,
        _options: &CodecOptions,
    ) -> Result<RawBytes<'a>, CodecError> {
        todo!()
    }
}
```

In the above example, the encode and decode methods have been left as an exercise to the reader.
A crate like [`lz4`](https://crates.io/crates/lz4) could be used to implement these methods with only a few lines in each method.

The encoded representation of an **array-to-bytes** or **bytes-to-bytes** filter is a [`BytesRepresentation`](https://docs.rs/zarrs/latest/zarrs/array/enum.BytesRepresentation.html), which is either `Fixed`, `Bounded`, or `Unbounded`.
Typically compression codecs like `lz4` have an upper bound on the compressed size (see See [`LZ4_compressBound`](https://github.com/lz4/lz4/blob/fa1634e2ccd41ac09c087ab65e96bcbbd003fd20/lib/lz4.h#L217-L226)), so the `encoded_representation()` should return a `BytesRepresentation::BoundedSize` (unless the proceeding filter outputs an unbounded size).
This has been left as an exercise for the reader.

#### Codec Parallelism
In the above snippet, the `recommended_concurrency` is set to 1.
This indicates to higher level `zarrs` operations that the codec `encode`/`decode` operations will only use one thread and that `zarrs` should use *chunk parallelism* over *codec parallelism*.
For large chunks, it may be preferable to use *codec parallelism*, and this can be achieved by increasing the recommended concurrency and using multithreading in the `encode`/`decode` methods.
However, the cost of multithreading in external libraries can be expensive, so benchmark this!
For example, the `blosc` codec in `zarrs` activates *codec parallelism* when the chunk size is greater than `4 MB`.

#### Partial Encoding / Decoding
Note that the `[async_]partial_decoder` and `[async_]partial_encoder` methods of `BytesToBytesCodecTraits` are not implemented in the above example, and the default implementations encode/decode the entire chunk.
Partial encoding is not applicable to the `lz4` codec, but it *could* support partial decoding.
The `blosc` codec in `zarrs` is an example of partial decoding.
The input is always fully decoded (and is cached because `partial_decoder_should_cache_input()` returns `true`), but only requested byte ranges are decompressed.

### Codec Registration

`zarrs` uses [`inventory`](https://crates.io/crates/inventory) for compile time registration of codecs.
Registration involves creating a method that is used to check if the identifier is a match, and a function that actually creates the codec from a configuration.

```rust
// Register the codec.
inventory::submit! {
    CodecPlugin::new(LZ4, is_identifier_lz4, create_codec_lz4)
}

fn is_identifier_lz4(identifier: &str) -> bool {
    identifier == LZ4
}

pub(crate) fn create_codec_lz4(metadata: &MetadataV3) -> Result<Codec, PluginCreateError> {
    let configuration: Lz4Codec = metadata
        .to_configuration()
        .map_err(|_| PluginMetadataInvalidError::new(LZ4, "codec", metadata.clone()))?;
    let codec = Arc::new(Lz4Codec::new_with_configuration(&configuration)?);
    Ok(Codec::BytesToBytes(codec))
}
```

### Codec Aliasing

By default, the codec `name` will be the codec `identifier()`, however that may not be desirable (especially with `example.lz4`!).

```rust
assert_eq!(Lz4::new(1).default_name(), "example.lz4");
```

`zarrs` includes a mechanism for setting the serialised `name` of codecs, as well as supported `name` aliases for decoding.
By default, `zarrs` will preserve the alias if an array is rewritten, but this can be changed (see the `zarrs` global config).

If the codec is confirmed to be fully compatible with `numcodecs.lz4`, its default name could be changed with a runtime configuration:

```rust
global_config_mut()
    .codec_aliases_v3_mut()
    .default_names
    .entry(LZ4.into())
    .and_modify(|entry| {
        *entry = "numcodecs.lz4".into();
    });
assert_eq!(Lz4::new(1).default_name(), "numcodecs.lz4");
```
Or the `identifier` could just be changed to `numcodecs.lz4`, for example.

### Ready to Test

At this point, the `lz4` is ready to go and could be tested for compatibility against `numcodecs.lz4` in `zarr-python`.

This codec would be a great candidate for merging into `zarrs` itself.
Using the `lz4` identifier would be recommended in this case and the default name would be set to `numcodecs.lz4` by default.
If `lz4` were ever standardised without a `numcodecs.` prefix, then the default name could be `lz4` but an alias would remain for `numcodecs.lz4`.

## Array-to-Array and Array-to-Bytes Codecs

Implementing an **Array-to-Array** or **Array-to-Bytes** codec is similar, but the `ArrayCodecTraits` and `ArraytoArrayCodecTraits` or `ArrayToBytesCodecTraits` must be implemented too.

### `ArrayCodecTraits`

[`ArrayCodecTraits`](https://docs.rs/zarrs/latest/zarrs/array/codec/trait.ArrayCodecTraits.html) has two methods.

**`recommended_concurrency()`** (Required)

This method differs from that of `BytesToBytesCodecTraits` only in the type of the `decoded_representation` parameter.
It takes a [`ChunkRepresentation`](https://docs.rs/zarrs/latest/zarrs/array/type.ChunkRepresentation.html) which holds a chunk shape, data type, and fill value.

**`partial_decode_granularity()`** (Provided)

Returns the shape of the smallest subset of a chunk that can be efficiently decoded if the chunk were subdivided into a regular grid.
For most codecs, this is just the shape of the chunk.
It is the shape of the "inner chunks" for the sharding codec.
The default implementation just returns the chunk shape.

### `ArrayToArrayCodecTraits`

This trait is similar to `BytesToBytesCodecTraits` except the `encode` and `decode` methods input and return [`ArrayBytes`](https://docs.rs/zarrs/latest/zarrs/array/enum.ArrayBytes.html), which can represent arrays with fixed or variable sized elements.

Key methods beyond `encode` and `decode` are:
- `encoded_data_type()` (required).
  - This is where a codec can put an input data type compatibility check and indicate if the data type changes on encoding.
- `encoded_fill_value()` (provided) Defaults to the input fill value.
- `encoded_shape()` (provided) Defaults to the input shape.
- `decoded_shape()` (provided) Defaults to the input shape.
- `encoded_representation()` (provided) Creates a `ChunkRepresentation` from the output of `encoded_{data_type,fill_value,shape}()`

Default implementations are provided for `[async_]partial_{encoder,decoder}` which encode/decode the entire chunk.

### `ArrayToBytesCodecTraits`

This trait has a required `encoded_representation()` method that returns a a `BytesRepresentation` based on `ChunkRepresentation` parameter.
The `decode()` and `encode()` methods transform between [`ArrayBytes`](https://docs.rs/zarrs/latest/zarrs/array/enum.ArrayBytes.html) and [`RawBytes`](https://docs.rs/zarrs/latest/zarrs/array/type.RawBytes.html).

## Custom Data Type Interaction

The next page deals with custom data types, however it is worth highlighting that third party codecs are expected to handle custom data types internally.

A first party codec may extend `DataTypeExtension` with a new `codec_<CODEC_NAME>` method and a new `DataTypeExtension<CodecName>` trait to enable a codec to be used with custom data types.
Currently `zarrs` has data type extension traits for the `bytes` and `packbits` codecs.
All other codecs are either data type agnostic (e.g. `transpose`, compression codecs, etc.) or operate on a specific set of data types (e.g. `zfp`).

> [!NOTE]
> If the need arises, `DataTypeExtension` may be changed in the future to better support interaction between custom data types and custom codecs.
