# Converting Zarr V2 to V3

## CLI tool

`zarrs_reencode` is a CLI tool that supports Zarr V2 to V3 conversion. See the [zarrs_reencode](./zarrs_tools/docs/zarrs_reencode.md) section.

## Changing the Internal Representation
When an array or group is initialised, it internally holds metadata in the Zarr version it was created with.

To change the internal representation to Zarr V3, call `to_v3()` on an `Array` or `Group`, then call `store_metadata()` to update the stored metadata.
V2 metadata must be explicitly erased if needed (see below).

> [!NOTE]
> While `zarrs` fully supports manipulation of Zarr V2 and V3 hierarchies (with supported codecs, data types, etc.), it only supports **forward conversion** of metadata from Zarr V2 to V3.

### Convert a Group to V3
```rust
# extern crate zarrs;
# use zarrs::group::Group;
# use zarrs::metadata::{GroupMetadata, v3::GroupMetadataV3};
# use zarrs::config::MetadataEraseVersion;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let group = Group::new_with_metadata(store, "/group", GroupMetadataV3::new().into())?;
let group = group.to_v3();
group.store_metadata()?;
// group.async_store_metadata().await?;
group.erase_metadata_opt(MetadataEraseVersion::V2)?;
// group.async_erase_metadata_opt(MetadataEraseVersion::V2).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

### Convert an Array to V3
```rust
# extern crate zarrs;
# use zarrs::array::{Array, ArrayBuilder, data_type};
# use zarrs::config::MetadataEraseVersion;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let array = ArrayBuilder::new(
#     vec![8, 8], // array shape
#     vec![4, 4], // regular chunk shape
#     data_type::float32(),
#     f32::NAN,
# ).build(store.clone(), "/array")?;
let array = array.to_v3()?;
array.store_metadata()?;
// array.async_store_metadata().await?;
array.erase_metadata_opt(MetadataEraseVersion::V2)?;
// array.async_erase_metadata_opt(MetadataEraseVersion::V2).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

Note that `Array::to_v3()` is fallible because some V2 metadata is not V3 compatible.

## Writing Versioned Metadata Explicitly

Rather than changing the internal representation, an alternative is to just write metadata with a specified version.

For groups, the `store_metadata_opt` accepts a [`GroupMetadataOptions`](https://docs.rs/zarrs/latest/zarrs/group/struct.GroupMetadataOptions.html) argument.
`GroupMetadataOptions` currently has only one option that impacts the Zarr version of the metadata.
By default, `GroupMetadataOptions` keeps the current Zarr version.

To write Zarr V3 metadata:
```rust
# extern crate zarrs;
# use zarrs::group::{Group, GroupMetadataOptions};
# use zarrs::metadata::{GroupMetadata, v3::GroupMetadataV3};
# use zarrs::config::MetadataConvertVersion;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let group = Group::new_with_metadata(store, "/group", GroupMetadataV3::new().into())?;
group.store_metadata_opt(&
    GroupMetadataOptions::default()
    .with_metadata_convert_version(MetadataConvertVersion::V3)
)?;
// group.async_store_metadata_opt(...).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!WARNING]
> `zarrs` does not support converting Zarr V3 metadata to Zarr V2.

Note that the original metadata is not automatically deleted.
If you want to delete it:

```rust
# extern crate zarrs;
# use zarrs::group::Group;
# use zarrs::metadata::v3::GroupMetadataV3;
# use zarrs::config::MetadataEraseVersion;
# let store = std::sync::Arc::new(zarrs::storage::store::MemoryStore::new());
# let group = Group::new_with_metadata(store, "/group", GroupMetadataV3::new().into())?;
group.erase_metadata_opt(MetadataEraseVersion::V2)?;
// group.async_erase_metadata_opt(MetadataEraseVersion::V2).await?;
# Ok::<_, Box<dyn std::error::Error>>(())
```

> [!TIP]
> The `store_metadata` methods of `Array` and `Group` internally call [`store_metadata_opt`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.store_metadata_opt).
> Global defaults can be changed, see [zarrs::global::Config](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html).

[`ArrayMetadataOptions`](https://docs.rs/zarrs/latest/zarrs/array/struct.ArrayMetadataOptions.html) has similar options for changing the Zarr version of the metadata.
It also has various other configuration options, see its documentation.
