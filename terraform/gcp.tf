provider "google-beta" {
  project = var.gcp_project_id
  zone = var.gcp_cluster_zone
}

data "google_service_account" "default" {
  provider = google-beta
  account_id = var.gcp_service_account_id
}

resource "google_container_cluster" "default" {
  provider = google-beta
  name = var.gcp_cluster_name

  min_master_version = var.gcp_cluster_version
  addons_config {
    istio_config {
      disabled = false
      auth = "AUTH_MUTUAL_TLS"
    }
  }

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "default_preemptible" {
  provider = google-beta
  cluster    = google_container_cluster.default.name
  node_count = var.gcp_cluster_num_nodes

  node_config {
    image_type = "COS_CONTAINERD"
    preemptible  = true
    machine_type = var.gcp_vm_machine_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = data.google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}