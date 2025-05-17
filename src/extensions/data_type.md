# Data Type Extensions

According to the Zarr V3 specification:
> A data type defines the set of possible values that an array may contain.
> For example, the 32-bit signed integer data type defines binary representations for all integers in the range −2,147,483,648 to 2,147,483,647.

The specification defines a limited set of data types, but additional data types can be defined as extensions.

`zarrs` supports a number of extension data types, many of which are registered in the [`zarr-extensions`] repository.
This chapter explains how to create custom data types with a guided walkthrough.

## Example: The `uint4` Data type

The `uint4` data type is registered at the [`zarr-extensions`] repository.
The specification can be read here:
- <https://github.com/zarr-developers/zarr-extensions/tree/main/data-types/uint4>

In summary, it defines a 4-bit unsigned integer in the range `[0, 15]` that is supported by the `bytes` and `packbits` codecs.

### The `DataTypeUint4` Struct

The `uint4` data type has no configuration, so it can be represented by a unit struct:
```rust
/// The `uint4` data type.
#[derive(Debug)]
struct DataTypeUint4;
```

### Implementing `DataTypeExtension`

To be used as a data type extension, `DataTypeUint4` must implement the `DataTypeExtension` trait.
The `DataTypeUint4Element` used in these definitions is defined later on this page.
This defines properties of the data type such as the metadata (name and configuration), size, and conversion between to and from fill values and fill value metadata.
It has additional codec related methods detailed shortly.

```rust
/// A unique identifier for `uint4` data type.
const UINT4: &'static str = "uint4";

impl DataTypeExtension for DataTypeUint4 {
    fn name(&self) -> String {
        UINT4.to_string()
    }

    fn configuration(&self) -> Configuration {
        Configuration::default()
    }

    fn fill_value(
        &self,
        fill_value_metadata: &FillValueMetadataV3,
    ) -> Result<FillValue, DataTypeFillValueMetadataError> {
        let err = || DataTypeFillValueMetadataError::new(self.name(), fill_value_metadata.clone());
        let element_metadata: u64 = fill_value_metadata.as_u64().ok_or_else(err)?;
        let element = DataTypeUint4Element::try_from(element_metadata).map_err(|_| {
            DataTypeFillValueMetadataError::new(UINT4.to_string(), fill_value_metadata.clone())
        })?;
        Ok(FillValue::new(element.to_ne_bytes().to_vec()))
    }

    fn metadata_fill_value(
        &self,
        fill_value: &FillValue,
    ) -> Result<FillValueMetadataV3, DataTypeFillValueError> {
        let element = DataTypeUint4Element::from_ne_bytes(
            fill_value
                .as_ne_bytes()
                .try_into()
                .map_err(|_| DataTypeFillValueError::new(self.name(), fill_value.clone()))?,
        );
        Ok(FillValueMetadataV3::from(element.as_u8()))
    }

    fn size(&self) -> zarrs::array::DataTypeSize {
        DataTypeSize::Fixed(1)
    }
    
    ...
}
```

### Implementing `DataTypeExtensionBytesCodec`

Supporting the `bytes` codec is absolutely trivial for the `uint4` data type.
It simply passes through the in-memory data unmodified, since it is already a 1-byte value.

```rust
impl DataTypeExtensionBytesCodec for DataTypeUint4 {
    fn encode<'a>(
        &self,
        bytes: std::borrow::Cow<'a, [u8]>,
        _endianness: Option<zarrs_metadata::Endianness>,
    ) -> Result<std::borrow::Cow<'a, [u8]>, DataTypeExtensionBytesCodecError> {
        Ok(bytes)
    }

    fn decode<'a>(
        &self,
        bytes: std::borrow::Cow<'a, [u8]>,
        _endianness: Option<zarrs_metadata::Endianness>,
    ) -> Result<std::borrow::Cow<'a, [u8]>, DataTypeExtensionBytesCodecError> {
        Ok(bytes)
    }
}
```

The default implementation of `DataTypeExtension::codec_bytes` must be overriden to return `Ok(self)`:
```rust
impl DataTypeExtension for DataTypeUint4 {
    ...
    
    fn codec_bytes(&self) -> Result<&dyn DataTypeExtensionBytesCodec, DataTypeExtensionError> {
        Ok(self)
    }
}
```

### Implementing `DataTypeExtensionPackBitsCodec`

The `uint4` data type supports the `packbits` codec as a 4-bit value.
This can be supported by implementing the `DataTypeExtensionPackBitsCodec` trait.

