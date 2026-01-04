serve:
    mdbook serve

test:
    mdbook test # needs https://github.com/rust-lang/mdBook/pull/2503

install:
    cargo binstall mdbook

crate_diagram:
    d2 src/crates.d2 src/crates.svg
