# Python Bindings (zarrs-python) 

[![zarrs_python_ver]](https://pypi.org/project/zarrs/) [![zarrs_python_doc]](https://zarrs-python.readthedocs.io/en/latest/) [![zarrs_python_repo]](https://github.com/ilan-gold/zarrs-python)

[zarrs_python_ver]: https://img.shields.io/pypi/v/zarrs
[zarrs_python_doc]: https://img.shields.io/readthedocs/zarrs-python
[zarrs_python_repo]: https://img.shields.io/badge/ilan--gold/zarrs--python-GitHub-blue?logo=github

The [`zarrs-python`](https://github.com/ilan-gold/zarrs-python) Python package exposes a high-performance codec pipeline to the [`zarr`](https://github.com/zarr-developers/zarr-python) reference implementation that uses `zarrs` under the hood.
There is no need to learn a new API and it is supported by downstream libraries like `dask`.

`zarrs-python` implements the `ZarrsCodecPipeline`.
It can be used by the reference zarr Python implementation (v3.0.0+) for improved performance over the default `BatchedCodecPipeline`.

> [!WARNING]
> `zarrs-python` is highly experimental and has [some limitations](https://github.com/ilan-gold/zarrs-python?tab=readme-ov-file#limitations) compared to the reference implementation.

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
