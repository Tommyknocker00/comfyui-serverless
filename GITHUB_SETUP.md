# ComfyUI Serverless - GitHub Actions Setup

## Stappen om de Docker image automatisch te builden

### 1. Docker Hub Access Token maken

1. Ga naar https://hub.docker.com/settings/security
2. Klik "New Access Token"
3. Description: `GitHub Actions`
4. Permissions: `Read, Write, Delete`
5. Klik "Generate"
6. **KOPIEER DE TOKEN** (je ziet hem maar 1 keer!)

### 2. GitHub Secrets instellen

1. Ga naar je repository: https://github.com/Tommyknocker00/comfyui-serverless
2. Klik op "Settings" (bovenaan)
3. Links: "Secrets and variables" → "Actions"
4. Klik "New repository secret"
5. Maak 2 secrets:

**Secret 1:**
- Name: `DOCKERHUB_USERNAME`
- Value: `tommyknocker000`

**Secret 2:**
- Name: `DOCKERHUB_TOKEN`
- Value: `[plak hier je Docker Hub token]`

### 3. Bestanden uploaden naar GitHub

Je hebt 2 opties:

#### Optie A: Via GitHub Web Interface (makkelijkst)

1. Ga naar https://github.com/Tommyknocker00/comfyui-serverless
2. Klik "uploading an existing file"
3. Sleep deze bestanden erin:
   - `Dockerfile`
   - `handler.py`
   - `workflow_api.json`
   - `requirements.txt`
   - `.dockerignore`
4. Maak een folder `.github/workflows/`
5. Upload daarin: `build.yml`
6. Commit!

#### Optie B: Via Git (op je Mac)

```bash
# Installeer git als je dat nog niet hebt
# Download de runpod-serverless folder naar je Mac

cd pad/naar/runpod-serverless

# Git initialiseren
git init
git add .
git commit -m "Initial commit"

# Koppel aan je GitHub repo
git remote add origin https://github.com/Tommyknocker00/comfyui-serverless.git
git branch -M main
git push -u origin main
```

### 4. Build starten

Zodra je de bestanden hebt geüpload naar GitHub:

1. Ga naar "Actions" tab in je repository
2. Klik op "Build and Push Docker Image"
3. Klik "Run workflow" → "Run workflow"
4. Wacht 10-15 minuten
5. ✅ Image staat op Docker Hub!

### 5. Controleren

Check of je image er staat:
https://hub.docker.com/r/tommyknocker000/comfyui-serverless

Je ziet dan: `latest` tag met een timestamp.

## Klaar!

Je kunt nu verder met de RunPod Serverless setup! 🔥

---

## Troubleshooting

**"Error: DOCKERHUB_USERNAME secret not found"**
→ Secrets niet goed ingesteld in stap 2

**"denied: requested access to the resource is denied"**
→ Docker Hub token heeft geen Write permissions

**Build duurt lang**
→ Normaal! Eerste keer duurt 10-15 min. Daarna sneller door caching.
