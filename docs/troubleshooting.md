# Troubleshooting Guide

This document summarizes the primary technical issues encountered while building and validating the multi-region GKE platform. It focuses on the symptoms, investigation process, root cause, resolution, and key lessons from each scenario.

---

## 1. Multi-Cluster Gateway Controller Was Not Ready

### Symptom

The Fleet multi-cluster ingress/gateway feature initially reported an unhealthy state, including:

```text
Lost connection
```

The expected multi-cluster GatewayClasses were also not available.

### Investigation

The following areas were reviewed:

- GKE Fleet membership status
- Multi-Cluster Service Discovery
- Multi-cluster ingress/gateway feature state
- Gateway API enablement
- Workload Identity configuration
- Required Google Cloud APIs
- Service-agent IAM permissions

The required APIs included:

- `gkehub.googleapis.com`
- `multiclusteringress.googleapis.com`
- `multiclusterservicediscovery.googleapis.com`
- `trafficdirector.googleapis.com`
- `cloudresourcemanager.googleapis.com`

The multi-cluster Gateway service agent permissions were also validated.

### Resolution

After confirming the required APIs, IAM permissions, and service-agent configuration, the Fleet feature reconciled successfully.

The expected multi-cluster GatewayClasses appeared, including:

```text
gke-l7-global-external-managed-mc
```

The GatewayClass reported:

```text
Accepted=True
```

Fleet ingress then showed both cluster memberships as healthy.

### Key Takeaway

When a GatewayClass is missing, the issue may be with the Fleet control plane or controller readiness rather than the application itself.

Before troubleshooting application routing, verify Fleet status, required APIs, IAM permissions, and Gateway controller health.

---

## 2. GitHub Actions Could Not Authenticate to GKE

### Symptom

The Terraform Apply workflow authenticated successfully to Google Cloud, but `kubectl` commands against the GKE cluster failed.

### Root Cause

The GitHub runner did not have the required GKE authentication plugin installed:

```text
gke-gcloud-auth-plugin
```

Google Cloud authentication alone was not sufficient for `kubectl` to authenticate to GKE.

### Resolution

The workflow was updated to install the GKE authentication plugin and `kubectl`:

```yaml
- name: Set up gcloud
  uses: google-github-actions/setup-gcloud@v2
  with:
    install_components: gke-gcloud-auth-plugin

- name: Set up kubectl
  uses: azure/setup-kubectl@v4
```

After this change, the post-apply verification steps could authenticate to the cluster successfully.

### Key Takeaway

Google Cloud authentication and Kubernetes cluster authentication are related but separate concerns.

A CI runner may be authenticated to Google Cloud while still being unable to use `kubectl` against GKE.

---

## 3. HTTPRoute Used the Wrong Backend Port

### Symptom

The Multi-Cluster Gateway was programmed, but the `HTTPRoute` remained unhealthy.

The route status showed:

```text
ResolvedRefs=False
```

The controller reported that backend port `8080` did not exist on the `ServiceImport`.

### Investigation

The application container listened on port:

```text
8080
```

The Kubernetes Service exposed:

```text
port: 80
targetPort: 8080
```

Because the `ServiceImport` represents the Kubernetes Service, it exposed port `80`, not the container port `8080`.

### Root Cause

The `HTTPRoute` referenced port `8080` instead of the ServiceImport port `80`.

### Resolution

The backend reference was updated to use port `80`:

```yaml
backendRefs:
  - group: net.gke.io
    kind: ServiceImport
    name: sre-observability-app
    port: 80
```

After deployment, the route reported:

```text
Accepted=True
ResolvedRefs=True
Reconciled=True
```

### Key Takeaway

Gateway routing targets the Kubernetes Service abstraction, not the application container port.

The request flow is:

```text
HTTPRoute
   |
   v
ServiceImport port 80
   |
   v
Service port 80
   |
   v
targetPort 8080
   |
   v
Container port 8080
```

---

## 4. Global Endpoint Returned HTTP 500

### Symptom

After correcting the HTTPRoute, the global Gateway was programmed and the route was healthy, but requests to the global endpoint still returned:

```text
500 fault filter abort
```

### Investigation

The application was tested directly from inside the cluster:

