# hello-newapp

Small Flask app packaged with Docker, Kubernetes manifests, and a Helm chart.

The app used here is the fallback app from the teacher repo:

https://github.com/elevy99927/hello-newapp/blob/argo-advance/app.py

This version runs on port `8000`, so the Dockerfile, Kubernetes files, and Helm chart all use port `8000`.

## Project structure

- `app/` has the Flask app, Dockerfile, and Python requirements.
- `k8s/` has the raw Kubernetes YAML files I used for testing before Helm.
- `helmchart/hello-newapp/` has the Helm chart.

## Docker

Build the image from the `app` folder:

```bash
docker build -t vladxgx/hello-newapp:1.0.0 app
```

Push it to Docker Hub:

```bash
docker push vladxgx/hello-newapp:1.0.0
```

## Kubernetes

Apply the regular Kubernetes manifests:

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Check the resources:

```bash
kubectl get deployment
kubectl get service
kubectl get pods
```

## Helm

The Helm chart is in:

```bash
./helmchart/hello-newapp
```

Lint the chart:

```bash
helm lint ./helmchart/hello-newapp
```

Render the templates locally:

```bash
helm template hello-release ./helmchart/hello-newapp
```

Install the chart:

```bash
helm install hello-release ./helmchart/hello-newapp
```

Upgrade the release after changing values or templates:

```bash
helm upgrade hello-release ./helmchart/hello-newapp
```

Check Helm history:

```bash
helm history hello-release
```

Rollback to revision 1:

```bash
helm rollback hello-release 1
```

Uninstall the release:

```bash
helm uninstall hello-release
```

## Values

Main values are in `helmchart/hello-newapp/values.yaml`.

The chart values control:

- image repository
- image tag
- replica count
- service type
- service port
- service target port
- resources

Current image:

```text
vladxgx/hello-newapp:1.0.0
```

Current app port:

```text
8000
```

## Secrets

No real AWS keys are committed. The `.env.example` file only has placeholder values.
