# Deploy a privacy-focused AI assistant

Build a healthcare AI assistant that ensures your large language model has multiple layers of protection, including PII detection and content moderation.

> This fork adapts the original [rh-ai-quickstart/guardrailing-llms](https://github.com/rh-ai-quickstart/guardrailing-llms) quickstart to **Red Hat OpenShift AI 3.x**. See [Changes for OpenShift AI 3.x](#changes-for-openshift-ai-3x).

## Detailed description 

This quickstart includes a healthcare AI assistant demo showing how
guardrails could help protect HIPAA-compliant applications.

The demo tests a patient services AI with four protection layers:
1. **PII Detection** - Protects Social Security Numbers and email addresses
2. **Content Moderation** - Blocks inappropriate language  
3. **Prompt Injection Protection** - Prevents system manipulation
4. **Gibberish Detection** - Filters out nonsense queries

For example, here's how PII detection works in action:

![diagram.png](docs/images/wb0.png)

Explore the complete interactive demo in `docs/healthcare-guardrails.ipynb`.

The LLM Guardrails quickstart is a quick-start template for deploying multiple layers of protection for LLM applications using TrustyAI's orchestrator and specialized detector services.

This quickstart includes a Helm chart for deploying:

- A Llama 3.2 3B Instruct model with GPU acceleration.
- Multiple AI safety detectors: regex (PII), gibberish detection, prompt injection detection, and hate/profanity detection.
- TrustyAI GuardrailsOrchestrator for coordinating safety checks.
- A Jupyter workbench with this repository already cloned.
- Configurable detection thresholds and routing policies.

<!-- ## Arcade demo -->

<!-- Short on time or don't have an environment? No problem! Try our step-by-step Arcade Demo for a guided walkthrough. -->

<!-- *Coming soon* -->

### Architecture diagrams

![architecture.png](docs/images/architecture.png)


## Requirements 

### Recommended hardware requirements 

- GPU required for main LLM: +24GiB vRAM
- CPU cores: 12+ cores total (4 for LLM + 8 for detectors)
- Memory: 24Gi+ RAM total
- Storage: 10Gi

### Minimum hardware requirements 

- GPU required for main LLM: 1 x NVIDIA GPU with 24GiB vRAM (e.g. NVIDIA L4 or A10G)
- CPU cores: 8+ cores total
- Memory: 16Gi+ RAM total
- Storage: 5Gi 

### Minimum software requirements

- Red Hat OpenShift AI 3.x (tested on 3.5.0)
    - `kserve` and `trustyai` components set to `Managed` in the DataScienceCluster
- NVIDIA GPU Operator with at least one **free** GPU

Check the components with:

```bash
oc get datasciencecluster -o jsonpath='{.items[0].spec.components.trustyai.managementState}{"\n"}{.items[0].spec.components.kserve.managementState}{"\n"}'
```

### Required user permissions

- Cluster admin permissions are required

## Install

The commands below can be run from your machine (with `oc` and `helm` installed) or from the OpenShift **Web Terminal**, which already includes both tools.

### Clone the repository

```bash
git clone https://github.com/nhermida-rh/guardrailing-llms.git && cd guardrailing-llms/
```

### Create a new project

```bash
PROJECT="guardrails-demo"

oc new-project ${PROJECT}
``` 

### Install with Helm

```bash
helm install ${PROJECT} helm/ --namespace ${PROJECT}
```

That's it: models, detectors, orchestrator and workbench are created by this single command.

### Wait for the pods to be ready

```bash
oc get pod -n ${PROJECT}
```

The LLM can take 5-15 minutes the first time while the model image is downloaded. You should see an output similar to:
<pre>
NAME                                                         READY   STATUS    RESTARTS   AGE
gibberish-detector-predictor-747d584d9c-n89nd                3/3     Running   0          9m
gorch-sample-7c58ccbb58-2vd5k                                2/2     Running   0          9m
guardrails-workbench-0                                       2/2     Running   0          9m
ibm-hate-and-profanity-detector-predictor-656ccfbb4f-5w2t7   3/3     Running   0          9m
llama-32-3b-instruct-predictor-d77c7787c-wssmv               3/3     Running   0          9m
prompt-injection-detector-predictor-6997fc8d67-hbqnl         3/3     Running   0          9m
regex-detector-7c5ccd89b-vg848                               1/1     Running   0          9m
</pre>

### Test

Open the OpenShift AI dashboard (from the OpenShift console, use the application launcher → **Red Hat OpenShift AI**) and navigate to **Projects** → `guardrails-demo` (or the name you used for `${PROJECT}`).

![OpenShift AI Projects](docs/images/wb1.png)

Inside the project, open the **Workbenches** tab and open `guardrails-workbench`.

![OpenShift AI WB](docs/images/wb2.png)

Inside Jupyter you'll see the `guardrailing-llms` repository already cloned. Open `docs/healthcare-guardrails.ipynb` and run the cells. The notebook detects the project it runs in, so no configuration changes are needed.

![OpenShift AI Jupyter Notebook](docs/images/wb3.png)

Enjoy!

### Delete

```bash
helm uninstall ${PROJECT} --namespace ${PROJECT}
```

## Configuration

Useful values (see `helm/values.yaml` for all of them), passed with `--set`:

| Value | Default | Description |
|---|---|---|
| `workbench.enabled` | `true` | Create the Jupyter workbench |
| `workbench.image.tag` | `""` | Workbench image tag. Empty = use the tag marked as recommended by OpenShift AI |
| `workbench.gitRepo.url` / `branch` | this fork / `main` | Repository cloned into the workbench |
| `detectors.regex.patterns` | `email`, `us-social-security-number` | PII patterns checked by the regex detector |
| `detectors.useGpu` | `false` | Run the HF detectors on GPU |
| `mainLLM.tolerations` | `nvidia.com/gpu=True:NoSchedule` | Adjust if your GPU nodes use a different taint |

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `no matches for kind "GuardrailsOrchestrator"` | The `trustyai` component is not `Managed` in the DataScienceCluster |
| LLM pod `Pending` with `Insufficient nvidia.com/gpu` | The GPU is used by another model. Find it with `oc get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"  "}{.metadata.name}{"  "}{.spec.containers[*].resources.requests.nvidia\.com/gpu}{"\n"}{end}' \| awk 'NF>=3'` and stop it from the OpenShift AI dashboard |
| Notebook returns `Orchestrator returned error status 500` | Check the orchestrator logs: `oc logs -n ${PROJECT} deploy/gorch-sample -c gorch-sample --tail=50` |

## Changes for OpenShift AI 3.x

Compared to the original quickstart (tested on OpenShift AI 2.23):

- **PII detector**: the built-in detector sidecar shipped with OpenShift AI 3.5 (`odh-built-in-detector-rhel9`) fails to start with `ModuleNotFoundError: No module named 'regex'`. The chart disables it (`enableBuiltInDetectors: false`) and deploys the upstream TrustyAI built-in detector as a standalone `regex-detector` Deployment/Service.
- **SSN pattern**: that detector names the SSN pattern `us-social-security-number`; the previous `ssn` value was silently ignored.
- **Detector and LLM ports**: KServe RawDeployment predictor Services are headless in 3.x, so the orchestrator targets the container ports (8000 for detectors, 8080 for vLLM) directly.
- **Workbench**: uses the 3.x `notebooks.opendatahub.io/inject-auth` annotation (kube-rbac-proxy), picks the recommended `s2i-minimal-notebook` image tag automatically, and clones the repository with an init container instead of a Job with `pods/exec` permissions.
- **Notebook**: reads the project name from the workbench service account, so the demo works in any namespace.
- Removed the unused `gorch-regex-gateway-image-config` ConfigMap and the `clusterdomainurl` value.

## References 

- [Red Hat documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.23/html/monitoring_data_science_models/configuring-the-guardrails-orchestrator-service_monitor)


## Tags 

* **Industry:** Healthcare
* **Product:** OpenShift AI 
* **Use case:** PII detection 