```bash
kubectl run curl-test   --rm -it   --restart=Never   --image=curlimages/curl   -n sre-app   -- curl -i http://sre-observability-app/health
```

The internal request returned:

```text
HTTP/1.1 200 OK
```

The following were also verified:

- Pods were Running and Ready
- The Kubernetes Service existed
- Endpoints were available
- Both clusters had healthy application workloads
- The HTTPRoute status was healthy

This narrowed the issue to the load balancer backend health layer.

### Root Cause

The application Service did not have an explicit GKE `HealthCheckPolicy`.

The global Gateway backend therefore did not have the expected health-check configuration for the application.

### Resolution

A `HealthCheckPolicy` was added:

```yaml
apiVersion: networking.gke.io/v1
kind: HealthCheckPolicy
metadata:
  name: sre-observability-healthcheck
  namespace: sre-app
spec:
  default:
    checkIntervalSec: 15
    timeoutSec: 5
    healthyThreshold: 1
    unhealthyThreshold: 2
    config:
      type: HTTP
      httpHealthCheck:
        requestPath: /health
        port: 8080
  targetRef:
    group: ""
    kind: Service
    name: sre-observability-app
```

After deployment:

```bash
curl -i http://<GLOBAL_IP>/health
```

returned:

```text
HTTP/1.1 200 OK
```

The application root endpoint also returned HTTP 200.

### Key Takeaway

A programmed Gateway and a valid route do not necessarily mean the backend is healthy.

Troubleshooting should distinguish between:

```text
Application health
Kubernetes Service health
Gateway route health
Load balancer backend health
```

---

## 5. Regional Failover Validation

### Objective

Validate that the global endpoint continues serving traffic when the primary regional workload becomes unavailable.

### Test

The primary application deployment was scaled to zero replicas:

```bash
kubectl scale deployment sre-observability-app   -n sre-app   --replicas=0
```

After confirming that the primary cluster had no application pods, the same global endpoint was tested:

```bash
curl -i http://<GLOBAL_IP>/health
curl -i http://<GLOBAL_IP>/
```

Both requests continued returning:

```text
HTTP/1.1 200 OK
```

### Result

Traffic continued through the secondary GKE cluster, confirming regional failover through the same global endpoint.

The primary deployment was then restored:

```bash
kubectl scale deployment sre-observability-app   -n sre-app   --replicas=2

kubectl rollout status   deployment/sre-observability-app   -n sre-app   --timeout=5m
```

### Key Takeaway

High availability should be validated through an actual failure test, not only by reviewing configuration.

---

## 6. Terraform Apply Failed While Creating the KMS Key Ring

### Symptom

Terraform failed with:

```text
Permission 'cloudkms.keyRings.create' denied
```

### Root Cause

The Terraform deployment service account did not have permission to create Cloud KMS key rings.

### Resolution

The deployment service account was granted:

```text
roles/cloudkms.admin
```

A documented Checkov suppression was added because this role is intentionally assigned to the infrastructure deployment identity:

```hcl
# checkov:skip=CKV_GCP_42:Terraform deployment service account requires KMS administration to provision and manage CMEK resources
```

### Key Takeaway

A successful `terraform validate` or `terraform plan` does not guarantee that the deployment identity has all runtime cloud permissions required by `terraform apply`.

Some authorization failures are only discovered when Terraform calls the cloud provider API.

---

## 7. BigQuery CMEK Encryption Service Account Did Not Exist

### Symptom

Terraform failed while attempting to grant KMS access to:

```text
bq-<PROJECT_NUMBER>@bigquery-encryption.iam.gserviceaccount.com
```

Google Cloud reported that the service account did not exist.

### Investigation

The dedicated BigQuery encryption service account had not yet been initialized.

### Resolution

The encryption service account was initialized with:

```bash
bq show   --encryption_service_account   --project_id=mohan-sre-assessment-20261001
```

The command returned:

```text
bq-588368134250@bigquery-encryption.iam.gserviceaccount.com
```

Terraform then used the service account in the KMS IAM binding:

```hcl
member = "serviceAccount:bq-${data.google_project.current.number}@bigquery-encryption.iam.gserviceaccount.com"
```

### Key Takeaway

Some Google-managed service identities are created only when the related service functionality is first used.

Enabling an API does not always guarantee that every service-specific identity already exists.

---

