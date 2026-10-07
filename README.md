# Multi-Region GKE SRE Observability Platform

This repository contains a production-style, multi-region Kubernetes platform on Google Cloud with infrastructure automation, observability, centralized log analytics, security scanning, and regional failover.

The platform is provisioned using Terraform and deployed through GitHub Actions using Google Cloud Workload Identity Federation.

---

## Architecture

```text
                         Internet
                            |
                            v
                Global Multi-Cluster Gateway
                            |
                        HTTPRoute
                            |
                      ServiceImport
                     /             \
                    /               \
                   v                 v
          GKE Primary             GKE Secondary
          us-east1                us-west1
              |                       |
        ServiceExport             ServiceExport
              |                       |
          Application             Application
             Pods                    Pods


Observability
------------------------------------------------

Application Metrics
       |
       v
Managed Prometheus
       |
       v
Grafana Dashboards + Alerts


Application / Kubernetes Logs
       |
       v
Cloud Logging
       |
       v
Logging Sink
       |
       v
BigQuery
       |
       v
SQL Log Analysis
```

---

## Key Features

- Multi-region GKE architecture
- Primary cluster in `us-east1`
- Secondary cluster in `us-west1`
- Shared Google Cloud VPC
- Private GKE nodes
- Cloud NAT for outbound access
- GKE Fleet integration
- Multi-Cluster Service Discovery
- ServiceExport / ServiceImport
- Global Multi-Cluster Gateway
- Regional failover
- GitHub Actions CI/CD
- Terraform infrastructure automation
- Workload Identity Federation
- Managed Prometheus
- Grafana dashboards and alerts
- Cloud Logging
- BigQuery log analytics
- Customer-managed encryption using Cloud KMS
- TFLint
- Checkov
- ShellCheck
- Trivy container scanning
- Hadolint
- Python dependency scanning

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       ├── app-deploy.yml
│       └── grafana-deploy.yml
│
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── terraform/
│   ├── backend.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── services.tf
│   ├── networking.tf
│   ├── gke.tf
│   ├── fleet.tf
│   └── bigquery.tf
│
├── kubernetes/
│   ├── app/
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── networkpolicy.yaml
│   │   ├── podmonitoring.yaml
│   │   └── serviceexport.yaml
│   │
│   ├── gateway/
│   │   ├── gateway.yaml
│   │   ├── httproute.yaml
│   │   └── healthcheckpolicy.yaml
│   │
│   └── observability/
│       └── grafana/
│
└── docs/
    └── troubleshooting.md
```

---

## Infrastructure as Code

Terraform manages the core Google Cloud infrastructure used by the platform.

### VPC and Subnets

The VPC provides the private network for the GKE clusters and other cloud resources.

Separate regional subnets are used for the primary and secondary GKE clusters.

The subnets also include secondary IP ranges for:

- Kubernetes Pods
- Kubernetes Services

This allows GKE to use VPC-native networking.

### Firewall Rules

Firewall rules control which network traffic is allowed between resources.

They are used to permit required internal communication between:

- GKE nodes
- Pods
- Services
- Multi-region cluster components

The goal is to allow only the traffic required by the platform.

### Cloud Routers

Cloud Routers are used together with Cloud NAT.

They provide the routing control required for private GKE nodes to access external services without assigning public IP addresses directly to the nodes.

### Cloud NAT

The GKE worker nodes are private and do not have public IP addresses.

Cloud NAT allows those private nodes to make outbound connections to the internet when required.

Examples include:

- downloading container images
- accessing external APIs
- installing packages
- communicating with external services

Inbound internet access to the nodes is not opened by Cloud NAT.

### GKE Clusters

Two regional Google Kubernetes Engine clusters provide the application runtime platform.

- Primary cluster: `us-east1`
- Secondary cluster: `us-west1`

Using two regions improves availability and allows regional failover.

### GKE Node Pools

Node pools provide the worker machines where Kubernetes Pods run.

They separate the Kubernetes control plane from the compute resources used by application workloads.

Terraform manages the node pool configuration so compute capacity can be recreated consistently.

### Artifact Registry

Artifact Registry stores the container images built by the application CI/CD pipeline.

The deployment flow is:

```text
Source Code
    |
    v
Docker Build
    |
    v
Security Scan
    |
    v
Artifact Registry
    |
    v
GKE Clusters

Terraform state is stored remotely in a Google Cloud Storage backend.

---

## CI/CD

Infrastructure changes follow a pull request workflow.

