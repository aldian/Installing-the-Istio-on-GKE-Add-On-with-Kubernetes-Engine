export ISTIO_DIR := /home/runner/work/Installing-the-Istio-on-GKE-Add-On-with-Kubernetes-Engine/Installing-the-Istio-on-GKE-Add-On-with-Kubernetes-Engine/istio-$(ISTIO_VERSION)
export PATH := $(ISTIO_DIR)/bin:$(PATH)

check-env:
ifndef ENV
	$(error Please set ENV=[staging|prod])
endif

get-cluster-credentials: check-env
	gcloud container clusters get-credentials $(GCP_CLUSTER_NAME) --zone $(GCP_CLUSTER_ZONE) --project $(GCP_PROJECT_ID)

check-cluster: check-env
	gcloud container clusters list

check-istio-services: check-env
	kubectl get service -n istio-system

check-istio-pods: check-env
	kubectl get pods -n istio-system

install-istio: check-env
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$(ISTIO_VERSION) sh -
	istioctl x precheck
	istioctl version

display-bookinfo-original-yaml: check-env
	cat $(ISTIO_DIR)/samples/bookinfo/platform/kube/bookinfo.yaml

update-bookinfo-yaml: check-env
	istioctl kube-inject -f $(ISTIO_DIR)/samples/bookinfo/platform/kube/bookinfo.yaml

deploy-bookinfo-backends: check-env
	istioctl kube-inject -f $(ISTIO_DIR)/samples/bookinfo/platform/kube/bookinfo.yaml > /tmp/bookinfo.yaml
	kubectl apply -f /tmp/bookinfo.yaml

display-bookinfo-gateway-original-yaml: check-env
	cat $(ISTIO_DIR)/samples/bookinfo/networking/bookinfo-gateway.yaml

deploy-bookinfo-gateway: check-env
	kubectl apply -f $(ISTIO_DIR)/samples/bookinfo/networking/bookinfo-gateway.yaml

get-services: check-env
	kubectl get services

get-pods: check-env
	kubectl get pods

access-products-from-ratings: check-env
	kubectl exec -it $(shell kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') \
		-c ratings -- curl productpage:9080/productpage | grep -o ".*"

get-gateway: check-env
	kubectl get gateway

get-external-ip: check-env
	kubectl get svc istio-ingressgateway -n istio-system

access-external-ip: check-env
	curl -I http://$(shell kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='' -o jsonpath='{..ip}')/productpage

terraform-init: check-env
	cd terraform && \
		terraform init \
  		-backend-config="bucket=$(GCS_BUCKET)" \
  		-backend-config="prefix=$(GCS_PATH_PREFIX)" && \
  		(terraform workspace select $(ENV) || terraform workspace new $(ENV)) && \
		terraform init \
  		-backend-config="bucket=$(GCS_BUCKET)" \
  		-backend-config="prefix=$(GCS_PATH_PREFIX)" \

terraform-apply: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform apply -auto-approve \
		-var="gcp_project_id=$(GCP_PROJECT_ID)" \
		-var="gcp_vm_machine_type=$(GCP_VM_MACHINE_TYPE)" \
		-var="gcp_cluster_name=$(GCP_CLUSTER_NAME)" \
		-var="gcp_cluster_zone=$(GCP_CLUSTER_ZONE)" \
		-var="gcp_cluster_version=$(GCP_CLUSTER_VERSION)" \
		-var="gcp_cluster_num_nodes=$(GCP_CLUSTER_NUM_NODES)"

terraform-destroy: check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform destroy -auto-approve -lock=false \
		-var="gcp_project_id=$(GCP_PROJECT_ID)" \
		-var="gcp_vm_machine_type=$(GCP_VM_MACHINE_TYPE)" \
		-var="gcp_cluster_name=$(GCP_CLUSTER_NAME)" \
		-var="gcp_cluster_zone=$(GCP_CLUSTER_ZONE)" \
		-var="gcp_cluster_version=$(GCP_CLUSTER_VERSION)" \
		-var="gcp_cluster_num_nodes=$(GCP_CLUSTER_NUM_NODES)"
