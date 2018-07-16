// Generic stuff is in kube.libsonnet - this file contains
// additional AWS or Bitnami -specific conventions.

local kube = import "kube.libsonnet";

local perCloudSvcAnnotations(cloud, internal, service) = (
  {
    aws: {
      "service.beta.kubernetes.io/aws-load-balancer-connection-draining-enabled": "true",
      "service.beta.kubernetes.io/aws-load-balancer-connection-draining-timeout": std.toString(service.target_pod.spec.terminationGracePeriodSeconds),
      // Use PROXY protocol (nginx supports this too)
      "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol": "*",
      // Does LB do NAT or DSR? (OnlyLocal implies DSR)
      // https://kubernetes.io/docs/tutorials/services/source-ip/
      // NB: Don't enable this without modifying set-real-ip-from above!
      // Not supported on aws in k8s 1.5 - immediate close / serves 503s.
      //"service.beta.kubernetes.io/external-traffic": "OnlyLocal",
    },
    gke: {},
  }[cloud] + if internal then {
    aws: {
      "service.beta.kubernetes.io/aws-load-balancer-internal": "0.0.0.0/0",
    },
    gke: {
      "cloud.google.com/load-balancer-type": "internal",
    },
  }[cloud] else {}
);

local perCloudSvcSpec(cloud) = (
  {
    aws: {},
    // Required to get real src IP address, which also allows proper
    // ingress.kubernetes.io/whitelist-source-range matching
    gke: { externalTrafficPolicy: "Local" },
  }[cloud]
);

{
  ElbService(name, cloud, internal): kube.Service(name) {
    local service = self,

    metadata+: {
      annotations+: perCloudSvcAnnotations(cloud, internal, service),
    },
    spec+: { type: "LoadBalancer" } + perCloudSvcSpec(cloud),
  },

  Ingress(name): kube.Ingress(name) {
    local ing = self,

    host:: error "host required",
    target_svc:: error "target_svc required",
    // Default to single-service - override if you want something else.
    paths:: [{ path: "/", backend: ing.target_svc.name_port }],
    secretName:: "%s-cert" % [ing.metadata.name],
    // cert_provider can either be:
    // - "internal": uses route53 for ACME dns-01 challenge
    // - "external": requires public ingress, uses http01 for ACME http challenge
    cert_provider:: "internal",

    cert_internal_metadata:: {
      annotations+: {
        "certmanager.k8s.io/cluster-issuer": "letsencrypt-prod-dns",
        "certmanager.k8s.io/acme-challenge-type": "dns01",
        "certmanager.k8s.io/acme-dns01-provider": "default",
      },
    },
    cert_external_metadata:: {
      annotations+: {
        "certmanager.k8s.io/cluster-issuer": "letsencrypt-prod-http",
      },
    },

    metadata+: if ing.cert_provider == "internal" then ing.cert_internal_metadata else ing.cert_external_metadata,
    spec+: {
      tls: [
        {
          hosts: std.set([r.host for r in ing.spec.rules]),
          secretName: ing.secretName,

          assert std.length(self.hosts) <= 1 : "cert-manager only supports one host per secret - make a separate Ingress resource",
        },
      ],

      rules: [
        {
          host: ing.host,
          http: {
            paths: ing.paths,
          },
        },
      ],
    },
  },

  PromScrape(port): {
    local scrape = self,
    prom_path:: "/metrics",

    metadata+: {
      annotations+: {
        "prometheus.io/scrape": "true",
        "prometheus.io/port": std.toString(port),
        "prometheus.io/path": scrape.prom_path,
      },
    },
  },

  PodZoneAntiAffinityAnnotation(pod): {
    podAntiAffinity: {
      preferredDuringSchedulingIgnoredDuringExecution: [
        {
          weight: 50,
          podAffinityTerm: {
            labelSelector: { matchLabels: pod.metadata.labels },
            topologyKey: "failure-domain.beta.kubernetes.io/zone",
          },
        },
        {
          weight: 100,
          podAffinityTerm: {
            labelSelector: { matchLabels: pod.metadata.labels },
            topologyKey: "kubernetes.io/hostname",
          },
        },
      ],
    },
  },
}
