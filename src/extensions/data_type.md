# Data Type Extensions

According to the Zarr V3 specification:
> A data type defines the set of possible values that an array may contain.
> For example, the 32-bit signed integer data type defines binary representations for all integers in the range −2,147,483,648 to 2,147,483,647.

The specification defines a limited set of data types, but additional data types can be defined as extensions.

`zarrs` supports a number of extension data types, many of which are registered in the [`zarr-extensions`] repository.
This chapter explains how to create custom data types with a guided walkthrough.

## Implementing a Custom Data Type

To open/read/write/create a Zarr `Array` with a custom data type, the following traits must be implemented:

### Core Traits

| Trait | Crate | Required | Description |
|-------|-------|----------|-------------|
| [`DataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/trait.DataTypeTraits.html) | `zarrs_data_type` | Yes | Core data type properties (size, fill value handling, etc.) |
| [`DataTypeTraitsV3`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/trait.DataTypeTraitsV3.html) | `zarrs_data_type` | For V3 | Creation from Zarr V3 metadata (for plugin registration) |
| [`DataTypeTraitsV2`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/trait.DataTypeTraitsV2.html) | `zarrs_data_type` | For V2 | Creation from Zarr V2 metadata (for plugin registration) |
| [`ExtensionAliases<ZarrVersion3>`](https://docs.rs/zarrs_plugin/latest/zarrs_plugin/trait.ExtensionAliases.html) | `zarrs_plugin` | For V3 | Defines the extension name and aliases for Zarr V3 metadata |
| [`ExtensionAliases<ZarrVersion2>`](https://docs.rs/zarrs_plugin/latest/zarrs_plugin/trait.ExtensionAliases.html) | `zarrs_plugin` | For V2 | Defines the extension name and aliases for Zarr V2 metadata |

Additionally, the data type must be registered as a [`DataTypePluginV3`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/struct.DataTypePluginV3.html) and/or [`DataTypePluginV2`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/struct.DataTypePluginV2.html) using `inventory`.

### Codec Traits

The following traits enable compatibility with specific codecs.
See the [`zarrs_data_type::codec_traits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/index.html) module for convenience macros.

| Trait | Crate | Required | Description |
|-------|-------|----------|-------------|
| [`BytesDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/bytes/trait.BytesDataTypeTraits.html) | `zarrs_data_type` | For `bytes` codec | Endianness handling for the `bytes` codec |
| [`PackBitsDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/packbits/trait.PackBitsDataTypeTraits.html) | `zarrs_data_type` | For `packbits` codec | Bit packing/unpacking for the `packbits` codec |
| [`BitroundDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/bitround/trait.BitroundDataTypeTraits.html) | `zarrs_data_type` | For `bitround` codec | Bit rounding for floating-point types |
| [`FixedScaleOffsetDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/fixedscaleoffset/trait.FixedScaleOffsetDataTypeTraits.html) | `zarrs_data_type` | For `fixedscaleoffset` codec | Fixed scale/offset encoding |
| [`PcodecDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/pcodec/trait.PcodecDataTypeTraits.html) | `zarrs_data_type` | For `pcodec` codec | Pcodec compression |
| [`ZfpDataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/codec_traits/zfp/trait.ZfpDataTypeTraits.html) | `zarrs_data_type` | For `zfp` codec | ZFP compression for floating-point types |

### Element Traits

These traits are implemented on the *in-memory representation* of the data type (e.g., a newtype wrapper like `UInt10DataTypeElement`), not on the data type struct itself.
Alternatively, existing `Element` implementations for standard numeric types (e.g., `u16`) can be used by setting `compatible_element_types` in `DataTypeTraits`.

