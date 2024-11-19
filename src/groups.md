# Zarr Groups

A group is a node in a Zarr hierarchy that may have child nodes (arrays or groups).

![zarr overview](https://zarr-specs.readthedocs.io/en/latest/_images/terminology-hierarchy.excalidraw.png)

Each array or group in a hierarchy is represented by a metadata document, which is a machine-readable document containing essential processing information about the node.
For a group, the metadata document contains the Zarr Version and optional user attributes.

## 

## Opening an Existing Group

An existing group can be opened with [`Group::open`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.open) (or [`async_open`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.async_open)):
```rs
let group = Group::open(store.clone(), "/group")?;
// let group = Group::async_open(store.clone(), "/group").await?;
```

> [!NOTE]
> These methods will open a Zarr V2 or Zarr V3 group.
> If you only want to open a specific Zarr version, see [`open_opt`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.open_opt) and [`MetadataRetrieveVersion`](https://docs.rs/zarrs/latest/zarrs/config/enum.MetadataRetrieveVersion.html).

## Creating Attributes
Attributes are encoded in a JSON object (`serde_json::Object`).

Here are a few different approaches for constructing a JSON object:
```rs
let value = serde_json::json!({
    "spam": "ham",
    "eggs": 42
});
```
```rs
let attributes: serde_json::Object =
    serde_json::json!(value).as_object().unwrap().clone()
```

```rs
let serde_json::Value::Object(attributes) = value else { unreachable!() };
```

```rs
let mut attributes =  serde_json::Object::default();
attributes.insert("spam".to_string(), Value::String("ham".to_string()));
attributes.insert("eggs".to_string(), Value::Number(42.into()));
```

Alternatively, you can encode your attributes in a struct deriving `Serialize`, and serialize to a `serde_json::Object`.

## Creating a Group with the `GroupBuilder`

> [!NOTE]
> The `GroupBuilder` only supports Zarr V3 groups.

```rs
let group = zarrs::group::GroupBuilder::new()
    .attributes(attributes)
    .build(store.clone(), "/group")?;
group.store_metadata()?;
// group.async_store_metadata().await?;
```

Note that the `/group` path is relative to the root of the store.

## Remember to Store Metadata!
Group metadata must **always** be stored explicitly, even if the attributes are empty.
Support for implicit groups without metadata [was removed long after provisional acceptance of the Zarr V3 specification](https://github.com/zarr-developers/zarr-specs/pull/292/).

> [!TIP]
> Consider deferring storage of group metadata until child group/array operations are complete.
> The presence of valid metadata can act as a signal that the data is ready.


## Creating a Group from `GroupMetadata`

### Zarr V3
```rs
/// Specify the group metadata
let metadata: GroupMetadata =
    GroupMetadataV3::new().with_attributes(attributes).into();

/// Create the group and write the metadata
let group =
    Group::new_with_metadata(store.clone(), "/group", metadata)?;
group.store_metadata()?;
// group.async_store_metadata().await?;
```

```rs
/// Specify the group metadata
let metadata: GroupMetadataV3 = serde_json::from_str(
    r#"{
    "zarr_format": 3,
    "node_type": "group",
    "attributes": {
        "spam": "ham",
        "eggs": 42
    },
    "unknown": {
        "must_understand": false
    }
}"#,
)?;

/// Create the group and write the metadata
let group =
    Group::new_with_metadata(store.clone(), "/group", metadata.into())?;
group.store_metadata()?;
// group.async_store_metadata().await?;
```

### Zarr V2

```rs
/// Specify the group metadata
let metadata: GroupMetadata =
    GroupMetadataV2::new().with_attributes(attributes).into();

/// Create the group and write the metadata
let group = Group::new_with_metadata(store.clone(), "/group", metadata)?;
group.store_metadata()?;
// group.async_store_metadata().await?;
```

## Mutating Group Metadata

Group attributes can be changed after initialisation with [`Group::attributes_mut`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html#method.attributes_mut):
```rust
group
    .attributes_mut()
    .insert("foo".into(), serde_json::Value::String("bar".into()));
group.store_metadata()?;
```

Don't forget to store the updated metadata after attributes have been mutated.
