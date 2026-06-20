# hello-newapp

`hello-newapp` is a small Flask application packaged with Docker and deployed
through Jenkins, Helm, ArgoCD, and GitOps.

The application:

- Runs on port `8000`.
- Exposes the application at `/`.
- Exposes Prometheus metrics at `/metrics`.
- Uses the Docker Hub image `vladxgx/hello-newapp`.

## CI/CD flow

Jenkins uses my shared library from `Vladxgx/mySharedLib` for the basic Docker
and test steps.

The pipeline:

- Checks out the app repo.
- Runs Python compile check and Bandit scan.
- Builds `vladxgx/hello-newapp:${BUILD_NUMBER}`.
- Runs a Trivy image scan.
- Pushes the image to Docker Hub.
- Renders the Helm chart into `devops-template.yaml`.
- Updates the selected `dev`, `qa`, or `prod` folder in `Vladxgx/argo-git-ops`.

Jenkins sends success and failure messages directly to Slack using `curl` and
the secret text credential `slack-webhook-url`. Docker Hub and GitHub
credentials are also stored in Jenkins and are not committed to this repo.

ArgoCD reads the rendered manifests from the GitOps repo and deploys the app to
Kubernetes. Prometheus and Grafana are also managed from the GitOps repo.

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