## 8. BigQuery Dataset Creation Permission Was Missing

### Symptom

Terraform failed with:

```text
bigquery.datasets.create permission denied
```

### Root Cause

The Terraform deployment service account did not have permission to create BigQuery datasets.

### Resolution

The deployment service account was granted:

```text
roles/bigquery.user
```

The dataset resource was configured to depend on that IAM grant.

### Key Takeaway

Terraform Plan shows intended infrastructure changes, but it does not guarantee that the deployment identity can perform every create, update, or delete operation.

Where practical, required IAM permissions should be validated before Apply.

---

## 9. Logging Sink Creation Permission Was Missing

### Symptom

Terraform failed with:

```text
logging.sinks.create permission denied
```

### Root Cause

The Terraform deployment service account did not have permission to create and manage Cloud Logging sinks.

### Resolution

The deployment service account was granted:

```text
roles/logging.configWriter
```

Terraform could then create the logging sink successfully.

### Key Takeaway

The identity that creates a logging sink and the identity used by that sink to write logs are different.

```text
Terraform deployment service account
        |
        | creates sink
        v
Cloud Logging Sink
        |
        | generated writer identity
        v
BigQuery Dataset
```

The deployment identity needs permission to manage the sink, while the sink writer identity needs permission to write to BigQuery.

---

## 10. Logging Sink Writer Access to BigQuery

The logging sink was configured with:

```hcl
unique_writer_identity = true
```

Google Cloud generated a dedicated writer identity for the sink.

That identity was granted:

```text
roles/bigquery.dataEditor
```

on the `sre_logs` dataset.

Terraform configuration:

```hcl
resource "google_bigquery_dataset_iam_member" "sre_logs_writer" {
  project    = var.project_id
  dataset_id = google_bigquery_dataset.sre_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.sre_app_logs.writer_identity
}
```

### Key Takeaway

Deployment permissions and runtime data-access permissions should be assigned to separate identities where possible.

This keeps responsibilities clear and supports least-privilege access.

---

## 11. Terraform CI and Apply Were Running Duplicate Checks

### Symptom

Manual Terraform Apply runs repeated several validation and security checks that had already completed during pull request validation:

- Terraform Format
- TFLint
- Checkov
- ShellCheck
- Terraform Plan

### Resolution

The workflow was separated into two execution paths.

### Pull Request / Push Validation

```text
Terraform Format
Terraform Validate
TFLint
Checkov
ShellCheck
Terraform Plan
```

### Manual Apply

```text
Authenticate
Terraform Init
Terraform Apply
Post-Apply Verification
```

The CI job is skipped for manual runs using:

```yaml
if: github.event_name != 'workflow_dispatch'
```

The Apply job remains restricted to manual execution from the `main` branch.

### Key Takeaway

Validation and deployment should be separate pipeline stages.

Pull requests should perform code quality, security, and plan checks before merge. Manual deployment should remain focused on applying the approved change and verifying the result.

---

## Troubleshooting Approach

A consistent troubleshooting approach was used throughout the implementation:

```text
1. Identify the failing layer
2. Review status and error messages
3. Verify dependencies
4. Test the simplest working path
5. Change one variable at a time
6. Re-run validation
7. Confirm the final behavior
```

For Kubernetes and multi-cluster issues, troubleshooting generally followed this path:

```text
Application
    |
    v
Pod
    |
    v
Service
    |
    v
ServiceExport / ServiceImport
    |
    v
HTTPRoute
    |
    v
Gateway
    |
    v
Global Load Balancer
```

For Terraform issues:

```text
Terraform Configuration
        |
        v
Terraform Validate
        |
        v
Terraform Plan
        |
        v
Cloud IAM / API Permissions
        |
        v
Terraform Apply
        |
        v
Post-Apply Verification
```

---

## Key Lessons

- A healthy Pod does not guarantee a healthy global endpoint.
- A programmed Gateway does not guarantee that its backends are healthy.
- Kubernetes Service ports and container ports serve different purposes.
- Some cloud service identities are created only when required.
- Terraform Plan does not fully validate runtime IAM permissions.
- Deployment identities and runtime service identities should be separated.
- Multi-region failover should be tested by intentionally removing a regional backend.
- CI validation should happen before merge, while deployment workflows should remain focused on deployment and verification.
