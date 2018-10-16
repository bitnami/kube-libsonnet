local kube = import "lib/kube.libsonnet";

local labels = {
  tier: "frontend",
};

{
  frontend_pvc: kube.PersistentVolumeClaim("wordpress") {
    metadata+: {
      labels+: labels,
    },
    storage:: "10Gi",
  },

  frontend_configmap: kube.ConfigMap("wordpress") {
    metadata+: {
      labels+: labels,
    },
    data: {
      "admin_first_name": "Admin",
      "admin_last_name": "User",
      "blog_name": "Kubernetes blog!",
  }},

  frontend_secret: kube.Secret("wordpress") {
    metadata+: {
      labels+: labels,
    },
    data_+: {
      "user": "user",
      "password": "bitnami",
      "mail": "user@example.com",
  }},

  frontend_deployment: kube.Deployment("wordpress") {
    metadata+: {
      labels+: labels,
    },
    spec+: {
      template+: {
        spec+: {
          containers_+: {
            default: kube.Container("wordpress") {
              image: "bitnami/wordpress",
              ports_+: { http: { containerPort: 80 } },
	      env_+: {
	        "MARIADB_HOST": "mariadb-master",
                "WORDPRESS_DATABASE_USER": {
                  secretKeyRef: { name: "mariadb", key: "database_user" },
                },
                "WORDPRESS_DATABASE_NAME": {
                  secretKeyRef: { name: "mariadb", key: "database_name" },
                },
                "WORDPRESS_DATABASE_PASSWORD": {
                  secretKeyRef: { name: "mariadb", key: "database_password" },
                },
                "WORDPRESS_USERNAME": {
                  secretKeyRef: { name: "wordpress", key: "user" },
                },
                "WORDPRESS_EMAIL": {
                  secretKeyRef: { name: "wordpress", key: "mail" },
                },
                "WORDPRESS_PASSWORD": {
                  secretKeyRef: { name: "wordpress", key: "password" },
                },
                "WORDPRESS_BLOG_NAME": {
                  configMapKeyRef: { name: "wordpress", key: "blog_name" },
                },
                "WORDPRESS_FIRST_NAME": {
                  configMapKeyRef: { name: "wordpress", key: "admin_first_name" },
                },
                "WORDPRESS_LAST_NAME": {
                  configMapKeyRef: { name: "wordpress", key: "admin_last_name" },
                },
              },
	      livenessProbe: {
                initialDelaySeconds: 120,
                httpGet:  { path: "/wp-login.php", port: 80 },
              },
              readinessProbe: {
                initialDelaySeconds: 60,
                httpGet:  { path: "/wp-login.php", port: 80 },
              },
              volumeMounts_+: {
                "wordpress-data": {
                  "mountPath": "/bitnami",
              }}}},
	  volumes_+: {
            "wordpress-data": {
              "persistentVolumeClaim": {
                "claimName": "wordpress",
  }}}}}}},

  frontend_service: kube.Service("wordpress") {
    metadata+: {
      labels+: labels,
    },
    target_pod: $.frontend_deployment.spec.template,
  },
}