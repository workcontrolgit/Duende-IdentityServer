# Running Duende IdentityServer in Docker Desktop - Complete Setup Guide

This comprehensive guide walks you through setting up Duende IdentityServer with Docker Desktop, including SSL certificate configuration, database seeding, and local domain setup.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Understanding the Docker Setup](#understanding-the-docker-setup)
4. [Step 1: Configure Windows Hosts File](#step-1-configure-windows-hosts-file)
5. [Step 2: Generate SSL Certificates](#step-2-generate-ssl-certificates)
6. [Step 3: Prepare Seed Data](#step-3-prepare-seed-data)
7. [Step 4: Start Docker Containers](#step-4-start-docker-containers)
8. [Step 5: Verify the Setup](#step-5-verify-the-setup)
9. [Accessing the Services](#accessing-the-services)
10. [Troubleshooting](#troubleshooting)
11. [Understanding How It Works](#understanding-how-it-works)
12. [Useful Commands](#useful-commands)

---

## Architecture Overview

The Docker setup consists of 5 containers working together:

```
┌─────────────────────────────────────────────────────────────┐
│                    nginx-proxy (Port 80/443)                 │
│                  Reverse Proxy with SSL                      │
└────────────┬────────────────────────────────┬────────────────┘
             │                                │
    ┌────────▼────────┐              ┌───────▼────────┐
    │ IdentityServer  │              │   Admin UI     │
    │  (STS)          │              │                │
    │ Port: 8080      │              │ Port: 8080     │
    └────────┬────────┘              └───────┬────────┘
             │                                │
             │         ┌──────────────────────┘
             │         │
    ┌────────▼─────────▼────────┐
    │   SQL Server Database     │
    │   Port: 1433 (7900 host)  │
    └───────────────────────────┘
```

**Components:**
- **nginx-proxy**: Routes requests to appropriate containers based on domain names
- **IdentityServer (STS)**: OAuth 2.0/OIDC authentication server
- **Admin UI**: Web interface for managing users, clients, and resources
- **Admin API**: REST API for administrative operations
- **SQL Server**: Database for storing configuration and operational data

---

## Prerequisites

Before you begin, ensure you have:

1. **Docker Desktop for Windows** (latest version)
   - Download: https://www.docker.com/products/docker-desktop

2. **Administrator Access**
   - Required for modifying the hosts file

3. **Text Editor** (VS Code, Notepad++, or similar)

4. **Git Bash or PowerShell** (for running commands)

---

## Understanding the Docker Setup

### Docker Compose Configuration

The setup uses two Docker Compose files:

**`docker-compose.yml`** - Main configuration
- Defines all 5 services (nginx, STS, Admin, Admin API, Database)
- Configures networks and volumes
- Sets up environment variables

**`docker-compose.override.yml`** - Development overrides
- Mounts user secrets for local development
- Can be customized without affecting the main configuration

### Key Files and Folders

```
Duende-IdentityServer/
├── docker-compose.yml              # Main Docker configuration
├── docker-compose.override.yml     # Development overrides
├── shared/                         # Shared configuration files
│   ├── identitydata.json          # User and role seed data
│   ├── identityserverdata.json    # Client and scope seed data
│   ├── serilog.json               # Logging configuration
│   └── nginx/
│       ├── certs/                 # SSL certificates (generated)
│       │   ├── sts.skoruba.local.crt
│       │   ├── sts.skoruba.local.key
│       │   ├── admin.skoruba.local.crt
│       │   ├── admin.skoruba.local.key
│       │   ├── admin-api.skoruba.local.crt
│       │   ├── admin-api.skoruba.local.key
│       │   └── cacerts.crt        # CA bundle
│       └── vhost.d/               # nginx virtual host configs
└── src/
    └── DuendeIdentityServer.Admin/
        ├── identitydata.json      # Source seed file (users)
        └── identityserverdata.json # Source seed file (clients)
```

---

## Step 1: Configure Windows Hosts File

The Docker setup uses custom domain names that need to be resolved locally.

### 1.1 Open Hosts File as Administrator

**Windows 10/11:**

1. Press `Win + X` and select **Windows Terminal (Admin)** or **PowerShell (Admin)**
2. Type: `notepad C:\Windows\System32\drivers\etc\hosts`
3. Click **Yes** to allow administrative access

### 1.2 Add Domain Entries

Add these lines at the end of the hosts file:

```
# Duende IdentityServer Docker Domains
127.0.0.1       sts.skoruba.local
127.0.0.1       admin.skoruba.local
127.0.0.1       admin-api.skoruba.local
```

### 1.3 Save and Verify

1. Save the file (**File → Save**)
2. Close Notepad
3. Verify by pinging one of the domains:

```bash
ping sts.skoruba.local
```

You should see responses from `127.0.0.1`.

**Why This is Needed:**

The nginx-proxy container routes traffic based on domain names (using the `VIRTUAL_HOST` environment variable). By mapping these domains to `127.0.0.1`, your browser sends requests to the local Docker containers instead of trying to resolve them on the internet.

---

## Step 2: Generate SSL Certificates

HTTPS requires SSL certificates for each domain. We'll generate self-signed certificates.

### 2.1 Navigate to Project Directory

Open PowerShell or Git Bash and navigate to:

```bash
cd C:\apps\AngularNetTutotial\TokenService\Duende-IdentityServer
```

### 2.2 Generate Certificates Using Docker

Run this command to generate all three certificates:

```bash
docker run --rm --entrypoint sh -v "${PWD}/shared/nginx/certs:/certs" alpine/openssl -c '
  cd /certs
  for domain in sts.skoruba.local admin.skoruba.local admin-api.skoruba.local; do
    echo "Generating certificate for $domain..."
    openssl genrsa -out "$domain.key" 2048
    openssl req -new -key "$domain.key" -out "$domain.csr" -subj "/C=US/ST=State/L=City/O=Dev/CN=$domain"
    openssl x509 -req -days 365 -in "$domain.csr" -signkey "$domain.key" -out "$domain.crt"
    rm "$domain.csr"
    echo "✓ Created: $domain.crt and $domain.key"
    echo ""
  done
  echo "All certificates generated successfully!"
  ls -lh *.crt *.key
'
```

**What This Does:**
1. Runs an Alpine Linux container with OpenSSL
2. Mounts the `shared/nginx/certs` directory
3. Generates a 2048-bit RSA private key for each domain
4. Creates a certificate signing request (CSR)
5. Self-signs the certificate (valid for 365 days)
6. Cleans up temporary CSR files

### 2.3 Create CA Certificate Bundle

The containers need a CA bundle to trust the self-signed certificates:

```bash
# Windows PowerShell
Get-Content shared\nginx\certs\sts.skoruba.local.crt, shared\nginx\certs\admin.skoruba.local.crt, shared\nginx\certs\admin-api.skoruba.local.crt | Set-Content shared\nginx\certs\cacerts.crt
```

Or using Git Bash:

```bash
cat shared/nginx/certs/sts.skoruba.local.crt \
    shared/nginx/certs/admin.skoruba.local.crt \
    shared/nginx/certs/admin-api.skoruba.local.crt \
    > shared/nginx/certs/cacerts.crt
```

### 2.4 Verify Certificates

```bash
ls -lh shared/nginx/certs/
```

You should see:
- `sts.skoruba.local.crt` and `sts.skoruba.local.key`
- `admin.skoruba.local.crt` and `admin.skoruba.local.key`
- `admin-api.skoruba.local.crt` and `admin-api.skoruba.local.key`
- `cacerts.crt` (CA bundle)

**Certificate Details:**

| File | Purpose | Size |
|------|---------|------|
| `*.crt` | Public certificate (SSL certificate) | ~1.2 KB |
| `*.key` | Private key (never share this!) | ~1.7 KB |
| `cacerts.crt` | Certificate authority bundle | ~3.7 KB |

---

## Step 3: Prepare Seed Data

The database needs initial data for clients, users, and scopes.

### 3.1 Copy Seed Files to Shared Directory

The Docker containers mount seed files from the `shared/` directory:

```bash
# Copy identity data (users and roles)
cp src/DuendeIdentityServer.Admin/identitydata.json shared/identitydata.json

# Copy IdentityServer data (clients, scopes, resources)
cp src/DuendeIdentityServer.Admin/identityserverdata.json shared/identityserverdata.json
```

### 3.2 Verify Seed Files

```bash
ls -lh shared/*.json
```

You should see:
- `identitydata.json` (~413 bytes)
- `identityserverdata.json` (~4.2 KB)
- `serilog.json` (~1 KB)

### 3.3 Understanding Seed Data

**`identitydata.json`** contains:
- **Roles**: `MyRole`
- **Users**: `admin` (password: `Pa$$word123`)

**`identityserverdata.json`** contains:
- **Identity Resources**: `roles`, `openid`, `profile`, `email`, `address`
- **API Scopes**: `MyClientId_api`, `app.api.talentmanagement.read`, `app.api.talentmanagement.write`
- **API Resources**: `MyClientId_api`, `app.api.talentmanagement`
- **Clients**:
  - `MyClientId` (Admin UI)
  - `TalentManagement` (Angular app)
  - `MyClientId_api_swaggerui` (Swagger)
  - `PostmanClient` (API testing)

---

## Step 4: Start Docker Containers

### 4.1 Start All Services

From the project root directory:

```bash
docker-compose up -d
```

**Expected Output:**

```
Creating network "duende-identityserver_proxy" ... done
Creating network "duende-identityserver_identityserverui" ... done
Creating volume "duende-identityserver_dbdata" ... done
Creating nginx ... done
Creating skoruba-duende-identityserver-db ... done
Creating skoruba-duende-identityserver-admin-api ... done
Creating skoruba-duende-identityserver-sts-identity ... done
Creating skoruba-duende-identityserver-admin ... done
```

**What `-d` means:**
- `-d` = detached mode (runs containers in the background)

### 4.2 Monitor Container Startup

Watch the containers start up:

```bash
docker-compose ps
```

All containers should show `Up` status:

```
NAME                                         STATUS
nginx                                        Up 30 seconds
skoruba-duende-identityserver-admin          Up 30 seconds
skoruba-duende-identityserver-admin-api      Up 30 seconds
skoruba-duende-identityserver-db             Up 30 seconds
skoruba-duende-identityserver-sts-identity   Up 30 seconds
```

### 4.3 Wait for Database Initialization

The database needs time to initialize and run migrations:

```bash
# Wait 30 seconds for database initialization
Start-Sleep -Seconds 30

# Or use this to continuously monitor logs
docker-compose logs -f --tail=50 skoruba-duende-identityserver-admin
```

Look for this line to confirm seeding completed:

```
Application started. Press Ctrl+C to shut down.
```

---

## Step 5: Verify the Setup

### 5.1 Check Container Logs

```bash
# View all logs
docker-compose logs

# View specific container logs
docker logs skoruba-duende-identityserver-sts-identity

# Follow logs in real-time
docker-compose logs -f
```

### 5.2 Verify Database Connection

Check that the admin container successfully seeded the database:

```bash
docker logs skoruba-duende-identityserver-admin 2>&1 | grep -i "client"
```

You should see INSERT statements for clients, indicating successful seeding.

### 5.3 Test HTTPS Endpoints

```bash
# Test IdentityServer discovery endpoint
curl -k https://sts.skoruba.local/.well-known/openid-configuration
```

Expected: JSON response with IdentityServer metadata.

---

## Accessing the Services

### Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **IdentityServer (STS)** | https://sts.skoruba.local | OAuth 2.0 / OIDC authentication server |
| **Admin UI** | https://admin.skoruba.local | Web interface for managing IdentityServer |
| **Admin API** | https://admin-api.skoruba.local | REST API with Swagger documentation |
| **SQL Server** | `localhost:7900` | Direct database access (SSMS, Azure Data Studio) |

### Default Credentials

**Admin UI Login:**
- Username: `admin`
- Password: `Pa$$word123`

**SQL Server:**
- Server: `localhost,7900`
- Username: `sa`
- Password: `Password_123`
- Database: `IdentityServerAdmin`

### Browser Security Warnings

Since we're using self-signed certificates, your browser will show security warnings.

**To Proceed:**

**Chrome/Edge:**
1. Click **"Advanced"**
2. Click **"Proceed to [site] (unsafe)"**

**Firefox:**
1. Click **"Advanced"**
2. Click **"Accept the Risk and Continue"**

You need to do this once for each domain:
- `sts.skoruba.local`
- `admin.skoruba.local`
- `admin-api.skoruba.local`

---

## Troubleshooting

### Issue: "This site can't be reached"

**Cause:** Hosts file not configured or Docker containers not running.

**Solution:**
1. Verify hosts file entries: `type C:\Windows\System32\drivers\etc\hosts`
2. Check containers: `docker-compose ps`
3. Restart containers: `docker-compose restart`

### Issue: "ERR_SSL_UNRECOGNIZED_NAME_ALERT"

**Cause:** SSL certificates missing or not properly mounted.

**Solution:**
1. Verify certificates exist: `ls shared/nginx/certs/`
2. Regenerate certificates (see Step 2)
3. Restart containers: `docker-compose down && docker-compose up -d`

### Issue: "Connection to SQL Server failed"

**Cause:** SQL Server SSL certificate validation failing.

**Solution:**
Connection strings include `TrustServerCertificate=True` to bypass this. Verify in `docker-compose.yml`:

```yaml
ConnectionStrings__ConfigurationDbConnection=Server=db;Database=IdentityServerAdmin;User Id=sa;Password=Password_123;MultipleActiveResultSets=true;TrustServerCertificate=True
```

### Issue: "Seed data not loading"

**Cause:** Seed files not properly mounted or database already initialized.

**Solution:**
1. Verify seed files: `ls shared/*.json`
2. Delete database and restart:
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### Issue: "Port already in use"

**Cause:** Another application is using ports 80, 443, or 7900.

**Solution:**
1. Find the process: `netstat -ano | findstr :80`
2. Stop the conflicting service
3. Or modify ports in `docker-compose.yml`

---

## Understanding How It Works

### 1. Request Flow

```
Browser Request: https://admin.skoruba.local
         ↓
Windows Hosts File (127.0.0.1)
         ↓
Docker Desktop → nginx-proxy (Port 443)
         ↓
nginx checks VIRTUAL_HOST environment variable
         ↓
Routes to: skoruba-duende-identityserver-admin (Port 8080)
         ↓
Admin UI Application
         ↓
Connects to: SQL Server (db:1433)
```

### 2. nginx-proxy Routing

The nginx-proxy container automatically configures routing based on environment variables:

```yaml
environment:
  - VIRTUAL_HOST=admin.skoruba.local
  - VIRTUAL_PORT=8080
```

When a request arrives for `admin.skoruba.local`, nginx:
1. Matches the domain to the container
2. Terminates SSL using the certificate in `/etc/nginx/certs/`
3. Proxies to the container on port 8080

### 3. SSL Certificate Chain

```
Browser
  ↓ HTTPS Request
nginx-proxy
  ↓ Loads: admin.skoruba.local.crt + admin.skoruba.local.key
  ↓ Terminates SSL
  ↓ HTTP (internal)
Admin Container
  ↓ Needs to call: https://sts.skoruba.local
  ↓ Loads: /usr/local/share/ca-certificates/cacerts.crt
  ↓ Trusts self-signed certificate
IdentityServer Container
```

### 4. Database Seeding Process

1. **Container starts** with command: `dotnet DuendeIdentityServer.Admin.dll /seed`
2. **Runs migrations** to create database schema
3. **Reads seed files**: `identitydata.json` and `identityserverdata.json`
4. **Checks existing data**: Queries database for existing clients, users, etc.
5. **Inserts missing data**: Only adds data that doesn't exist
6. **Completes seeding**: Application starts normally

### 5. Container Communication

Containers communicate via Docker networks:

```yaml
networks:
  identityserverui:
    driver: bridge
  proxy:
    driver: bridge
```

- **identityserverui**: Internal network for STS, Admin, Admin API, and Database
- **proxy**: External network for nginx-proxy to route incoming requests

### 6. Data Persistence

Data is persisted in Docker volumes:

```yaml
volumes:
  dbdata:
    driver: local
```

The `dbdata` volume stores SQL Server data files, ensuring data survives container restarts.

**To reset the database:**
```bash
docker-compose down -v  # -v removes volumes
```

---

## Useful Commands

### Container Management

```bash
# Start all containers
docker-compose up -d

# Stop all containers
docker-compose down

# Restart all containers
docker-compose restart

# Stop and remove everything (including database)
docker-compose down -v

# View container status
docker-compose ps

# View container resource usage
docker stats
```

### Logs and Debugging

```bash
# View all logs
docker-compose logs

# View logs for specific service
docker-compose logs skoruba-duende-identityserver-admin

# Follow logs in real-time
docker-compose logs -f

# View last 50 lines
docker-compose logs --tail=50

# Search logs for errors
docker-compose logs | grep -i error
```

### Database Access

```bash
# Connect to SQL Server container
docker exec -it skoruba-duende-identityserver-db /bin/bash

# Access database via SQL command-line (if tools installed)
docker exec -it skoruba-duende-identityserver-db /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P Password_123
```

### Certificate Management

```bash
# View certificate details
openssl x509 -in shared/nginx/certs/sts.skoruba.local.crt -text -noout

# Check certificate expiration
openssl x509 -in shared/nginx/certs/sts.skoruba.local.crt -enddate -noout

# Regenerate all certificates
docker run --rm --entrypoint sh -v "${PWD}/shared/nginx/certs:/certs" alpine/openssl -c '...'
```

### Network Inspection

```bash
# List Docker networks
docker network ls

# Inspect network details
docker network inspect duende-identityserver_identityserverui

# View container IP addresses
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' skoruba-duende-identityserver-admin
```

### Clean Up

```bash
# Remove stopped containers
docker-compose rm

# Remove dangling images
docker image prune

# Remove all unused resources
docker system prune -a

# Full cleanup (WARNING: removes all Docker data)
docker system prune -a --volumes
```

---

## Production Considerations

**⚠️ This setup is for DEVELOPMENT ONLY. Do NOT use in production without:**

1. **Real SSL Certificates**
   - Use Let's Encrypt or commercial certificates
   - Implement certificate rotation

2. **Secure Secrets**
   - Use Docker secrets or Azure Key Vault
   - Never commit secrets to source control

3. **Database Security**
   - Strong passwords (not default)
   - Network isolation
   - Regular backups

4. **Logging and Monitoring**
   - Centralized logging (ELK, Application Insights)
   - Health checks and alerts
   - Performance monitoring

5. **Scaling**
   - Load balancing for multiple instances
   - Separate database server
   - Redis for distributed caching

6. **Updates**
   - Regular security updates
   - Container image scanning
   - Dependency updates

---

## Summary

You've successfully set up Duende IdentityServer running in Docker with:

✅ **nginx-proxy** for SSL termination and routing
✅ **IdentityServer** for OAuth 2.0 / OIDC authentication
✅ **Admin UI** for managing configuration
✅ **Admin API** for programmatic access
✅ **SQL Server** for data persistence
✅ **Self-signed SSL certificates** for HTTPS
✅ **Seed data** for clients, users, and scopes

**Next Steps:**
- Customize client configurations in `shared/identityserverdata.json`
- Add additional users and roles in `shared/identitydata.json`
- Integrate with your Angular/React/Vue application
- Configure CORS for your frontend application
- Set up continuous integration for Docker builds

---

## Additional Resources

- **Duende IdentityServer Documentation**: https://docs.duendesoftware.com/identityserver/v7
- **Skoruba Admin UI**: https://github.com/skoruba/Duende.IdentityServer.Admin
- **Docker Documentation**: https://docs.docker.com/
- **nginx-proxy**: https://github.com/nginx-proxy/nginx-proxy
- **OAuth 2.0 Specification**: https://oauth.net/2/
- **OpenID Connect Specification**: https://openid.net/connect/

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Author**: Claude Code Documentation
**License**: MIT