| Trait | Crate | Required | Description |
|-------|-------|----------|-------------|
| [`Element`](https://docs.rs/zarrs/latest/zarrs/array/trait.Element.html) | `zarrs` | For `Array` store methods | Conversion from in-memory elements to array bytes |
| [`ElementOwned`](https://docs.rs/zarrs/latest/zarrs/array/trait.ElementOwned.html) | `zarrs` | For `Array` retrieve methods | Conversion from array bytes to in-memory elements |

## Example: The `uint10` Data Type

This example demonstrates how to implement a hypothetical `uint10` data type as a custom extension.
A 10-bit unsigned integer can represent values in the range `[0, 1023]` and can be supported by the `bytes` and `packbits` codecs.

The `uint10` data type has no configuration, so it can be represented by a unit struct:
```rust
/// The `uint10` data type.
#[derive(Debug, Clone, Copy)]
struct UInt10DataType;
```

### Extension Name/Alias Registration

In `zarrs` 0.23.0, extension names and aliases are managed through the `zarrs_plugin::ExtensionAliases<V>` trait.
The [`zarrs_plugin::impl_extension_aliases!`](https://docs.rs/zarrs_plugin/latest/zarrs_plugin/macro.impl_extension_aliases.html) macro provides a convenient way to implement these traits:
At compile time, extensions are registered (via `inventory`) so that can be identified when opening an array and created.
Extensions are registered for usage with Zarr V3 metadata and/or V2 if applicable.
Note that some extensions types (e.g. chunk grids) are not supported all in Zarr V2.

For example:

```rust,ignore
# extern crate inventory;
# extern crate zarrs;
# extern crate zarrs_plugin;
# extern crate zarrs_data_type;
# extern crate zarrs_metadata;
# use std::sync::Arc;
# use zarrs_metadata::v3::MetadataV3;
# #[derive(Debug)]
# struct UInt10DataType;
zarrs_plugin::impl_extension_aliases!(UInt10DataType, v3: "uint10");
inventory::submit! {
    zarrs_data_type::DataTypePluginV3::new::<UInt10DataType>(|_: &MetadataV3| Ok(Arc::new(UInt10DataType).into()))
}
```

### Implementing `DataTypeTraits`

To be used as a data type extension, `UInt10DataType` must implement the [`DataTypeTraits`](https://docs.rs/zarrs_data_type/latest/zarrs_data_type/trait.DataTypeTraits.html) trait (from `zarrs_data_type`).
This defines properties of the data type, such as conversion to/from fill value metadata, size (fixed or variable), and a method to .

```rust
# extern crate zarrs_data_type;
# extern crate zarrs_metadata;
# extern crate zarrs_plugin;
# use std::convert::TryInto;
# use std::sync::Arc;
# use std::any::Any;
use zarrs_data_type::{DataTypeTraits, DataTypeTraitsV3, DataTypeFillValueMetadataError, DataTypeFillValueError, FillValue};
use zarrs_metadata::{Configuration, DataTypeSize, FillValueMetadata, v3::MetadataV3};
use zarrs_plugin::PluginCreateError;

// Define a marker struct for the data type
// A custom data type could also be a struct holding configuration parameters
#[derive(Debug)]
struct UInt10DataType;

// Register the data type
zarrs_plugin::impl_extension_aliases!(UInt10DataType, v3: "uint10");

impl DataTypeTraitsV3 for UInt10DataType {
    fn create(_metadata: &MetadataV3) -> Result<zarrs_data_type::DataType, PluginCreateError> {
        // NOTE: Should validate that metadata is empty / missing
        Ok(Arc::new(UInt10DataType).into())
    }
}

inventory::submit! {
    zarrs_data_type::DataTypePluginV3::new::<UInt10DataType>()
}

impl DataTypeTraits for UInt10DataType {
    fn configuration(&self, _zarr_version: zarrs_plugin::ZarrVersion) -> Configuration {
        Configuration::default()
    }

    fn size(&self) -> DataTypeSize {
        DataTypeSize::Fixed(2)
    }

    fn fill_value(
        &self,
        fill_value_metadata: &FillValueMetadata,
        _version: zarrs_plugin::ZarrVersion,
    ) -> Result<FillValue, DataTypeFillValueMetadataError> {
        let int = fill_value_metadata.as_u64().ok_or(DataTypeFillValueMetadataError)?;
        // uint10 range: 0 to 1023
        if int > 1023 {
            return Err(DataTypeFillValueMetadataError);
        }
        #[expect(clippy::cast_possible_truncation)]
        Ok(FillValue::from(int as u16))
    }

    fn metadata_fill_value(
        &self,
        fill_value: &FillValue,
    ) -> Result<FillValueMetadata, DataTypeFillValueError> {
        let bytes: [u8; 2] = fill_value.as_ne_bytes().try_into().map_err(|_| DataTypeFillValueError)?;
        let number = u16::from_ne_bytes(bytes);
        Ok(FillValueMetadata::from(number))
    }

    fn compatible_element_types(&self) -> &'static [std::any::TypeId] {
        // Declare compatibility with u16 for Element trait implementations
        const TYPES: [std::any::TypeId; 1] = [std::any::TypeId::of::<u16>()];
        &TYPES
    }

    fn as_any(&self) -> &dyn Any {
        self
    }
}
```

### Implementing `BytesDataTypeTraits`

Supporting the `bytes` codec for the `uint10` data type requires handling endianness conversion.
The `impl_bytes_data_type_traits!` macro from `zarrs_data_type` provides a convenient implementation that reverses byte order if necessary (depending on system endianness and the `bytes` codec endianness configuration):

```rust
# extern crate zarrs_data_type;
# extern crate zarrs_plugin;
# #[derive(Debug)]
# struct UInt10DataType;
zarrs_data_type::codec_traits::impl_bytes_data_type_traits!(UInt10DataType, 2);
```

The arguments are:
- Data type struct
- Fixed size in bytes (2 for uint10)

### Implementing `PackBitsDataTypeTraits`

The `uint10` data type supports the `packbits` codec as a 10-bit value.
The `impl_pack_bits_data_type_traits!` macro from `zarrs_data_type` provides a convenient implementation:

```rust
# extern crate zarrs_data_type;
# extern crate zarrs_plugin;
# #[derive(Debug)]
# struct UInt10DataType;
zarrs_data_type::codec_traits::impl_pack_bits_data_type_traits!(UInt10DataType, 10, unsigned, 1);
```

The arguments are:
- Data type struct
- Bits per component (10 for uint10)
- Sign type (`unsigned` or `signed`)
- Number of components (1 for scalar types)

### Using Existing `Element` Implementations

`zarrs` provides `Element` and `ElementOwned` implementations for standard numeric types like `u16`.
To enable these existing implementations for a custom data type, override the `compatible_element_types` method in `DataTypeTraits` to return the compatible Rust types.

For `uint10`, we declared compatibility with `u16` above:
```rust,ignore
fn compatible_element_types(&self) -> &'static [std::any::TypeId] {
    const TYPES: [std::any::TypeId; 1] = [std::any::TypeId::of::<u16>()];
    &TYPES
}
```

This allows using `u16` directly with `Array::store_*` and `Array::retrieve_*` methods without implementing custom `Element` traits.
Note that this does NOT enforce that values are in the valid `uint10` range of `[0, 1023]`, so a custom type is recommended for stricter type safety.

### Custom `Element` Implementations

For custom data types where existing `Element` implementations are not suitable, you can define a newtype wrapper and implement `Element` and `ElementOwned` manually.

For example, here is how `uint10` could be supported as a newtype wrapper around `u16`:

```rust
/// The in-memory representation of the `uint10` data type.
#[derive(Clone, Copy, Debug, PartialEq)]
struct UInt10DataTypeElement(u16);
```

A custom element type must implement the `Element` trait to be used in `Array::store_*` methods with `Vec` or `ndarray` inputs.

```rust,ignore
use zarrs::array::{ArrayBytes, ArrayError, DataType, Element};

impl Element for UInt10DataTypeElement {
    fn validate_data_type(data_type: &DataType) -> Result<(), ArrayError> {
        data_type
            .is::<UInt10DataType>()
            .then_some(())
            .ok_or(ArrayError::IncompatibleElementType)
    }

    fn to_array_bytes<'a>(
        data_type: &DataType,
        elements: &'a [Self],
    ) -> Result<ArrayBytes<'a>, ArrayError> {
        Self::validate_data_type(data_type)?;
        // Validate all elements are in the valid uint10 range
        for element in elements {
            if element.0 > 1023 {
                return Err(ArrayError::InvalidDataValue);
            }
        }
        // Convert to native endian bytes
        let bytes: Vec<u8> = elements
            .iter()
            .flat_map(|e| e.0.to_ne_bytes())
            .collect();
        Ok(ArrayBytes::from(bytes))
    }

    fn into_array_bytes(
        data_type: &DataType,
        elements: Vec<Self>,
    ) -> Result<ArrayBytes<'static>, ArrayError> {
        Self::to_array_bytes(data_type, &elements)
    }
}
```

A custom element type must implement the `ElementOwned` trait to be used in `Array::retrieve_*` methods with `Vec` or `ndarray` outputs.

```rust,ignore
use zarrs::array::{ArrayBytes, ArrayError, DataType, ElementOwned};

impl ElementOwned for UInt10DataTypeElement {
    fn from_array_bytes(
        data_type: &DataType,
        bytes: ArrayBytes<'_>,
    ) -> Result<Vec<Self>, ArrayError> {
        Self::validate_data_type(data_type)?;
        let bytes = bytes.into_fixed()?;
        if bytes.len() % 2 != 0 {
            return Err(ArrayError::InvalidDataValue);
        }
        let elements: Vec<Self> = bytes
            .as_chunks::<2>()
            .0
            .map(|chunk| {
                let value = u16::from_ne_bytes(chunk);
                UInt10DataTypeElement(value)
            })
            .collect();
        for element in &elements {
            if element.0 > 1023 {
                return Err(ArrayError::InvalidDataValue);
            }
        }
        Ok(elements)
    }
}
```

## More Examples
The `zarrs` repository includes multiple custom data type examples:
- [custom_data_type_uint12.rs](https://github.com/zarrs/zarrs/blob/main/zarrs/examples/custom_data_type_uint12.rs)
- [custom_data_type_uint4.rs](https://github.com/zarrs/zarrs/blob/main/zarrs/examples/custom_data_type_uint4.rs)
- [custom_data_type_float8_e3m4.rs](https://github.com/zarrs/zarrs/blob/main/zarrs/examples/custom_data_type_float8_e3m4.rs)
- [custom_data_type_fixed_size.rs](https://github.com/zarrs/zarrs/blob/main/zarrs/examples/custom_data_type_fixed_size.rs)
- [custom_data_type_variable_size.rs](https://github.com/zarrs/zarrs/blob/main/zarrs/examples/custom_data_type_variable_size.rs)

## Contributing New Data Types to `zarrs`

The [`zarr-extensions`] repository is always growing with new Zarr extensions.
The conformance of `zarrs` to [`zarr-extensions`] is tracked in this issue:
- <https://github.com/zarrs/zarrs/issues/191>

Contributions are welcomed to support additional data types.

[`zarr-extensions`]: https://github.com/zarr-developers/zarr-extensions
