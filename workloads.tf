data "ncloud_nks_kube_config" "kube_config" {
  cluster_uuid = ncloud_nks_cluster.terraform_cluster.uuid
}

resource "null_resource" "create_kubeconfig" {
  depends_on = [ncloud_nks_cluster.terraform_cluster]

  provisioner "local-exec" {
    command = "ncp-iam-authenticator update-kubeconfig --clusterUuid ${self.triggers.cluster_uuid} --region ${self.triggers.region}"

    environment = {
      CLUSTER_UUID = data.ncloud_nks_kube_config.kube_config.cluster_uuid
      REGION       = "KR"
    }
  }
  triggers = {
    cluster_uuid = data.ncloud_nks_kube_config.kube_config.cluster_uuid
    region       = "KR"
  }
}

resource "kubernetes_pod" "nginx" {
  metadata {
    name = "nginx-example"
    labels = {
      app = "nginx"
    }
  }

  spec {
    container {
      image = "nginx:latest"
      name  = "nginx"

      port {
        container_port = 80
      }
    }
  }
}

resource "kubernetes_service" "nginx_public" {
  metadata {
    name = "nginx-service-public"

    annotations = {
      "service.beta.kubernetes.io/ncloud-load-balancer-internal" = "false"
    }
  }

  spec {
    selector = {
      app = kubernetes_pod.nginx.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "nginx_private" {
  metadata {
    name = "nginx-service-private"

    annotations = {
      "service.beta.kubernetes.io/ncloud-load-balancer-internal" = "true"
    }
  }

  spec {
    selector = {
      app = kubernetes_pod.nginx.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
