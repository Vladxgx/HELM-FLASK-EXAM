# hello-newapp

`hello-newapp` is a Flask application packaged with Docker and deployed through
Jenkins, Helm, and ArgoCD.

The application:

- Runs on port `8000`.
- Exposes the application at `/`.
- Exposes Prometheus metrics at `/metrics`.
- Uses the Docker Hub image `vladxgx/hello-newapp`.

## CI/CD flow

Jenkins checks out the application, runs simple lint and security checks,
builds and pushes the Docker image, and renders the Helm chart. It then commits
the rendered `devops-template.yaml` to the selected `dev`, `qa`, or `prod`
folder in `Vladxgx/argo-git-ops`.

Jenkins sends success and failure messages directly to Slack using `curl` and
the secret text credential `slack-webhook-url`. Docker Hub and GitHub
credentials are also stored in Jenkins and are not committed to this repo.

## Run locally

```bash
docker build -t vladxgx/hello-newapp:local .
docker run -p 8000:8000 vladxgx/hello-newapp:local
curl http://localhost:8000/metrics
```

## Render the Helm chart

```bash
helm template hello-newapp ./helmchart/hello-newapp --set image.tag=local
```

The chart deploys a `ClusterIP` Service on port `8000` and includes Prometheus
scrape annotations for `/metrics`.

## Terraform

The Terraform part of the project is maintained separately:

https://github.com/Vladxgx/TF-EXAM
