# Pipeline

The CI pipeline is defined in `azure-pipelines.yml`.

## What It Does

On pushes and pull requests targeting `main`, the pipeline:

1. Checks out the repository.
2. Installs Java 17, Node.js 20, and Python 3.11.
3. Builds and tests the Spring Boot backend with Maven.
4. Installs frontend dependencies, runs Vitest, and builds the React app.
5. Installs Python requirements and runs pytest.
6. Publishes build artifacts for backend, frontend, Python service, database scripts, and docs.

## Azure DevOps Setup

1. Create an Azure DevOps project.
2. Connect this GitHub repository to Azure Pipelines.
3. Select `azure-pipelines.yml` from the repository root.
4. Save and run the pipeline.

No database credentials are required for the current pipeline because tests use mocked or local logic only.

## Artifacts

The published `rtd-dashboard` artifact contains:

- `backend/` Spring Boot JAR
- `frontend/` built React static files
- `python-service/` Python automation files
- `support/` database scripts, docs, and README
