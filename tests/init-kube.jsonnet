local kube = import "../kube.libsonnet";

local crds = {
  // A simplified VPA CRD from https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler
  vpa_crd: kube.CustomResourceDefinition("autoscaling.k8s.io", "v1beta1", "VerticalPodAutoscaler") {
    metadata+: {
      annotations: {
        "api-approved.kubernetes.io": "https://github.com/kubernetes/kubernetes/pull/78458",
      },
    },
    spec+: {
      versions_+: {
        v1beta2: self.default_spec { storage: false },
      },
    },
  },
  // Simplified cert-manager CRD from https://github.com/jetstack/cert-manager/blob/master/deploy/crds/crd-certificates.yaml,
  // enough to test bitnami.CertManager object(s)
  cm_certificate_crd: kube.CustomResourceDefinition("cert-manager.io", "v1alpha2", "Certificate"),
};

crds
