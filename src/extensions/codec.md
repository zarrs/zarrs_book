# Codec Extensions

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

- `CodecTraits`: Defines the codec `configuration` creation method, the unique `zarrs` codec `identifier`, and capabilities related to partial decoding/encoding.
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
# extern crate serde;
# extern crate derive_more;
/// `lz4` codec configuration parameters
#[derive(serde::Serialize, serde::Deserialize, Clone, Eq, PartialEq, Debug, derive_more::Display)]
#[display("{}", serde_json::to_string(self).unwrap_or_default())]
pub struct Lz4CodecConfiguration {
    pub acceleration: i32
}
```
Note that codec configurations in [`zarrs_metadata`](https://docs.rs/zarrs_metadata/latest/zarrs_metadata/) are versioned so that they can adapt to potential codec specification revisions.

### The `Lz4Codec` Struct

Now create the codec struct.
For encoding, the `acceleration` needs to be known, so this must be a field of the struct:

```rust
# #[derive(serde::Serialize, serde::Deserialize, Clone, Eq, PartialEq, Debug, derive_more::Display)]
# #[display("{}", serde_json::to_string(self).unwrap_or_default())]
# pub struct Lz4CodecConfiguration { pub acceleration: i32 }
/// An `lz4` codec implementation.
#[derive(Clone, Debug)]
pub struct Lz4Codec {
    acceleration: i32
}

impl Lz4Codec {
    /// Create a new `lz4` codec.
    #[must_use]
    pub fn new(acceleration: i32) -> Self {
        Self { acceleration }
    }

    /// Create a new `lz4` codec from configuration.
    #[must_use]
    pub fn new_with_configuration(configuration: &Lz4CodecConfiguration) -> Self {
        Self { acceleration: configuration.acceleration }
    }
}
```

### `ExtensionIdentifier` and `ExtensionAliases` Traits

In zarrs 0.23.0, codec identity and aliasing are managed through the `ExtensionIdentifier` and `ExtensionAliases<V>` traits.
The `impl_extension_aliases!` macro from `zarrs_plugin` (`zarrs::plugin`) provides a convenient way to implement these traits:

```rust
# extern crate zarrs;
# pub struct Lz4Codec { acceleration: i32 }
zarrs_plugin::impl_extension_aliases!(Lz4Codec, v3: "example.lz4");
```

This macro generates implementations for both `ExtensionIdentifier` (providing the `IDENTIFIER` constant) and `ExtensionAliases` for Zarr V2 and V3.
The generated `ExtensionIdentifier::IDENTIFIER` constant can be used throughout your codec implementation.

For more complex aliasing needs (e.g., different aliases for V2 vs V3, or regex patterns), the macro supports additional forms:
```rust,ignore
// V3 aliases only
zarrs_plugin::impl_extension_aliases!(Lz4Codec, v3: "example.lz4", ["numcodecs.lz4"]);

// V2 and V3 aliases
zarrs_plugin::impl_extension_aliases!(Lz4Codec, "example.lz4",
    v3: "example.lz4", ["numcodecs.lz4"],
    v2: "example.lz4", ["lz4"]
);
```

### `CodecTraits`

Now we implement the `CodecTraits`, which are required for every codec.

```rust,ignore
use std::any::Any;
use zarrs::array::codec::{
    CodecTraits, CodecMetadataOptions, PartialDecoderCapability, PartialEncoderCapability
};
use zarrs::metadata::Configuration;
use zarrs_plugin::{ExtensionIdentifier, ZarrVersion};

impl CodecTraits for Lz4Codec {
    /// Returns self as `Any` for downcasting.
    fn as_any(&self) -> &dyn Any {
        self
    }

    /// Create the codec configuration.
    fn configuration(
        &self,
        _version: ZarrVersion,
        _options: &CodecMetadataOptions,
    ) -> Option<Configuration> {
        Some(Lz4CodecConfiguration { acceleration: self.acceleration }.into())
    }

    /// Returns the partial decoder capability of the codec.
    fn partial_decoder_capability(&self) -> PartialDecoderCapability {
        PartialDecoderCapability {
            partial_read: false,
            partial_decode: false,
        }
    }

    /// Returns the partial encoder capability of the codec.
    fn partial_encoder_capability(&self) -> PartialEncoderCapability {
        PartialEncoderCapability {
            partial_encode: false,
        }
    }
}
```

The `as_any()` method is required for downcasting the codec to its concrete type.

The `configuration` method creates the codec configuration.
It takes a `version` and `options` parameter that can impact serialisation behaviour.

The `partial_decoder_capability` and `partial_encoder_capability` methods indicate the codec's support for partial operations.
Since the `lz4` codec does not support partial decoding or encoding, both capabilities are set to `false`.

### `BytesToBytesCodecTraits`

The `BytesToBytesCodecTraits` are where the encoding and decoding methods are implemented.

```rust,ignore
use std::borrow::Cow;
use std::sync::Arc;
use zarrs::array::{ArrayBytesRaw, BytesRepresentation};
use zarrs::array::codec::{
    BytesToBytesCodecTraits, CodecError, CodecOptions, RecommendedConcurrency
};

