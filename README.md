# Hosted Control Planes (HyperShift) — libvirt/BM Tekton CI

This branch (`patterns-libvirt-tekton`) installs **OpenShift Pipelines (Tekton)** and the secrets stack on an **existing** HyperShift hosted cluster. It does **not** install Multicluster Engine, does **not** create another hosted cluster, and does **not** use AWS.

Use it when:

- A hub OpenShift cluster already runs MCE + HyperShift
- A hosted cluster already exists (here: `hcptest-0` on libvirt VMs)
- You want to install Tekton on that hosted cluster

## What `./patterns.sh make install` deploys

On the hosted cluster (default kubeconfig):

| Component | Purpose |
| --- | --- |
| OpenShift GitOps | Pattern / Argo CD install |
| OpenShift Pipelines | Tekton operator |
| `pipelines-rbac` | ClusterRole/binding + `ci-users` group |
| HashiCorp Vault | Secrets backend |
| External Secrets Operator | Sync Vault → cluster secrets |
| HTPasswd OAuth | Lab users from `users.htpasswd` |
| Local storage | Static hostPath PVs (`lab-hostpath`) for Vault and pipeline workspaces |

Explicitly **skipped**: MCE, HyperShift config, `hcp` CLI build, AWS credentials/IAM, S3 OIDC bucket, cluster-autoscaler, Let’s Encrypt (Route53), kubelet MachineConfig, ACM managed-cluster groups, AWS cluster-provisioning pipelines.

## Prerequisites

- Hub kubeconfig: `/home/kni/clusterconfigs/auth/kubeconfig`
- Hosted cluster kubeconfig: `/home/kni/clusterconfigs/hcptest-0/auth/kubeconfig` (default target)
- HTPasswd file: `/home/kni/clusterconfigs/users.htpasswd`
- Pull secret (optional, loaded into Vault): `/home/kni/clusterconfigs/pull-secret.json`
- `podman` (used by `pattern.sh` / `patterns.sh`)
- This git branch must be **pushed** to the origin Argo CD will clone (`TARGET_BRANCH` defaults to the current branch)

Copy the secrets template (never commit the copy):

```sh
cp values-secret.yaml.template $HOME/values-secret-hypershift.yaml
```

Paths in the template already point at this lab’s clusterconfigs files.

## Install

```sh
cd hypershift
git checkout patterns-libvirt-tekton
# Push the branch so in-cluster GitOps can clone it
# git push -u origin patterns-libvirt-tekton

./patterns.sh make install
```

`make install` always uses the hosted-cluster kubeconfig (`/home/kni/clusterconfigs/hcptest-0/auth/kubeconfig`), even if your shell exported the hub kubeconfig. To target the hub instead (not typical for this branch):

```sh
INSTALL_KUBECONFIG=/home/kni/clusterconfigs/auth/kubeconfig ./patterns.sh make install
```

On platform `None` (hosted cluster), `values-None.yaml` enables local PVs on workers `hcptest-worker-0-0` and `hcptest-worker-0-1`. If node names differ, edit `values-None.yaml` and `overrides/values-None.yaml`.

On platform `BareMetal` (the hub), local storage is disabled because `hostpath-csi` already exists.

## After install

- Console login: HTPasswd users `demouser1` … `demouser5` (see `users.spec` for passwords)
- Group `ci-users` is bound to `openshift-pipelines-tekton-admin`
- Create Pipeline / PipelineRun objects in `vp-qe-ci` or any namespace
- Workspace PVCs should use StorageClass `lab-hostpath` (default on the hosted cluster)

## Optional: GitHub OAuth instead of HTPasswd

1. Uncomment `oauthCreds` / `githubGroupSync` in `~/values-secret-hypershift.yaml`
2. Set `global.oauth.type: GitHub` and `secretName: ocp-github-oauth` in `values-hypershift.yaml`
3. Enable the `groupsync` subscription and application in `values-prod.yaml`

## Original AWS HyperShift pattern

The `patterns` branch still installs MCE, HyperShift, S3 OIDC, and AWS cluster-provisioning pipelines. This branch is a lab overlay of that work for an already-running libvirt/BM hosted cluster.
