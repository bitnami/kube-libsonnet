local kube = import "lib/kube.libsonnet";

local labels = {
  tier: "backend",
};

local master_labels = labels + {
  component: "master",
};

local slave_labels = labels + {
  component: "slave",
};

{
  backend_secret: kube.Secret("mariadb") {
    metadata+: {
      labels+: labels,
    },
    data_+: {
      "database_name": "webserver_db",
      "database_user": "webserver_user",
      "database_password": "webserver_db_password",
      "replication_user": "replica_user",
      "replication_password": "replica_password",
      "root_user": "root_user",
      "root_password": "root_password"
  }},

  backend_master_statefulset: kube.StatefulSet("mariadb-master") {
    metadata+: {
      labels+: master_labels,
    },
    spec+: {
      template+: {
        spec+: {
          securityContext: {
            runAsUser: 1001,
            fsGroup: 1001,
          },
          containers_+: {
            default: kube.Container("mariadb") {
              image: "bitnami/mariadb",
              ports_+: {
                mysql: { containerPort: 3306 },
              },
              env_+: {
                "MARIADB_REPLICATION_MODE": "master",
                "MARIADB_REPLICATION_USER": { secretKeyRef: { name: "mariadb", key: "replication_user" } },
                "MARIADB_REPLICATION_PASSWORD": { secretKeyRef: { name: "mariadb", key: "replication_password" } },
                "MARIADB_ROOT_USER": { secretKeyRef: { name: "mariadb", key: "root_user" } },
                "MARIADB_ROOT_PASSWORD": { secretKeyRef: { name: "mariadb", key: "root_password" } },
                "MARIADB_USER": { secretKeyRef: { name: "mariadb", key: "database_user" } },
                "MARIADB_DATABASE": { secretKeyRef: { name: "mariadb", key: "database_name" } },
                "MARIADB_PASSWORD": { secretKeyRef: { name: "mariadb", key: "database_password"
              }}},
              livenessProbe: {
                initialDelaySeconds: 40,
                exec: {
                  command: [
                    "sh",
                    "-c",
                    "exec mysqladmin status -u$MARIADB_ROOT_USER -p$MARIADB_ROOT_PASSWORD",
              ]}},
              readinessProbe: {
                initialDelaySeconds: 30,
                exec: {
                  command: [
                    "sh",
                    "-c",
                    "exec mysqladmin status -u$MARIADB_ROOT_USER -p$MARIADB_ROOT_PASSWORD",
              ]}},
              volumeMounts_+: {
                "mariadb-data": {
                  "mountPath": "/bitnami/mariadb",
            }}},
            metrics: kube.Container("metrics") {
              image: "prom/mysqld-exporter:v0.10.0",
              command: [
                "sh",
                "-c",
                "DATA_SOURCE_NAME=\"root:$MARIADB_ROOT_PASSWORD@(localhost:3306)/\" /bin/mysqld_exporter",
              ],
              ports_+: {
                metrics: { containerPort: 9104 },
              },
              env_+: {
                "MARIADB_ROOT_PASSWORD": { secretKeyRef: { name: "mariadb", key: "root_password"
              }}},
              livenessProbe: {
                initialDelaySeconds: 15,
                timeoutSeconds: 1,
                httpGet: {
                  path: "/metrics",
                  port: 9104,
              }},
              readinessProbe: {
                initialDelaySeconds: 5,
                timeoutSeconds: 5,
                httpGet: {
                  path: "/metrics",
                  port: 9104,
      }}}}}},
      volumeClaimTemplates_+: {
        "mariadb-data": {
          storage: "10Gi",
          metadata+: {
            labels+: master_labels,
  }}}}},

  backend_slave_statefulset: kube.StatefulSet("mariadb-slave") {
    metadata+: {
      labels+: slave_labels,
    },
    spec+: {
      template+: {
        spec+: {
          securityContext: {
            runAsUser: 1001,
            fsGroup: 1001,
          },
          containers_+: {
            default: kube.Container("mariadb") {
              image: "bitnami/mariadb",
              ports_+: { mysql: { containerPort: 3306 } },
              env_+: {
                "MARIADB_REPLICATION_MODE": "slave",
                "MARIADB_REPLICATION_USER": { secretKeyRef: { name: "mariadb", key: "replication_user" } },
                "MARIADB_REPLICATION_PASSWORD": { secretKeyRef: { name: "mariadb", key: "replication_password" } },
                "MARIADB_MASTER_HOST": "mariadb-master",
                "MARIADB_MASTER_ROOT_USER": { secretKeyRef: { name: "mariadb", key: "root_user" } },
                "MARIADB_MASTER_ROOT_PASSWORD": { secretKeyRef: { name: "mariadb", key: "root_password"
              }}},
              livenessProbe: {
                initialDelaySeconds: 40,
                exec: {
                  command: [
                    "sh",
                    "-c",
                    "exec mysqladmin status -u$MARIADB_MASTER_ROOT_USER -p$MARIADB_MASTER_ROOT_PASSWORD",
              ]}},
              readinessProbe: {
                initialDelaySeconds: 30,
                exec: {
                  command: [
                    "sh",
                    "-c",
                    "exec mysqladmin status -u$MARIADB_MASTER_ROOT_USER -p$MARIADB_MASTER_ROOT_PASSWORD",
              ]}},
              volumeMounts_+: {
                "mariadb-data": {
                  "mountPath": "/bitnami/mariadb",
            }}},
            metrics: kube.Container("metrics") {
              image: "prom/mysqld-exporter:v0.10.0",
              command: [
                "sh",
                "-c",
                "DATA_SOURCE_NAME=\"root:$MARIADB_MASTER_ROOT_PASSWORD@(localhost:3306)/\" /bin/mysqld_exporter",
              ],
              ports_+: {
                metrics: { containerPort: 9104 },
              },
              env_+: {
                "MARIADB_MASTER_ROOT_PASSWORD": { secretKeyRef: { name: "mariadb", key: "root_password"
              }}},
              livenessProbe: {
                initialDelaySeconds: 15,
                timeoutSeconds: 1,
                httpGet: {
                  path: "/metrics",
                  port: 9104,
              }},
              readinessProbe: {
                initialDelaySeconds: 5,
                timeoutSeconds: 5,
                httpGet: {
                  path: "/metrics",
                  port: 9104,
      }}}}}},
      volumeClaimTemplates_+: {
        "mariadb-data": {
          storage: "10Gi",
          metadata+: {
            labels+: slave_labels,
  }}}}},

  backend_master_service: kube.Service("mariadb-master") {
    metadata+: {
      labels+: master_labels,
      annotations+: {
        "prometheus.io/scrape": "true",
        "prometheus.io/port": "9104",
    }},
    target_pod: $.backend_master_statefulset.spec.template,
    spec+: {
      ports: [
        {
          name: "mariadb",
          port: 3306,
          targetPort: $.backend_master_statefulset.spec.template.spec.containers[0].ports[0].containerPort,
        },
        {
          name: "metrics",
          port: 9104,
          targetPort: $.backend_master_statefulset.spec.template.spec.containers[1].ports[0].containerPort,
  }]}},

  backend_slave_service: kube.Service("mariadb-slave") {
    metadata+: {
      labels+: slave_labels,
      annotations+: {
        "prometheus.io/scrape": "true",
        "prometheus.io/port": "9104",
    }},
    target_pod: $.backend_master_statefulset.spec.template,
    spec+: {
      ports: [
        {
          name: "mariadb",
          port: 3306,
          targetPort: $.backend_slave_statefulset.spec.template.spec.containers[0].ports[0].containerPort,
        },
        {
          name: "metrics",
          port: 9104,
          targetPort: $.backend_slave_statefulset.spec.template.spec.containers[1].ports[0].containerPort,
  }]}},
}