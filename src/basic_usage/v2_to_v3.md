# Converting Zarr V2 to V3

## Changing the Internal Representation
When an array or group is initialised, it internally holds metadata in the Zarr version it was created with.

To change the internal representation, call `to_v3()` on an `Array` or `Group`, then call `store_metadata()` to update the stored metadata.
V2 metadata must be explicitly erased if needed (see below).

### Convert a Group to V3
```rs
let group: Group = group.to_v3();
group.store_metadata()?;
// group.async_store_metadata().await?;
group.erase_metadata_opt(MetadataEraseVersion::V2)?;
// group.async_erase_metadata_opt(MetadataEraseVersion::V2).await?;
```

### Convert an Array to V3
```rs
let array: Array = array.to_v3()?;
array.store_metadata()?;
// array.async_store_metadata().await?;
array.erase_metadata_opt(MetadataEraseVersion::V2)?;
// array.async_erase_metadata_opt(MetadataEraseVersion::V2).await?;
```

Note that `Array::to_v3()` is fallible because some V2 metadata is not V3 compatible.

## Writing Versioned Metadata Explicitly

Rather than changing the internal representation, an alternative is to just write metadata with a specified version.

For groups, the `store_metadata_opt` accepts a [`GroupMetadataOptions`](https://docs.rs/zarrs/latest/zarrs/group/struct.GroupMetadataOptions.html) argument.
`GroupMetadataOptions` currently has only one option that impacts the Zarr version of the metadata.
By default, `GroupMetadataOptions` keeps the current Zarr version.

To convert a Zarr V2 group to Zarr V3:
```rs
group.store_metadata_opt(&
    GroupMetadataOptions::default()
    .with_metadata_convert_version(MetadataConvertVersion::V3)
)?;
// group.store_metadata_opt(...).await?;
```

> [!WARNING]
> `zarrs` does not support converting Zarr V3 metadata to Zarr V2.

Note that the original metadata is not automatically deleted.
If you want to delete it:

```rs
group.erase_metadata()?;
// group.async_erase_metadata().await?;
```

> [!TIP]
> The `store_metadata` methods of `Array` and `Group` internally call [`store_metadata_opt`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.store_metadata_opt).
> Global defaults can be changed, see [zarrs::global::Config](https://docs.rs/zarrs/latest/zarrs/config/struct.Config.html).

[`ArrayMetadataOptions`](https://docs.rs/zarrs/latest/zarrs/array/struct.ArrayMetadataOptions.html) has similar options for changing the Zarr version of the metadata.
It also has various other configuration options, see its documentation.
