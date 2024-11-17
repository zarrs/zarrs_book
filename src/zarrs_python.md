# Python Bindings (zarrs-python)

`zarrs-python` implements the `ZarrsCodecPipeline`.
It can be used by the reference [`zarr`](https://zarr.readthedocs.io/en/main/) Python implementation (v3.0.0+) for improved performance over the default `BatchedCodecPipeline`.

> [!WARNING]
> `zarrs-python` has some limitations compared to the reference implementation.
> See the [limitations](https://github.com/ilan-gold/zarrs-python?tab=readme-ov-file#limitations) in [![zarrs-python](https://img.shields.io/badge/ilan--gold/zarrs--python-GitHub-blue?logo=github)](https://github.com/ilan-gold/zarrs-python).

## Enabling `zarrs-python`

The `ZarrsCodecPipeline` is enabled as follows:

```python
from zarr import config
import zarrs # noqa: F401

config.set({"codec_pipeline.path": "zarrs.ZarrsCodecPipeline"})
```

> [!TIP]
> The `zarrs-python` bindings are located in a repository called `zarrs-python`, but the Python package is called `zarrs`.

Downstream libraries that use `zarr` internally ([`dask`](https://docs.dask.org/en/stable/index.html), [`xarray`](https://docs.xarray.dev/en/stable/), etc.) will also use the `ZarrsCodecPipeline`.

## Performance

This benchmark measures time and peak memory usage to "round trip" a dataset (potentially chunk-by-chunk).
- The disk cache is cleared between each measurement
- These are best of 3 measurements

All datasets are \\(1024x2048x2048\\) `uint16` arrays.

| Name                               | Chunk Shape | Shard Shape | Compression                 | Size   |
|------------------------------------|-------------|-------------|-----------------------------|--------|
| Uncompressed                | \\(256^3\\)     |             | None                        | 8.0 GB |
| Compressed       | \\(256^3\\)     |             | `blosclz` 9 <br> + bitshuffling  | 377 MB |
| Compressed <br> + Sharded | \\(32^3\\)      | \\(256^3\\)     | `blosclz` 9 <br> + bitshuffling  | 1.1 GB |

![benchmark standalone](./zarr_benchmarks/plots/benchmark_roundtrip.svg)

![benchmark dask](./zarr_benchmarks/plots/benchmark_roundtrip_dask.svg)

See [![zarr_benchmarks](https://img.shields.io/badge/LDeakin/zarr__benchmarks-GitHub-blue?logo=github)](https://github.com/LDeakin/zarr_benchmarks) for more details and additional benchmarks.
