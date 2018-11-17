local kube = import "../kube.libsonnet";

local an_obj = kube._Object("v1", "Gentle", "foo");
local a_pod = kube.Pod("foo") {
  metadata+: { labels+: { foo: "bar", bar: "qxx" } },
  spec+: {
    default_container: "c1",
    containers_+: {
      local c = self,
      c1: kube.Container("c1") {
        image: "nginx",
        args_: {
          k1: "v1",
          k2: "v2",
        },
        ports_: {
          http: { containerPort: 8080 },
          https: { containerPort: 8443 },
          udp: { containerPort: 5353, protocol: "UDP" },
        },
      },
      c2: kube.Container("c2") {
        image: "nginx",
        args_format+: { prefix: "-" },
        args_: c.c1.args_,
      },
      c3: kube.Container("c3") {
        image: "nginx",
        args_format+: { split: true },
        args_: c.c1.args_,
      },
      c4: kube.Container("c4") {
        image: "nginx",
        args_format+: { prefix: "-", split: true },
        args_: c.c1.args_,
      },
    },
  },
};
local a_deploy = kube.Deployment("foo") {
  spec+: { template+: { metadata+: a_pod.metadata, spec+: a_pod.spec } },
};
// Basic unittesting for methods that are not exercised by the other e2e-ish tests
std.assertEqual(a_pod.spec.containers[0].args, ["--k1=v1", "--k2=v2"]) &&
std.assertEqual(a_pod.spec.containers[1].args, ["-k1=v1", "-k2=v2"]) &&
std.assertEqual(a_pod.spec.containers[2].args, ["--k1", "v1", "--k2", "v2"]) &&
std.assertEqual(a_pod.spec.containers[3].args, ["-k1", "v1", "-k2", "v2"]) &&
std.assertEqual(kube.objectValues({ a: 1, b: 2 }), [1, 2]) &&
std.assertEqual(kube.objectItems({ a: 1, b: 2 }), [["a", 1], ["b", 2]]) &&
std.assertEqual(kube.hyphenate("foo_bar_baz"), ("foo-bar-baz")) &&
std.assertEqual(kube.mapToNamedList({ foo: { a: "b" } }), [{ name: "foo", a: "b" }]) &&
std.assertEqual(kube.filterMapByFields({ a: 1, b: 2, c: 3 }, ["a", "c", "d"]), { a: 1, c: 3 }) &&
std.assertEqual(kube.parseOctal("755"), 493) &&
std.assertEqual(kube.siToNum("42G"), 42 * 1e9) &&
std.assertEqual(kube.siToNum("42Gi"), 42 * std.pow(2, 30)) &&
std.assertEqual(kube.toUpper("ForTy 2"), "FORTY 2") &&
std.assertEqual(kube.toLower("ForTy 2"), "forty 2") &&
std.assertEqual(an_obj, {
  apiVersion: "v1",
  kind: "Gentle",
  metadata: { name: "foo", labels: { name: "foo" }, annotations: {} },
}) &&
std.assertEqual(
  [kube.podRef(a_deploy).spec.ports("TCP"), kube.podRef(a_deploy).spec.ports("UDP")],
  [[8080, 8443], [5353]]
) &&
std.assertEqual(
  // latest kubecfg produces stable output from maps hashes, so below shouldn't be flaky
  kube.podsPorts([a_deploy]),
  [
    { port: 8080, protocol: "TCP" },
    { port: 8443, protocol: "TCP" },
    { port: 5353, protocol: "UDP" },
  ]
) &&
std.assertEqual(
  kube.podLabelsSelector(a_deploy),
  { podSelector: { matchLabels: { name: "foo", foo: "bar", bar: "qxx" } } }
)
