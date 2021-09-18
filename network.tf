resource "google_compute_network" "k8s" {
  name                    = var.network["name"]
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "k8s" {
  name          = "k8s-${var.region}"
  network       = google_compute_network.k8s.self_link
  ip_cidr_range = var.network["iprange"]
  region        = var.region
}

resource "google_compute_address" "controllers" {
  count        = var.number_of_controller
  name         = "controller-${count.index}"
  subnetwork   = google_compute_subnetwork.k8s.self_link
  address_type = "INTERNAL"
  region       = var.region
  address      = "${var.network["prefix"]}.1${count.index}"
}

resource "google_compute_address" "workers" {
  count        = var.number_of_worker
  name         = "worker-${count.index}"
  subnetwork   = google_compute_subnetwork.k8s.self_link
  address_type = "INTERNAL"
  region       = var.region
  address      = "${var.network["prefix"]}.2${count.index}"
}

##############  FIREWALS  #######################
resource "google_compute_firewall" "k8s-allow-internal" {
  name          = "k8s-allow-internal"
  network       = google_compute_network.k8s.name
  source_ranges = ["${var.network["iprange"]}", "10.200.0.0/16"]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}


# resource "google_compute_firewall" "k8s-allow-rdp" {
#   name          = "k8s-allow-rdp"
#   network       = "${google_compute_network.k8s.name}"
#   source_ranges = ["0.0.0.0/0"]

#   allow {
#     protocol = "tcp"
#     ports    = ["3389"]
#   }
# }

resource "google_compute_firewall" "k8s-allow-ssh" {
  name          = "k8s-allow-ssh"
  network       = google_compute_network.k8s.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "k8s-allow-api-server" {
  name          = "k8s-allow-api-server"
  network       = google_compute_network.k8s.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
}

resource "google_compute_firewall" "k8s-allow-healthz" {
  name          = "k8s-allow-healthz"
  network       = google_compute_network.k8s.name
  source_ranges = ["209.85.152.0/22", "209.85.204.0/22"]

  allow {
    protocol = "tcp"
    ports    = ["8080", "80", "${var.kube_api_port}"]
  }
}

resource "google_compute_health_check" "k8s-health-check-with-ssl" {
  name = "k8s-health-check-with-ssl"

  https_health_check {
    host         = "k8s.default.svc.cluster.local"
    request_path = "/healthz"
    port         = var.kube_api_port
  }
}
resource "google_compute_health_check" "k8s-health-check" {
  name = "k8s-health-check-without-ssl"

  http_health_check {
    host         = "k8s.default.svc.cluster.local"
    request_path = "/healthz"
    port         = var.kube_api_port
  }
}

resource "google_compute_address" "k8s" {
  name = "k8s"
}

resource "google_compute_target_pool" "k8s" {
  name = "k8s-pool"
  instances = [
    "${var.region}-${var.zones[0]}/controller-0",
    "${var.region}-${var.zones[0]}/controller-1",
    "${var.region}-${var.zones[0]}/controller-2",
  ]
  health_checks = [
    #    "${google_compute_health_check.k8s-health-check-with-ssl.name}",
  ]
}

resource "google_compute_forwarding_rule" "k8s" {
  project               = var.project_id
  name                  = "kube-forward"
  ip_address            = google_compute_address.k8s.address
  target                = google_compute_target_pool.k8s.self_link
  load_balancing_scheme = "EXTERNAL"
  port_range            = var.kube_api_port
}