```rust
impl DataTypeExtensionPackBitsCodec for DataTypeUint4 {
    fn component_size_bits(&self) -> u64 {
        4
    }

    fn num_components(&self) -> u64 {
        1
    }

    fn sign_extension(&self) -> bool {
        false
    }
}
```
In this case, the trait methods signify that the data type:
- has 1 component,
- a component size of 4 bits, and
- it is unsigned and does not need sign extension.

The default implementation of `DataTypeExtension::codec_packbits` must be overriden to return `Ok(self)`:
```rust
impl DataTypeExtension for DataTypeUint4 {
    ...
    
    fn codec_packbits(
        &self,
    ) -> Result<&dyn DataTypeExtensionPackBitsCodec, DataTypeExtensionError> {
        Ok(self)
    }
}
```

### Registering the `uint4` Data Type
A data type must be registered as a `DataTypePlugin` to be used in an `Array`.

```rust

// Register the data type so that it can be recognised when opening arrays.
inventory::submit! {
    DataTypePlugin::new(UINT4, is_uint4_dtype, create_uint4_dtype)
}

fn is_uint4_dtype(name: &str) -> bool {
    name == UINT4
}

fn create_uint4_dtype(
    metadata: &MetadataV3,
) -> Result<Arc<dyn DataTypeExtension>, PluginCreateError> {
    if metadata.configuration_is_none_or_empty() {
        Ok(Arc::new(DataTypeUint4))
    } else {
        Err(PluginMetadataInvalidError::new(UINT4, "data_type", metadata.to_string()).into())
    }
}
```

### The `DataTypeUint4Element` Struct

The most suitable in-memory representation of a `uint4` data type element is a `u8`.

```rust
/// The in-memory representation of the `uint4` data type.
#[derive(Deserialize, Clone, Copy, Debug, PartialEq)]
struct DataTypeUint4Element(u8);
```

A data type element must implement the `Element` trait to be used in `Array::store_*_as_elements` methods.

```rust
/// This defines how an in-memory DataTypeUint4 is converted into ArrayBytes before encoding via the codec pipeline.
impl Element for DataTypeUint4 {
    fn validate_data_type(data_type: &DataType) -> Result<(), ArrayError> {
        (data_type == &DataType::Extension(Arc::new(DataTypeUint4)))
            .then_some(())
            .ok_or(ArrayError::IncompatibleElementType)
    }

    fn into_array_bytes<'a>(
        data_type: &DataType,
        elements: &'a [Self],
    ) -> Result<zarrs::array::ArrayBytes<'a>, ArrayError> {
        Self::validate_data_type(data_type)?;
        // Maybe this could be a transmute instead &[DataTypeUint4(u8)] -> Cow::Borrowed(&[u8])
        let mut bytes: Vec<u8> =
            Vec::with_capacity(elements.len() * size_of::<DataTypeUint4>());
        for element in elements {
            bytes.push(element.0);
        }
        Ok(ArrayBytes::Fixed(Cow::Owned(bytes)))
    }
}
```

A data type element must implement the `ElementOwned` trait to be used in `Array::retrieve_*_as_elements` methods.

```rust
/// This defines how ArrayBytes are converted into a DataTypeUint4 after decoding via the codec pipeline.
impl ElementOwned for DataTypeUint4 {
    fn from_array_bytes(
        data_type: &DataType,
        bytes: ArrayBytes<'_>,
    ) -> Result<Vec<Self>, ArrayError> {
        Self::validate_data_type(data_type)?;
        let bytes = bytes.into_fixed()?;
        let bytes_len = bytes.len();
        let mut elements = Vec::with_capacity(bytes_len / size_of::<DataTypeUint4>());
        for byte in bytes.iter() {
            // TODO: Should not construct DataTypeUint4 this way as it could represent a
            // value outside of [0, 15]. Set upper bits in the byte to 0?
            elements.push(DataTypeUint4(*byte))
        }
        Ok(elements)
    }
}
```

Some non-essential utility methods were defined for `DataTypeUint4` and used in the snippets above:
```rust
impl DataTypeUint4 {
    fn to_ne_bytes(&self) -> [u8; 1] {
        [self.0]
    }

    fn from_ne_bytes(bytes: &[u8; 1]) -> Self {
        Self(bytes[0])
    }

    fn as_u8(&self) -> u8 {
        self.0
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
With a little bit of polish, the `uint4` example above could be included in `zarrs` itself (if it isn't already)!

[`zarr-extensions`]: https://github.com/zarr-developers/zarr-extensions