```text
Feature Branch
      |
      v
Pull Request
      |
      +--> Terraform Format
      +--> Terraform Validate
      +--> TFLint
      +--> Checkov
      +--> ShellCheck
      +--> Terraform Plan
      |
      v
Merge to main
      |
      v
Manual Terraform Apply
```

Terraform Apply is restricted to manually triggered runs from the `main` branch.

Application deployment follows a separate GitHub Actions workflow.

```text
Application Change
      |
      v
Build Container Image
      |
      v
Security Scan
      |
      v
Artifact Registry
      |
      +----------------+
      |                |
      v                v
GKE Primary       GKE Secondary
```

The same immutable image is deployed to both regions.

---

## Application

The application is a Python Flask service running behind Gunicorn.

Available endpoints include:

- `/` — application status
- `/health` — application health endpoint
- `/ready` — readiness endpoint
- `/slow` — simulates a slow request for latency testing
- `/error` — generates an HTTP 500 response for error testing
- `/metrics` — exposes Prometheus metrics

---

## Kubernetes Security

The application deployment includes several security controls:

- Non-root container execution
- Read-only root filesystem
- Linux capabilities dropped
- RuntimeDefault seccomp profile
- Resource requests and limits
- Kubernetes NetworkPolicy
- Liveness probe
- Readiness probe
- Disabled service account token automount
- Container image vulnerability scanning

---

## Observability

### Metrics

Application metrics are exposed using the Prometheus client library.

Key metrics include:

- `http_requests_total` — tracks request volume by method, endpoint, and status
- `http_request_duration_seconds` — tracks request latency

GKE Managed Prometheus collects application metrics using `PodMonitoring`.

---

## Grafana

Grafana is deployed into the `monitoring` namespace.

The primary dashboard includes:

- Request rate
- HTTP 5xx error rate
- p95 request latency
- Application availability

Grafana configuration is managed through the repository rather than manual UI configuration.

---

## Alerting

Grafana alert rules include:

### High Application Error Rate

Triggers when the HTTP 5xx error rate exceeds the configured threshold.

### High Application p95 Latency

Triggers when p95 request latency exceeds the configured threshold.

Alert conditions were validated using the `/error` and `/slow` application endpoints.

---

## Multi-Region Availability

The application runs in two GKE regions:

- Primary: `us-east1`
- Secondary: `us-west1`

Both clusters are members of a GKE Fleet.

The application Service is exported from both clusters using `ServiceExport`.

Multi-Cluster Service Discovery creates a `ServiceImport` representing the shared application service.

The global Gateway sends traffic to available backends across both clusters.

---

## Global Traffic Flow

```text
Client
  |
  v
Global External Application Load Balancer
  |
  v
Multi-Cluster Gateway
  |
  v
HTTPRoute
  |
  v
ServiceImport
  |
  +------------------+
  |                  |
  v                  v
Primary Service   Secondary Service
  |                  |
  v                  v
Application Pods  Application Pods
```

---

## Health Checks

A GKE `HealthCheckPolicy` is attached to the application Service.

The backend health check uses:

```text
Protocol: HTTP
Path: /health
Port: 8080
```

This allows the global Gateway to detect healthy application backends.

---

## Failover Validation

Regional failover was tested by scaling the primary deployment to zero replicas.

```bash
kubectl scale deployment sre-observability-app \
  -n sre-app \
  --replicas=0
```

While the primary application had no running pods, requests through the same global endpoint continued returning HTTP 200.

This confirmed traffic was routed to the secondary cluster.

The primary deployment was then restored:

```bash
kubectl scale deployment sre-observability-app \
  -n sre-app \
  --replicas=2
```

---

## Log Analytics

Application and Kubernetes container logs are collected by Google Cloud Logging.

A project logging sink exports logs from the `sre-app` namespace into BigQuery.

```text
GKE
 |
 v
Cloud Logging
 |
 v
Logging Sink
 |
 v
BigQuery Dataset
 |
 v
SQL Analysis
```

The BigQuery dataset can be used for:

- Error analysis
- Request analysis
- Cluster comparison
- Pod-level investigation
- Historical trend analysis
- Failover analysis

---

## BigQuery Encryption

The BigQuery dataset uses a customer-managed encryption key stored in Google Cloud KMS.

The BigQuery encryption service account receives:

```text
roles/cloudkms.cryptoKeyEncrypterDecrypter
```

on the encryption key.

This provides additional control over encryption at rest.

---

## Example Log Analysis

Examples of SRE questions that can be answered using BigQuery include:

