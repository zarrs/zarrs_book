serve:
    mdbook serve

install:
    cargo binstall mdbook mdbook-alerts mdbook-mermaid mdbook-pagetoc

crate_diagram:
    d2 src/crates.d2 src/crates.svg
