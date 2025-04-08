The Zarr v3 specification defines several explicit **extension points**, which are specific components of the Zarr model that can be replaced or augmented with custom implementations:
- **Codecs**: Codecs define how chunk data is transformed between its in-memory representation and its stored (bytes) representation.
  Zarr allows chaining multiple codecs, creating sophisticated data transformation pipelines.
- **Data types**: The element representation of the array. Array-to-array codecs may change the data type of chunk data on encoding, but this is reversed on decoding.  
- **Chunk Grids**: Define how the N-dimensional array space is partitioned into chunks. The specification only defines a `regular` grid, and a `rectangular` grid is proposed.
- **Chunk Key Encoding**: Specifies how the logical coordinates of a chunk are mapped to the string key used for storage (e.g., `(0, 1, 0)` to `c/0/1/0`, `c.0.1.0`, `/0/1/0`, etc.). The specification defines `default` and `v2` encodings.
- **Storage Transformers**: These modify the interaction between the logical Zarr hierarchy (groups, arrays, chunks) and the underlying storage system. The specification does not define nay storage transformers.
- **Stores** While not strictly an extension point, the ability to interact with different storage backends is a crucial aspect of Zarr's flexibility.
The `zarrs` library, like other Zarr implementations, leverages this by providing its own Storage API for reading, writing, and listing data.
`zarrs` can work with virtually any storage system – in-memory buffers, local filesystems, object stores (like S3 or GCS), databases, etc.