- Which cluster generated the most application logs?
- Which pods generated errors?
- What happened around a failover event?
- How did application behavior change over time?
- Which workloads produced the largest volume of logs?

---

## Infrastructure Security Scanning

Infrastructure and application changes are scanned before deployment.

## What Each CI Check Does

### Terraform Format

`terraform fmt -check -recursive`

Checks whether Terraform files follow standard Terraform formatting.

It does not change infrastructure and does not validate permissions.

### Terraform Validate

`terraform validate`

Checks whether the Terraform configuration is syntactically and structurally valid.

It catches issues such as:

- invalid references
- duplicate resources
- missing required arguments
- incorrect Terraform configuration

It does not confirm that the deployment identity has all required GCP permissions.

### TFLint

TFLint performs static analysis on Terraform code.

It helps identify:

- invalid or deprecated configuration
- provider-related issues
- missing provider version constraints
- Terraform best-practice issues

### Checkov

Checkov performs security and compliance scanning against Terraform and Kubernetes configuration.

Examples include:

- insecure IAM configuration
- missing encryption controls
- Kubernetes security settings
- cloud resource security policies

Where a security requirement is intentionally implemented differently, documented Checkov suppressions may be used.

### Terraform Plan

`terraform plan`

Shows the infrastructure changes Terraform intends to make before deployment.

Typical output includes:

- resources to create
- resources to modify
- resources to destroy

A successful plan does not guarantee that Apply will succeed because some cloud API permissions and runtime dependencies are only evaluated during Apply.

### ShellCheck

ShellCheck analyzes shell scripts for common scripting problems.

Examples include:

- quoting issues
- unsafe variable expansion
- incorrect shell syntax
- potentially unreliable commands

### Hadolint

Hadolint analyzes Dockerfiles for Docker best practices and common configuration issues.

### Trivy

Trivy scans container images for known vulnerabilities.

It helps identify vulnerable operating-system packages and application dependencies before an image is deployed.

### pip-audit

`pip-audit` checks Python dependencies against known vulnerability databases.

This helps detect vulnerable packages listed in `requirements.txt`.

### Kubernetes Checkov

Rendered Kubernetes manifests are scanned with Checkov before deployment.

This helps identify issues such as:

- privileged containers
- missing security settings
- unsafe container configuration
- weak pod security controls

---

## Authentication

GitHub Actions authenticates to Google Cloud using Workload Identity Federation.

No long-lived Google Cloud service account keys are stored in GitHub.

```text
GitHub Actions
      |
      v
Workload Identity Federation
      |
      v
Terraform Service Account
      |
      v
Google Cloud APIs
```

---

## Troubleshooting

Several infrastructure and application-delivery issues were diagnosed during implementation, including:

- Fleet controller connectivity
- Multi-cluster Gateway readiness
- Missing GKE authentication plugin in CI
- HTTPRoute backend port mismatch
- Gateway backend health
- HealthCheckPolicy configuration
- IAM permission failures
- BigQuery CMEK service account configuration
- Logging sink permissions

Detailed troubleshooting scenarios are documented in:

```text
docs/troubleshooting.md
```

---

## Validation

The platform was validated across several layers.

### Application

```bash
curl http://<GLOBAL_IP>/
curl http://<GLOBAL_IP>/health
curl http://<GLOBAL_IP>/slow
curl http://<GLOBAL_IP>/error
```

### Kubernetes

```bash
kubectl get pods -n sre-app
kubectl get service -n sre-app
kubectl get serviceexport -n sre-app
kubectl get serviceimport -n sre-app
```

### Gateway

```bash
kubectl get gateway -n sre-app
kubectl get httproute -n sre-app
kubectl get gatewayclass
```

### Fleet

```bash
gcloud container fleet memberships list
```

### Observability

Verify:

- Grafana request metrics
- Error-rate metrics
- p95 latency
- Alert evaluation
- Managed Prometheus collection

### Log Analytics

Verify:

- BigQuery dataset exists
- Logging sink is active
- Application logs are exported
- SQL queries return recent GKE application logs

---

## Key SRE Concepts Demonstrated

This platform demonstrates:

- Infrastructure as Code
- GitOps-style deployment
- Multi-region Kubernetes
- High availability
- Regional failover
- Service discovery
- Global traffic management
- Metrics
- Logs
- Alerting
- SLI/SLO-oriented monitoring
- Infrastructure security scanning
- Least-privilege IAM
- Centralized log analytics
- Production troubleshooting
