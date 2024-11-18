# Zarr Stores

A Zarr store is a system that can be used to store and retrieve data from a Zarr hierarchy.
For example: a filesystem, HTTP server, FTP server, Amazon S3 bucket, etc.
A store implements a key/value store interface for storing, retrieving, listing, and erasing keys.

The Zarr V3 storage API is detailed [here](https://zarr-specs.readthedocs.io/en/latest/v3/core/v3.0.html#storage) in the Zarr V3 specification.

## The Sync and Async API

Zarr [`Group`](https://docs.rs/zarrs/latest/zarrs/group/struct.Group.html)s and [`Array`](https://docs.rs/zarrs/latest/zarrs/array/struct.Array.html)s are the core components of a Zarr hierarchy.
In `zarrs`, both structures have both a synchronous and asynchronous API.
The applicable API depends on the storage that the group or array is created with.

Async API methods typically have an `async_` prefix.
In subsequent chapters, async API method calls are shown commented out below their sync equivalent.

> [!WARNING]
> The async API is still considered experimental, and it requires the `async` feature.

## Synchronous Stores

### Memory

[![zarrs_storage_repo]](https://github.com/LDeakin/zarrs/tree/main/zarrs_storage) [![zarrs_storage_ver]](https://crates.io/crates/zarrs_storage) [![zarrs_storage_doc]](https://docs.rs/zarrs_storage)

[zarrs_storage_repo]: https://img.shields.io/badge/LDeakin/zarrs/zarrs__storage-GitHub-blue?logo=github
[zarrs_storage_ver]: https://img.shields.io/crates/v/zarrs_storage
[zarrs_storage_doc]: https://docs.rs/zarrs_storage/badge.svg

[`MemoryStore`](https://docs.rs/zarrs_storage/latest/zarrs_storage/store/struct.MemoryStore.html) is a synchronous in-memory store available in the [`zarrs_storage`](https://docs.rs/zarrs_storage/latest/zarrs_storage/) crate (re-exported as `zarrs::storage`).

```rust
use zarrs::storage::ReadableWritableListableStorage;
use zarrs::storage::store::MemoryStore;

let store: ReadableWritableListableStorage = Arc::new(MemoryStore::new());
```

Note that in-memory stores do not persist data, and they are not suited to distributed (i.e. multi-process) usage.

### Filesystem

[![zarrs_filesystem_repo]](https://github.com/LDeakin/zarrs/tree/main/zarrs_filesystem) [![zarrs_filesystem_ver]](https://crates.io/crates/zarrs_filesystem) [![zarrs_filesystem_doc]](https://docs.rs/zarrs_filesystem)

[zarrs_filesystem_repo]: https://img.shields.io/badge/LDeakin/zarrs/zarrs__filesystem-GitHub-blue?logo=github
[zarrs_filesystem_ver]: https://img.shields.io/crates/v/zarrs_filesystem
[zarrs_filesystem_doc]: https://docs.rs/zarrs_filesystem/badge.svg

[`FilesystemStore`](https://docs.rs/zarrs_filesystem/latest/zarrs_filesystem/struct.FilesystemStore.html) is a synchronous filesystem store available in the [`zarrs_filesystem`](https://docs.rs/zarrs_filesystem/latest/zarrs_filesystem/) crate (re-exported as `zarrs::filesystem` with the `filesystem` feature).

```rust
use zarrs::storage::ReadableWritableListableStorage;
use zarrs::filesystem::FilesystemStore;

let base_path = "/";
let store: ReadableWritableListableStorage =
    Arc::new(FilesystemStore::new(base_path));
```

The base path is the root of the filesystem store.
Node paths are relative to the base path.

The filesystem store also has a [`new_with_options`](https://docs.rs/zarrs_filesystem/latest/zarrs_filesystem/struct.FilesystemStore.html#method.new_with_options) constructor.
Currently the only option available for filesystem stores is whether or not to enable direct I/O on Linux.

### HTTP

[![zarrs_http_repo]](https://github.com/LDeakin/zarrs/tree/main/zarrs_http) [![zarrs_http_ver]](https://crates.io/crates/zarrs_http) [![zarrs_http_doc]](https://docs.rs/zarrs_http)

[zarrs_http_repo]: https://img.shields.io/badge/LDeakin/zarrs/zarrs__http-GitHub-blue?logo=github
[zarrs_http_ver]: https://img.shields.io/crates/v/zarrs_http
[zarrs_http_doc]: https://docs.rs/zarrs_http/badge.svg

[`HTTPStore`](https://docs.rs/zarrs_http/latest/zarrs_http/struct.HTTPStore.html) is a read-only synchronous HTTP store available in the [`zarrs_http`](https://docs.rs/zarrs_http/latest/zarrs_http/) crate.

```rust
use zarrs::storage::ReadableStorage;
use zarrs_http::HTTPStore;

let http_store: ReadableStorage = Arc::new(HTTPStore::new("http://...")?);
```

> [!NOTE]
> The HTTP stores provided by `object_store` and `opendal` (see below) provide a more comprehensive feature set.

## Asynchronous Stores

### `object_store`

[![zarrs_object_store_repo]](https://github.com/LDeakin/zarrs/tree/main/zarrs_object_store) [![zarrs_object_store_ver]](https://crates.io/crates/zarrs_object_store) [![zarrs_object_store_doc]](https://docs.rs/zarrs_object_store)

[zarrs_object_store_repo]: https://img.shields.io/badge/LDeakin/zarrs/zarrs__object__store-GitHub-blue?logo=github
[zarrs_object_store_ver]: https://img.shields.io/crates/v/zarrs_object_store
[zarrs_object_store_doc]: https://docs.rs/zarrs_object_store/badge.svg

The [`object_store`](https://crates.io/crates/object_store) crate is an `async` object store library for interacting with object stores.
Supported object stores include:
* [AWS S3](https://aws.amazon.com/s3/)
* [Azure Blob Storage](https://azure.microsoft.com/en-us/services/storage/blobs/)
* [Google Cloud Storage](https://cloud.google.com/storage)
* Local files
* Memory
* [HTTP/WebDAV Storage](https://datatracker.ietf.org/doc/html/rfc2518)
* Custom implementations

[`zarrs_object_store::AsyncObjectStore`](https://docs.rs/zarrs_object_store/latest/zarrs_object_store/struct.AsyncObjectStore.html) wraps [`object_store::ObjectStore`](https://docs.rs/object_store/0.11.0/object_store/trait.ObjectStore.html) stores.

```rust
use zarrs::storage::::AsyncReadableStorage;
use zarrs_object_store::AsyncObjectStore;

let options = object_store::ClientOptions::new().with_allow_http(true);
let store = object_store::http::HttpBuilder::new()
    .with_url("http://...")
    .with_client_options(options)
    .build()?;
let store: AsyncReadableStorage = Arc::new(AsyncObjectStore::new(store));
```

### OpenDAL

[![zarrs_opendal_repo]](https://github.com/LDeakin/zarrs/tree/main/zarrs_opendal) [![zarrs_opendal_ver]](https://crates.io/crates/zarrs_opendal) [![zarrs_opendal_doc]](https://docs.rs/zarrs_opendal)

[zarrs_opendal_repo]: https://img.shields.io/badge/LDeakin/zarrs/zarrs__opendal-GitHub-blue?logo=github
[zarrs_opendal_ver]: https://img.shields.io/crates/v/zarrs_opendal
[zarrs_opendal_doc]: https://docs.rs/zarrs_opendal/badge.svg

The [`opendal`](https://crates.io/crates/opendal) crate offers a unified data access layer, empowering users to seamlessly and efficiently retrieve data from diverse storage services.
It supports a huge range of [services](https://docs.rs/opendal/latest/opendal/services/index.html) and [layers](https://docs.rs/opendal/latest/opendal/layers/index.html) to extend their behaviour.

[`zarrs_object_store::AsyncOpendalStore`](https://docs.rs/zarrs_opendal/latest/zarrs_opendal/struct.AsyncOpendalStore.html) wraps [`opendal::Operator`](https://docs.rs/opendal/0.50.2/opendal/struct.Operator.html).

```rust
use zarrs::storage::::AsyncReadableStorage;
use zarrs_opendal::AsyncOpendalStore;

let builder = opendal::services::Http::default().endpoint("http://...");
let operator = opendal::Operator::new(builder)?.finish();
let store: AsyncReadableStorage =
    Arc::new(AsyncOpendalStore::new(operator));
```

> [!NOTE]
> Some `opendal` stores can also be used in a synchronous context with [`zarrs_object_store::OpendalStore`](https://docs.rs/zarrs_opendal/latest/zarrs_opendal/struct.OpendalStore.html), which wraps [`opendal::BlockingOperator`](https://docs.rs/opendal/0.50.2/opendal/struct.BlockingOperator.html).

### Icechunk

[`icechunk`](https://crates.io/crates/icechunk) is a transactional storage engine for Zarr designed for use on cloud object storage.

```rust
// Create an icechunk store
let storage = Arc::new(icechunk::ObjectStorage::new_in_memory_store(None));
let icechunk_store = icechunk::Store::new_from_storage(storage).await?;
let store =
    Arc::new(zarrs_icechunk::AsyncIcechunkStore::new(icechunk_store));

// Do some array/metadata manipulation with zarrs, then commit a snapshot
let snapshot0 = store.commit("Initial commit").await?;

// Do some more array/metadata manipulation, then commit another snapshot
let snapshot1 = store.commit("Update data").await?;

// Checkout the first snapshot
store.checkout(icechunk::zarr::VersionInfo::SnapshotId(snapshot0)).await?;
```

## Storage Adapters

Storage adapters can be layered on top of stores to change their functionality.

The below storage adapters are all available in the `zarrs::storage` submodule (via the [`zarrs_storage`](https://docs.rs/zarrs_storage) crate).

### Async to Sync

Asynchronous stores can be used in a synchronous context with the [`AsyncToSyncStorageAdapter`](https://docs.rs/zarrs_storage/0.2.2/zarrs_storage/storage_adapter/async_to_sync/struct.AsyncToSyncStorageAdapter.html).

The `AsyncToSyncBlockOn` trait must be implemented for a runtime or runtime handle in order to block on futures.
See the below `tokio` example:
```rust
use zarrs::storage::storage_adapter::async_to_sync::AsyncToSyncBlockOn;

struct TokioBlockOn(tokio::runtime::Runtime); // or handle

impl AsyncToSyncBlockOn for TokioBlockOn {
    fn block_on<F: core::future::Future>(&self, future: F) -> F::Output {
        self.0.block_on(future)
    }
}
```

```rust
use zarrs::storage::::{AsyncReadableStorage, ReadableStorage};

// Create an async store as normal
let builder = opendal::services::Http::default().endpoint(path);
let operator = opendal::Operator::new(builder)?.finish();
let storage: AsyncReadableStorage =
    Arc::new(AsyncOpendalStore::new(operator));

// Create a tokio runtime and adapt the store to sync
let block_on = TokioBlockOn(tokio::runtime::Runtime::new()?);
let store: ReadableStorage =
    Arc::new(AsyncToSyncStorageAdapter::new(storage, block_on))
```

> [!WARNING]
> Many async stores are not runtime-agnostic (i.e. only support `tokio`).

### Usage Log

The [`UsageLogStorageAdapter`](https://docs.rs/zarrs_storage/0.2.2/zarrs_storage/storage_adapter/usage_log/struct.UsageLogStorageAdapter.html) logs storage method calls.

It is intended to aid in debugging and optimising performance by revealing storage access patterns.

```rust
let store = Arc::new(MemoryStore::new());
let log_writer = Arc::new(Mutex::new(
    // std::io::BufWriter::new(
    std::io::stdout(),
    //    )
));
let store = Arc::new(UsageLogStorageAdapter::new(store, log_writer, || {
    chrono::Utc::now().format("[%T%.3f] ").to_string()
}));
```

### Performance Metrics

The [`PerformanceMetricsStorageAdapter`](https://docs.rs/zarrs_storage/0.2.2/zarrs_storage/storage_adapter/performance_metrics/struct.PerformanceMetricsStorageAdapter.html) accumulates metrics, such as bytes read and written.

It is intended to aid in testing by allowing the application to validate that metrics (e.g., bytes read/written, total read/write operations) match expected values for specific operations.

```rust
let store = Arc::new(MemoryStore::new());
let store = Arc::new(PerformanceMetricsStorageAdapter::new(store));

assert_eq!(store.bytes_read(), ...);
```
