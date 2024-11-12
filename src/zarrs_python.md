# Python Bindings (zarrs-python)

`zarrs-python` implements the `ZarrsCodecPipeline`.
This can be used by the reference [`zarr`](https://zarr.readthedocs.io/en/main/) Python implementation (v3.0.0+) for improved performance over the default `BatchedCodecPipeline`.

![benchmark](./zarr_benchmarks/plots/benchmark_roundtrip.svg)

The `ZarrsCodecPipeline` can be enabled as follows:

```python
from zarr import config
import zarrs_python # noqa: F401

config.set({"codec_pipeline.path": "zarrs_python.ZarrsCodecPipeline"})
```

Downstream libraries that use `zarr` internally ([`dask`](https://docs.dask.org/en/stable/index.html), [`xarray`](https://docs.xarray.dev/en/stable/), etc.) will also use the `ZarrsCodecPipeline`.

## Limitations of `zarrs-python`
- It does not support all stores with the same level of configuration as the reference implementation, and
- with some advanced indexing operations, `zarrs-python` falls back to reading entire chunks and indexing in Python.

See the `zarrs-python` documentation for more information about these limitations.
