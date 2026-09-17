# Hosted Control Planes (HyperShift) — libvirt/BM Tekton CI

This branch (`patterns-libvirt-tekton`) installs **OpenShift Pipelines (Tekton)** and the secrets stack on the **existing BM hub** (hosting / management cluster). That matches the upstream `patterns` branch: Tekton runs on the hub. It does **not** install Multicluster Engine, does **not** create another hosted cluster, and does **not** use AWS.

Use it when:

- A hub OpenShift cluster already runs MCE + HyperShift
- A hosted cluster may already exist; this pattern will not create or reinstall it
- You to install Tekton on the hub

## What `./patterns.sh make install` deploys

On the hub (default kubeconfig):

| Component | Purpose |
| --- | --- |
| OpenShift GitOps | Pattern / Argo CD install |
| OpenShift Pipelines | Tekton operator |
| `pipelines-rbac` | ClusterRole/binding + `ci-users` group |
| HashiCorp Vault | Secrets backend |
| External Secrets Operator | Sync Vault → cluster secrets |
| HTPasswd OAuth | Lab users from `users.htpasswd` |

Explicitly **skipped**: MCE, HyperShift config, `hcp` CLI build, AWS credentials/IAM, S3 OIDC bucket, cluster-autoscaler, Let’s Encrypt (Route53), kubelet MachineConfig, ACM managed-cluster groups, AWS cluster-provisioning pipelines (those would create hosted clusters).

Storage uses the hub’s existing `hostpath-csi` default StorageClass.

## Prerequisites

- Hub kubeconfig (default target): `/home/kni/clusterconfigs/auth/kubeconfig`
- HTPasswd file: `/home/kni/clusterconfigs/users.htpasswd`
- Pull secret (optional, loaded into Vault): `/home/kni/clusterconfigs/pull-secret.json`
- `podman` (used by `pattern.sh` / `patterns.sh`)
- This git branch must be **pushed** to the origin Argo CD will clone (`TARGET_BRANCH` defaults to the current branch)

Copy the secrets template if it is not already present (never commit the copy):

```sh
cp values-secret.yaml.template $HOME/values-secret-hypershift.yaml
```

## Install

```sh
cd hypershift
git checkout patterns-libvirt-tekton
# Push the branch so in-cluster GitOps can clone it
# git push -u origin patterns-libvirt-tekton

./patterns.sh make install
```

`make install` always uses the hub kubeconfig (`/home/kni/clusterconfigs/auth/kubeconfig`). To point at the hosted cluster instead (not the default):

```sh
INSTALL_KUBECONFIG=/home/kni/clusterconfigs/hcptest-0/auth/kubeconfig ./patterns.sh make install
```

Guest OAuth CRs cannot be patched on a hosted cluster; `values-None.yaml` disables the oauth app in that case.

## After install

- Console login: HTPasswd users `demouser1` … `demouser5` (see `users.spec` for passwords)
- Group `ci-users` is bound to `openshift-pipelines-tekton-admin`
- Create Pipeline / PipelineRun objects in `vp-qe-ci` or any namespace
- Workspace PVCs use the hub default StorageClass (`hostpath-csi`)

## Optional: GitHub OAuth instead of HTPasswd

1. Uncomment `oauthCreds` / `githubGroupSync` in `~/values-secret-hypershift.yaml`
2. Set `global.oauth.type: GitHub` and `secretName: ocp-github-oauth` in `values-hypershift.yaml`
3. Enable the `groupsync` subscription and application in `values-prod.yaml`

## Original AWS HyperShift pattern

The `patterns` branch still installs MCE, HyperShift, S3 OIDC, and AWS cluster-provisioning pipelines on a hub. This branch keeps that hub-side Tekton model but skips MCE/HyperShift/AWS because the lab hub and hosted cluster already exist.
