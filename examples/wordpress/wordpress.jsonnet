// Copyright (c) 2018 Bitnami
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

// Example to demonstrate kubecfg using kube-libsonnet
// This should not necessarily be considered a model jsonnet example
// to build upon.

// Based on WordPress chart:
// https://github.com/helm/charts/tree/master/stable/wordpress
//
// ```
// kubecfg update wordpress.jsonnet
//
// kubecfg delete wordpress.jsonnet
// ```

local kube = import "lib/kube.libsonnet";
local frontend = import "frontend.jsonnet";
local backend = import "backend.jsonnet";

kube.List() {
  items_+: frontend + backend,
}