impl BytesToBytesCodecTraits for Lz4Codec {
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
        // LZ4 has an upper bound on compressed size
        // See: https://github.com/lz4/lz4/blob/dev/lib/lz4.h#L217-L226
        todo!("Calculate LZ4_compressBound")
    }

    fn encode<'a>(
        &self,
        decoded_value: ArrayBytesRaw<'a>,
        _options: &CodecOptions,
    ) -> Result<ArrayBytesRaw<'a>, CodecError> {
        // Use the lz4 crate to compress decoded_value
        todo!("Implement LZ4 compression")
    }

    fn decode<'a>(
        &self,
        encoded_value: ArrayBytesRaw<'a>,
        _decoded_representation: &BytesRepresentation,
        _options: &CodecOptions,
    ) -> Result<ArrayBytesRaw<'a>, CodecError> {
        // Use the lz4 crate to decompress encoded_value
        todo!("Implement LZ4 decompression")
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
The input is always fully decoded (and is cached), but only requested byte ranges are decompressed.

### Codec Registration

`zarrs` uses [`inventory`](https://crates.io/crates/inventory) for compile time registration of codecs.
Registration involves implementing `CodecTraitsV3` and submitting a `CodecPluginV3`.

```rust,ignore
use std::sync::Arc;
use zarrs::array::{Codec, CodecPluginV3, CodecTraitsV3};
use zarrs::metadata::v3::MetadataV3;
use zarrs_plugin::{ExtensionIdentifier, PluginCreateError, PluginMetadataInvalidError};

impl CodecTraitsV3 for Lz4Codec {
    fn create(metadata: &MetadataV3) -> Result<Codec, PluginCreateError> {
        let configuration: Lz4CodecConfiguration = metadata
            .to_configuration()
            .map_err(|_| PluginMetadataInvalidError::new(
                Lz4Codec::IDENTIFIER, "codec", metadata.to_string()
            ))?;
        let codec = Arc::new(Lz4Codec::new_with_configuration(&configuration));
        Ok(Codec::BytesToBytes(codec))
    }
}

// Register the codec.
inventory::submit! {
    CodecPluginV3::new::<Lz4Codec>()
}
```

The `matches_name` function is automatically provided by the `impl_extension_aliases!` macro.

zarrs 0.23.0 also supports runtime extension registration, allowing extensions to be registered dynamically rather than only at compile time.

### Ready to Test

At this point, the `lz4` is ready to go and could be tested for compatibility against `numcodecs.lz4` in `zarr-python`.

This codec would be a great candidate for merging into `zarrs` itself.
Using the `lz4` identifier would be recommended in this case, with `numcodecs.lz4` as an alias.
If `lz4` were ever standardised without a `numcodecs.` prefix, then the identifier could be `lz4` but an alias would remain for `numcodecs.lz4`.

## Array-to-Array and Array-to-Bytes Codecs

Implementing an **Array-to-Array** or **Array-to-Bytes** codec is similar, but the `ArrayCodecTraits` and `ArrayToArrayCodecTraits` or `ArrayToBytesCodecTraits` must be implemented too.

### `ArrayCodecTraits`

[`ArrayCodecTraits`](https://docs.rs/zarrs_codec/latest/zarrs_codec/trait.ArrayCodecTraits.html) has two methods.

**`recommended_concurrency(shape, data_type)`** (Required)

This method differs from that of `BytesToBytesCodecTraits` in that it takes a chunk `shape` and `data_type` instead of a `BytesRepresentation`.

**`partial_decode_granularity(shape)`** (Provided)

Returns the shape of the smallest subset of a chunk that can be efficiently decoded if the chunk were subdivided into a regular grid.
For most codecs, this is just the shape of the chunk.
It is the shape of the "inner chunks" for the sharding codec.
The default implementation just returns the chunk shape.

### `ArrayToArrayCodecTraits`

This trait is similar to `BytesToBytesCodecTraits` except the `encode` and `decode` methods input and return [`ArrayBytes`](https://docs.rs/zarrs/latest/zarrs/array/enum.ArrayBytes.html), which can represent arrays with fixed or variable sized elements.

Key methods beyond `encode` and `decode` are:
- `encoded_data_type(decoded_data_type)` (required) - validates input data type compatibility and returns the encoded data type.
- `encoded_fill_value(decoded_data_type, decoded_fill_value)` (provided) - computes the encoded fill value. Defaults to encoding a single element.
- `encoded_shape(decoded_shape)` (provided) - returns the encoded shape. Defaults to the input shape.
- `decoded_shape(encoded_shape)` (provided) - returns the decoded shape. Defaults to the input shape.
- `encoded_representation(shape, data_type, fill_value)` (provided) - creates an encoded representation from the above methods.

Default implementations are provided for `[async_]partial_{encoder,decoder}` which encode/decode the entire chunk.

### `ArrayToBytesCodecTraits`

This trait has a required `encoded_representation(shape, data_type, fill_value)` method that returns a `BytesRepresentation`.
The `encode()` and `decode()` methods transform between [`ArrayBytes`](https://docs.rs/zarrs/latest/zarrs/array/enum.ArrayBytes.html) and [`ArrayBytesRaw`](https://docs.rs/zarrs/latest/zarrs/array/type.ArrayBytesRaw.html), taking shape, data type, and fill value parameters.

## Custom Data Type Interaction

The previous page deals with custom data types, however it is worth highlighting that third party codecs are expected to handle custom data types internally.

Some first party codecs define codec-specific data type traits to enable compatibility with custom data types.
See the [`zarrs_data_type::codec_traits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/index.html) module for the available codec data type traits:
- `BytesDataTypeTraits` - for the `bytes` codec
- `PackBitsDataTypeTraits` - for the `packbits` codec
- `BitroundDataTypeTraits` - for the `bitround` codec
- `FixedScaleOffsetDataTypeTraits` - for the `fixedscaleoffset` codec
- `PcodecDataTypeTraits` - for the `pcodec` codec
- `ZfpDataTypeTraits` - for the `zfp` codec

All other codecs are either data type agnostic (e.g., `transpose`, compression codecs, etc.) or operate on a specific set of data types.

### Creating a Custom Codec Data Type Trait

If you are implementing a codec that requires data type-specific behaviour (e.g., endianness handling, bit manipulation), you can create a custom codec data type trait.
This allows custom data types to register support for your codec.

The process involves three components:

1. **Define the trait** - Create a trait that defines the data type-specific operations your codec needs
2. **Generate support infrastructure** - Use the `define_data_type_support!` macro to create the plugin and extension trait
3. **Provide a registration macro** - Create a convenience macro for data types to implement and register support (if appropriate)

Here's an example of how the `bytes` codec data type trait is structured:

```rust,ignore
use std::borrow::Cow;
use zarrs_metadata::Endianness;

/// Error type for the codec.
#[derive(Debug, Clone, Copy, thiserror::Error)]
#[error("endianness must be specified for multi-byte data types")]
pub struct BytesCodecEndiannessMissingError;

/// The codec data type trait.
pub trait BytesDataTypeTraits {
    /// Encode the bytes to a specified endianness.
    fn encode<'a>(
        &self,
        bytes: Cow<'a, [u8]>,
        endianness: Option<Endianness>,
    ) -> Result<Cow<'a, [u8]>, BytesCodecEndiannessMissingError>;

    /// Decode the bytes from a specified endianness.
    fn decode<'a>(
        &self,
        bytes: Cow<'a, [u8]>,
        endianness: Option<Endianness>,
    ) -> Result<Cow<'a, [u8]>, BytesCodecEndiannessMissingError>;
}

// Generate the plugin and extension trait infrastructure
zarrs_data_type::define_data_type_support!(Bytes);
```

The `define_data_type_support!(Bytes)` macro generates:
- `BytesDataTypePlugin` - A struct for `inventory` registration
- `BytesDataTypeExt` - An extension trait on `DataType` with a `codec_bytes()` method

The codec can then use the extension trait to access the data type's implementation:

```rust,ignore
// In the codec's encode method:
let bytes_encoded = data_type.codec_bytes()?.encode(bytes, self.endian)?;

// In the codec's decode method:
let bytes_decoded = data_type.codec_bytes()?.decode(bytes, self.endian)?;
```

Data types register support using the `register_data_type_extension_codec!` macro:

```rust,ignore
impl BytesDataTypeTraits for MyDataType {
    fn encode<'a>(
        &self,
        bytes: Cow<'a, [u8]>,
        endianness: Option<Endianness>,
    ) -> Result<Cow<'a, [u8]>, BytesCodecEndiannessMissingError> {
        // Implementation...
    }

    fn decode<'a>(
        &self,
        bytes: Cow<'a, [u8]>,
        endianness: Option<Endianness>,
    ) -> Result<Cow<'a, [u8]>, BytesCodecEndiannessMissingError> {
        // Implementation...
    }
}

zarrs_data_type::register_data_type_extension_codec!(
    MyDataType,
    BytesDataTypePlugin,
    BytesDataTypeTraits
);
```

First party codecs typically provide convenience macros (e.g., `impl_bytes_data_type_traits!`) that implement the trait and register support in one step.
