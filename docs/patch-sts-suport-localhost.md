# Patch STS Support Localhost - TODO

- [x] Review existing Docker routing and identify current STS host binding (`sts.skoruba.local`).
- [x] Add nginx host port mapping for localhost STS endpoint (`44310:443`) in `docker-compose.yml`.
- [x] Update STS virtual host routing to include `localhost` alongside `sts.skoruba.local`.
- [x] Align STS issuer URI with Angular authority (`https://localhost:44310`).
- [x] Generate and mount TLS certificate/key for `localhost` (`localhost.crt` and `localhost.key`).
- [x] Keep existing `sts.skoruba.local` route intact for backward compatibility.
- [x] Restart Docker Compose stack and verify STS discovery endpoint at `https://localhost:44310/.well-known/openid-configuration`.
- [x] Validate OIDC login flow from Angular without changing Angular authority config.
- [x] Update `docs/Running-Duende-IdentityServer-In-Docker.md` with a "localhost:44310 mode" section.
- [x] Add troubleshooting notes for issuer mismatch and certificate SAN errors.
