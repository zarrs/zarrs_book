# Installation

## Prerequisites

The most recent `zarrs` requires [Rust](https://www.rust-lang.org/) version ![msrv](https://img.shields.io/crates/msrv/zarrs?label=) or newer.

You can check your current Rust version by running:
```sh
rustc --version
```
If you don’t have Rust installed, follow the [official Rust installation guide](https://www.rust-lang.org/tools/install).

Some optional `zarrs` codecs require:
- The [CMake](https://cmake.org/) build system.
- The [Clang](https://clang.llvm.org/get_started.html) compiler.

These are typically available through package managers on Linux, Homebrew on Mac, etc.

## Adding `zarrs` to Your Rust Library/Application

`zarrs` is a Rust library.
To use it as a dependency in your Rust project, add it to your `Cargo.toml` file:

```toml
[dependencies]
zarrs = "18.0" # Replace with the latest version
```

The latest version is [![Latest Version](https://img.shields.io/crates/v/zarrs.svg)](https://crates.io/crates/zarrs).
See [crates.io](https://crates.io/crates/zarrs/versions) for a full list of versions.

To use the latest development release:
```toml
[dependencies]
zarrs = { git = "https://github.com/LDeakin/zarrs.git" }
```

The [Cargo reference](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html#specifying-dependencies-from-git-repositories) has more information on `git` repository dependencies.


## Crate Features

`zarrs` has a number of features for stores, codecs, or APIs, many of which are enabled by default.
The below example demonstrates how to disable default features and explicitly enable required features:

```toml
[dependencies.zarrs]
version = "18.0"
default-features = false
features = ["filesystem", "blosc"]
```

See [zarrs (docs.rs) - Crate Features](https://docs.rs/zarrs/latest/zarrs/index.html#crate-features) for an up-to-date list of all available features.

## Supplementary Crates
Some `zarrs` functionality (e.g. additional stores, bindings, etc.) are in separate crates.
The next section details the `zarrs` crate ecosystem.
