# Initialising a Group

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

```rs
let group = zarrs::group::GroupBuilder::new()
    .attributes(attributes)
    .build(store.clone(), "/group")?;
group.store_metadata()?;
```

Note that the `/group` path is relative to the root of the store.

> [!NOTE]
> The `GroupBuilder` only supports Zarr V3 groups.

## Creating a Group from `GroupMetadata`

### Zarr V3
```rs
let metadata: GroupMetadata =
    GroupMetadataV3::new().with_attributes(attributes).into();
let group =
    Group::new_with_metadata(store.clone(), "/group", metadata)?;
group.store_metadata()?;
```

```rs
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
let group =
    Group::new_with_metadata(store.clone(), "/group", metadata.into())?;
group.store_metadata()?;
```

### Zarr V2

```rs
let metadata: GroupMetadata =
    GroupMetadataV2::new().with_attributes(attributes).into();
let group = Group::new_with_metadata(store.clone(), "/group", metadata)?;
group.store_metadata()?;
```

## Remember to Store Metadata!
`store_metadata` is explicitly called immediately after creating the group in all of the examples above.

> [!WARNING]
> Group metadata must **always** be stored explicitly, even if the attributes are empty.

Group metadata must be stored because support for implicit groups (without metadata) [was removed long after provisional acceptance of the Zarr V3 specification](https://github.com/zarr-developers/zarr-specs/pull/292/).

> [!TIP]
> Consider deferring storage of group metadata until child group/array operations are complete.
> Ths presence of valid metadata can act as a signal that the data is ready.
