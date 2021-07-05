local bitnami = import "../bitnami.libsonnet";
local kube = import "../kube.libsonnet";

local stack = {
  name:: "test-Service-pass",
  pod: kube.Pod($.name + "-pod") {
    spec+: {
      containers_+: {
        default: kube.Container($.name + "-default") {
          image: "nginx:1.12",
          ports_+: {
            http: { containerPort: 80 },
            metrics: { containerPort: 9099 },
          },
        },
        sidecar: kube.Container($.name + "-sidecar") {
          image: "nginx:1.12",
          ports_+: {
            http_sidecar: { containerPort: 80 },
            metrics: { containerPort: 9099 },
          },
        },
      },
    },
  },
  deploy: kube.Deployment($.name + "-deploy") {
    local this = self,
    spec+: {
      template+: {
        spec+: $.pod.spec,
      },
    },
  },
  service: kube.Service($.name + "-svc") {
    local this = self,
    target_pod: $.deploy.spec.template,
    container_index: 1,
  },
};

stack {
  // Assert we got the 2nd containers port named "http" for service
  assert (stack.service.spec.ports[0].name == "http-sidecar") : "Expected service port http-sidecar.",
}
