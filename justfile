serve:
    mdbook serve

install:
    cargo binstall mdbook

crate_diagram:
    d2 src/crates.d2 src/crates.svg
