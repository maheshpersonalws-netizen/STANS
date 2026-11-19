# STANS Navigation System - Complete DevOps & Deployment Guide

Welcome to the **Smart Traffic-Aware Navigation System (STANS)** deployment guide. This document explains every concept from scratch, designed specifically for beginners, and walks you through containerizing, automating, and deploying this system to production.

---

## Table of Contents
1. [What is STANS & Core Concepts](#1-what-is-stans--core-concepts)
2. [DevOps Concepts Explained Simply](#2-devops-concepts-explained-simply)
3. [Part 1: Forking & Local Setup](#3-part-1-forking--local-setup)
4. [Part 2: Docker Containerization](#4-part-2-docker-containerization)
5. [Part 3: Automated CI/CD Pipeline with GitHub Actions](#5-part-3-automated-cicd-pipeline-with-github-actions)
6. [Part 4: Production Cloud Deployment & SSL](#6-part-4-production-cloud-deployment--ssl)
7. [Stretch Goals & Advanced DevOps](#7-stretch-goals--advanced-devops)
8. [Troubleshooting & FAQs](#8-troubleshooting--faqs)

---

## 1. What is STANS & Core Concepts

**STANS (Smart Traffic-Aware Navigation System)** is a modern React + TypeScript application that models traffic networks as weighted directed graphs. It uses classic graph algorithms to find optimal routes:

- **Dijkstra's Algorithm with Traffic Penalties**: Calculates the shortest path between intersections while dynamically weighting edges based on traffic congestion, road incidents, or weather delays.
- **Kruskal's & Prim's Algorithms**: Compute Minimum Spanning Trees (MST) to identify the most cost-efficient backbone routes for traffic sensor grids or road maintenance.
- **Disjoint Set Union (Union-Find)**: Efficient cycle detection for network connectivity and path planning.

---

## 2. DevOps Concepts Explained Simply

| Concept | What It Is | Why We Use It |
| :--- | :--- | :--- |
| **Containerization (Docker)** | Bundles the code, libraries, and web server into an isolated package called an **Image**. | Eliminates "it works on my machine" syndrome. It runs identically everywhere. |
| **Multi-Stage Build** | Uses two stages in `Dockerfile`: Stage 1 compiles the app, Stage 2 serves it with Nginx. | Shrinks the final image from 1.5 GB down to ~35 MB and removes build tools for security. |
| **Nginx & SPA Routing** | A high-speed web server. Single Page Apps (SPAs) need `try_files $uri $uri/ /index.html;`. | Without this, clicking refresh on a sub-route like `/dashboard` would give a 404 error. |
| **CI/CD (GitHub Actions)** | Automated scripts triggered whenever you push commits to GitHub. | Runs automated tests, builds the Docker image, and uploads it to a registry automatically. |
| **SSL/TLS & Reverse Proxy** | Host Nginx intercepts HTTPS port 443 traffic, decrypts it, and forwards it to Docker on port 8080. | Keeps web traffic encrypted and secure without having to bake SSL keys into Docker images. |

---

## 3. Part 1: Forking & Local Setup

### Step 1: Fork the Repository
1. Navigate to [https://github.com/weedu230/STANS](https://github.com/weedu230/STANS).
2. Click the **Fork** button in the upper-right corner to copy it to your GitHub account.

### Step 2: Clone Locally
Clone your fork to your computer:
```bash
git clone https://github.com/<YOUR-GITHUB-USERNAME>/STANS.git
cd STANS
```

### Step 3: Install & Run
```bash
# Install dependencies
npm install

# Start development server
npm run dev
```
Open your browser at `http://localhost:5173` to test the user interface.

---

## 4. Part 2: Docker Containerization

### Understanding the Multi-Stage Dockerfile
Open `Dockerfile` in the root directory. You will see two stages:

1. **Stage 1 (`builder`)**:
   - Uses `node:20-alpine`.
   - Copies `package.json` and runs `npm ci` (fast, deterministic install).
   - Runs `npm run build` to generate compiled HTML, CSS, and JS files in `dist/`.

2. **Stage 2 (`production`)**:
   - Uses `nginx:1.27-alpine` (~23 MB base).
   - Copies `nginx/default.conf` to configure React client-side routing.
   - Copies only the compiled `/dist` directory from Stage 1.
   - Adds an automated health check at `/health`.

### Test the Docker Image Locally

#### Option A: Using Docker CLI
```bash
# 1. Build the Docker image
docker build -t stans-app .

# 2. Run the container mapping host port 8080 to container port 80
docker run -d --name stans-app -p 8080:80 stans-app

# 3. Verify it is running
docker ps
```
Now open your browser at **`http://localhost:8080`**. Test navigating between `/` and `/dashboard` and press Refresh to ensure client-side routing works!

To stop and clean up:
```bash
docker stop stans-app
docker rm stans-app
```

#### Option B: Using Docker Compose
```bash
# Start in the background
docker compose up -d

# Check logs
docker compose logs -f

# Stop container
docker compose down
```

---

## 5. Part 3: Automated CI/CD Pipeline with GitHub Actions

The file `.github/workflows/deploy.yml` automates the entire testing, building, and publishing cycle.

### How the Pipeline Works:
1. **Trigger**: Any `git push` or `pull_request` targeting the `main` branch.
2. **Job 1 (`validate`)**: Sets up Node 20 on an Ubuntu VM, installs dependencies, and ensures `npm run build` succeeds.
3. **Job 2 (`docker-build-push`)**: Builds the Docker image and publishes it to **GitHub Container Registry (ghcr.io)** under your repository.
4. **Job 3 (`deploy-remote`)** *(Optional)*: If SSH secrets are added, it connects to your cloud server via SSH, pulls the new image, and restarts the container with zero manual intervention.

### Configuring GitHub Secrets
Go to your GitHub repo -> **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**:

| Secret Name | Value Description | Mandatory? |
| :--- | :--- | :--- |
| `DOCKERHUB_USERNAME` | Your Docker Hub username (if pushing to Docker Hub) | Optional (GHCR works by default) |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token | Optional |
| `SSH_HOST` | Public IP address of your cloud server | Optional (for auto-deploy) |
| `SSH_USERNAME` | SSH username (e.g., `ubuntu` or `root`) | Optional (for auto-deploy) |
| `SSH_PRIVATE_KEY` | Your server's private SSH key (`id_rsa` or `.pem`) | Optional (for auto-deploy) |

---

## 6. Part 4: Production Cloud Deployment & SSL

You can deploy STANS to any cloud provider (AWS EC2, DigitalOcean Droplet, Google Cloud Compute Engine, or Oracle Cloud Free Tier).

### Step 1: Launch a Cloud Virtual Machine
- **OS**: Ubuntu 22.04 LTS (x86_64 or ARM64)
- **Size**: 1 vCPU, 1 GB RAM (e.g., AWS `t3.micro` or DigitalOcean `$4/mo` Droplet)
- **Networking**: Allow inbound ports:
  - Port `22` (SSH)
  - Port `80` (HTTP)
  - Port `443` (HTTPS)

### Step 2: Connect to your Server
```bash
ssh -i your-key.pem ubuntu@YOUR_SERVER_PUBLIC_IP
```

### Step 3: Run the Automated Server Setup Script
Clone your repository or download the setup script:
```bash
# Clone the repository
git clone https://github.com/<YOUR-USERNAME>/STANS.git
cd STANS

# Execute the provisioning script (installs Docker, Nginx, Certbot, Firewall)
sudo bash deploy/setup-server.sh
```

### Step 4: Run the STANS Container with Automatic Restart
```bash
docker run -d \
  --name stans-app \
  --restart=always \
  -p 127.0.0.1:8080:80 \
  ghcr.io/<your-github-username>/stans:latest
```
> [!NOTE]
> Binding to `127.0.0.1:8080` ensures the container is only reachable by the local host, forcing all public visitors through the secure Host Nginx reverse proxy.

### Step 5: Configure Host Nginx Reverse Proxy & SSL (Let's Encrypt)
1. Copy the host Nginx configuration:
   ```bash
   sudo cp deploy/host-nginx.conf /etc/nginx/sites-available/stans.conf
   ```
2. Edit `/etc/nginx/sites-available/stans.conf` and update `server_name` with your domain name (or server IP):
   ```bash
   sudo nano /etc/nginx/sites-available/stans.conf
   ```
3. Enable the site and test configuration:
   ```bash
   sudo ln -s /etc/nginx/sites-available/stans.conf /etc/nginx/sites-enabled/
   sudo rm -f /etc/nginx/sites-enabled/default
   sudo nginx -t
   sudo systemctl restart nginx
   ```
4. Obtain free SSL/TLS certificate via Certbot:
   ```bash
   sudo certbot --nginx -d your-domain.com -d www.your-domain.com
   ```
   Certbot will automatically install the certificates and configure auto-renewal.

---

## 7. Stretch Goals & Advanced DevOps

### 1. Prometheus & Grafana Monitoring
To observe CPU, memory, network I/O, and container health metrics:
```bash
# Start Prometheus, Grafana, and cAdvisor
docker compose -f docker-compose.monitoring.yml up -d
```
- Open **Prometheus** at `http://<SERVER-IP>:9090`
- Open **cAdvisor** at `http://<SERVER-IP>:8081`
- Open **Grafana** at `http://<SERVER-IP>:3000` (User: `admin`, Password: `admin`)
  - Add Prometheus data source: `http://prometheus:9090`
  - Import Dashboard ID `893` or `14282` for instant Docker container monitoring.

### 2. Kubernetes Deployment
For high availability and rolling updates across clusters:
```bash
kubectl apply -f k8s/stans.yaml
kubectl get pods -l app=stans
kubectl get svc stans-service
```

### 3. Infrastructure as Code (Terraform)
To automatically provision the AWS EC2 server and firewall rules:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

---

## 8. Troubleshooting & FAQs

### Q: Why do I get a 404 when refreshing `/dashboard` in React?
**Answer**: Single Page Applications (SPAs) rely on client-side routing. Without `try_files $uri $uri/ /index.html;` in Nginx, Nginx looks for a real folder named `/dashboard/` on the server disk. Our `nginx/default.conf` fixes this by redirecting all unknown paths to `index.html`.

### Q: How do I view container logs if something goes wrong?
```bash
docker logs stans-app -f
```

### Q: How do I test the internal health check?
```bash
curl http://127.0.0.1:8080/health
# Expected output: healthy
```

### Q: How do I verify the firewall is active?
```bash
sudo ufw status verbose
```
It should show ports 22, 80, and 443 are ALLOWED, and all other incoming ports are blocked.
