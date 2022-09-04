# Installing-the-Istio-on-GKE-Add-On-with-Kubernetes-Engine

This project demonstrates the infrastructure provisioning of an Istio based app.
It uses Terraform to automate the provisioning of Google Cloud Platform resources, and GitHub Actions for CI/CD.
The app being deployed is https://istio.io/latest/docs/examples/bookinfo/

## Set up Google Cloud Platform

On Google Cloud Platform IAM Roles admin page https://console.cloud.google.com/iam-admin/roles, create
a new role with these permissions:
```
compute.instanceGroupManagers.get
container.clusters.create
container.clusters.delete
container.clusters.get
container.clusters.list
container.clusters.update
container.configMaps.get
container.deployments.create
container.deployments.get
container.deployments.update
container.operations.get
container.pods.exec
container.pods.get
container.pods.list
container.serviceAccounts.create
container.serviceAccounts.get
container.services.create
container.services.get
container.services.list
container.thirdPartyObjects.create
container.thirdPartyObjects.get
container.thirdPartyObjects.list
iam.serviceAccounts.actAs
iam.serviceAccounts.get
storage.objects.create
storage.objects.delete
storage.objects.get
storage.objects.list
```
Create a new IAM service account, assign the new role to the service account. Download the service account JSON

## Set up GitHub Actions

On GitHub Actions, some environment variable values needs to be specified. 
On your own repository (you can fork this repsitory), Open the `/settings/secrets/actions`, create these variables and don't forget to set the values:
* `GCP_CLUSTER_NAME`. THe name of the Kubernetes nodes cluster to be created on GCP
* `GCP_CLUSTER_NUM_NODES`. The number of machine nodes to be created on GCP
* `GCP_CLUSTER_VERSION`. The cluster version, for example, `1.22.11-gke.400`
* `GCP_CLUSTER_ZONE`. The GCP data center to be used, for example, `us-central1-a`
* `GCP_PROJECT_ID`
* `GCP_SA_KEY`. The content of the Service account JSON you have downloaded on the previous step.
* `GCP_VM_MACHINE_TYPE`. For example, `e2-medium`
* `GCS_BUCKET`. The cloud storage bucket to store Terraform state.
* `GCS_PATH_PREFIX`. The path in cloud storage to store Terraform state. For example, `/state/istio-gke`

## Accessing GCP from local machine

You will need to be able to access GCP from your local machine, because in the end you will need to trigger
the deletion of the infrastructure from your local machine.
You need to install `gcloud` and `terraform` command line tools.

Once you have installed the CLI tools, login to GCP using the service account JSON:
```
gcloud activate-service-account --key-file <THE SERVICE ACCOUNT JSON FILE>
```

Initialize Terraform:
```
make terraform-init
```

Now you can trigger the infrastructure provisioning from your local machine:
```
make terraform-apply
```

Once the infrastructure provisioning is done, you can also try the deployment from your local machine by
following the steps in `.github/workflows/build-push-deploy.yaml`:
```
make get-cluster-credentials
make install-istio
make deploy-bookinfo-backends
make deploy-bookinfo-gateway
```
See the example on how to access the Bookinfo app by running `make access-external-ip`.
You can copy the displayed URL and paste it to a web browser.

## Destroy the infrastructure

Once you finished your experiment, you want to stop GCP from charging you. Run this command:
```
make terraform-destroy
```