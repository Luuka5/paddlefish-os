# Point rustup at the system-wide toolchains baked into the image. CARGO_HOME
# is intentionally left at the default (~/.cargo) so the crate cache lives in
# the per-project home volume.
export RUSTUP_HOME=/usr/local/rustup
