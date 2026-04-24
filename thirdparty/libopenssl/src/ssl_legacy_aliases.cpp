// ssl_legacy_aliases.cpp
// Provides backward-compatible link-time symbols for OpenSSL 1.x names that
// were removed in OpenSSL 3.x.  This file is compiled into libopenssl_stubs
// so that any component linking that library (e.g. dbpostgresql, which bundles
// a libpq built against OpenSSL 1.x) can resolve the old names at link time.
//
// At runtime each alias calls the corresponding new-name stub that is already
// present in ssl.*.stubs.cpp, which lazily loads the real symbol from
// revsecurity at first call.  No new DLL symbol resolution is needed here.

extern "C"
{

// ── SSL_get_peer_certificate (removed in OpenSSL 3.0) ────────────────────────
// Old name: SSL_get_peer_certificate  – returned X509 *, ref-count incremented
// New name: SSL_get1_peer_certificate – identical semantics
// Declared as void* to avoid pulling in OpenSSL headers.
void *SSL_get1_peer_certificate(void *ssl);

void *SSL_get_peer_certificate(void *ssl)
{
    return SSL_get1_peer_certificate(ssl);
}

} // extern "C"
