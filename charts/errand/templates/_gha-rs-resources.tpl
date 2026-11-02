{{- /*
The per-scale-set templates from gha-runner-scale-set 0.15.1, each wrapped in a
define named after its upstream file, with the same sed as _gha-rs-helpers.tpl.
runners.yaml includes them once per runner.
*/}}

{{- define "errand.gha-rs.no_permission_serviceaccount" }}
{{- include "errand.gha-rs.validateMetadata" . }}
{{- $hasCustomResourceMeta := (and .Values.resourceMeta .Values.resourceMeta.noPermissionServiceAccount) }}
{{- $containerMode := .Values.containerMode }}
{{- if and (ne $containerMode.type "kubernetes") (ne $containerMode.type "kubernetes-novolume") (not .Values.template.spec.serviceAccountName) }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "errand.gha-rs.noPermissionServiceAccountName" . }}
  namespace: {{ include "errand.gha-rs.namespace" . }}
  labels:
    {{- $base := include "errand.gha-rs.labels" . | fromYaml }}
    {{- $extra := dict "app.kubernetes.io/component" "" }}
    {{- $reserved := merge $base $extra }}
    {{- with .Values.labels }}
    {{- range $k, $v := . }}
    {{- if not (or (hasKey $reserved $k) (hasPrefix "actions.github.com/" $k)) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.noPermissionServiceAccount.labels }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
    {{- include "errand.gha-rs.labels" . | nindent 4 }}
  annotations:
    {{- with .Values.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.noPermissionServiceAccount.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
  finalizers:
    - actions.github.com/cleanup-protection
{{- end }}
{{- end }}

{{- define "errand.gha-rs.manager_role" }}
{{- include "errand.gha-rs.validateMetadata" . }}
{{- $hasCustomResourceMeta := (and .Values.resourceMeta .Values.resourceMeta.managerRole) }}
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: {{ include "errand.gha-rs.managerRoleName" . }}
  namespace: {{ include "errand.gha-rs.namespace" . }}
  labels:
    {{- $base := include "errand.gha-rs.labels" . | fromYaml }}
    {{- $extra := dict "app.kubernetes.io/component" "manager-role" }}
    {{- $reserved := merge $base $extra }}
    {{- with .Values.labels }}
    {{- range $k, $v := . }}
    {{- if not (or (hasKey $reserved $k) (hasPrefix "actions.github.com/" $k)) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.managerRole.labels }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
    {{- include "errand.gha-rs.labels" . | nindent 4 }}
    app.kubernetes.io/component: manager-role
  annotations:
    {{- with .Values.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.managerRole.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
  finalizers:
    - actions.github.com/cleanup-protection
rules:
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - create
  - delete
  - get
- apiGroups:
  - ""
  resources:
  - pods/status
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - create
  - delete
  - get
  - list
  - patch
  - update
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - rolebindings
  verbs:
  - create
  - delete
  - get
  - patch
  - update
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - roles
  verbs:
  - create
  - delete
  - get
  - patch
  - update
{{- if .Values.githubServerTLS }}
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
{{- end }}
{{- end }}

{{- define "errand.gha-rs.manager_role_binding" }}
{{- include "errand.gha-rs.validateMetadata" . }}
{{- $hasCustomResourceMeta := (and .Values.resourceMeta .Values.resourceMeta.managerRoleBinding) }}
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: {{ include "errand.gha-rs.managerRoleBindingName" . }}
  namespace: {{ include "errand.gha-rs.namespace" . }}
  labels:
    {{- $base := include "errand.gha-rs.labels" . | fromYaml }}
    {{- $extra := dict "app.kubernetes.io/component" "manager-role-binding" }}
    {{- $reserved := merge $base $extra }}
    {{- with .Values.labels }}
    {{- range $k, $v := . }}
    {{- if not (or (hasKey $reserved $k) (hasPrefix "actions.github.com/" $k)) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.managerRoleBinding.labels }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
    {{- include "errand.gha-rs.labels" . | nindent 4 }}
    app.kubernetes.io/component: manager-role-binding
  annotations:
    {{- with .Values.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.managerRoleBinding.annotations }}
    {{- include "errand.gha-rs.stringMap" . | nindent 4 }}
    {{- end }}
    {{- end }}
  finalizers:
    - actions.github.com/cleanup-protection
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: {{ include "errand.gha-rs.managerRoleName" . }}
subjects:
- kind: ServiceAccount
  name: {{ include "errand.gha-rs.managerServiceAccountName" . | nindent 4 }}
  namespace: {{ include "errand.gha-rs.managerServiceAccountNamespace" . | nindent 4 }}
{{- end }}

{{- define "errand.gha-rs.autoscalingrunnerset" }}
{{- $resourceMeta := default (dict) .Values.resourceMeta }}
{{- $hasCustomResourceMeta := (and .Values.resourceMeta .Values.resourceMeta.autoscalingRunnerSet) }}
{{- /* .Values.listenerConfig is validated by values.schema.json */ -}}
{{- include "errand.gha-rs.validateMetadata" . }}
apiVersion: actions.github.com/v1alpha1
kind: AutoscalingRunnerSet
metadata:
  {{- if or (not (include "errand.gha-rs.scale-set-name" .)) (gt (len (include "errand.gha-rs.scale-set-name" .)) 45) }}
  {{ fail "Name must have up to 45 characters" }}
  {{- end }}
  {{- if gt (len (include "errand.gha-rs.namespace" .)) 63 }}
  {{ fail "Namespace must have up to 63 characters" }}
  {{- end }}
  name: {{ include "errand.gha-rs.scale-set-name" . | replace "_" "-" }}
  namespace: {{ include "errand.gha-rs.namespace" . }}
  labels:
    {{- $base := include "errand.gha-rs.labels" . | fromYaml }}
    {{- $extra := dict "app.kubernetes.io/component" "" }}
    {{- $reserved := merge $base $extra }}
    {{- with .Values.labels }}
    {{- range $k, $v := . }}
    {{- if not (or (hasKey $reserved $k) (hasPrefix "actions.github.com/" $k)) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.autoscalingRunnerSet.labels }}
    {{- range $k, $v := . }}
    {{- if not (or (hasKey $reserved $k) (hasPrefix "actions.github.com/" $k)) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
    app.kubernetes.io/component: "autoscaling-runner-set"
    {{- include "errand.gha-rs.labels" . | nindent 4 }}
  annotations:
    {{- with .Values.annotations }}
    {{- range $k, $v := . }}
    {{- if not (or (hasPrefix "actions.github.com/cleanup-" $k) (eq $k "actions.github.com/values-hash")) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if $hasCustomResourceMeta }}
    {{- with .Values.resourceMeta.autoscalingRunnerSet.annotations }}
    {{- range $k, $v := . }}
    {{- if not (or (hasPrefix "actions.github.com/cleanup-" $k) (eq $k "actions.github.com/values-hash")) }}
    {{ $k }}: {{ include "errand.gha-rs.metadataValue" $v | quote }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
    actions.github.com/values-hash: {{ toJson .Values | sha256sum | trunc 63 }}
    {{- $containerMode := .Values.containerMode }}
    {{- if not (kindIs "string" .Values.githubConfigSecret) }}
    actions.github.com/cleanup-github-secret-name: {{ include "errand.gha-rs.githubsecret" . }}
    {{- end }}
    actions.github.com/cleanup-manager-role-binding: {{ include "errand.gha-rs.managerRoleBindingName" . }}
    actions.github.com/cleanup-manager-role-name: {{ include "errand.gha-rs.managerRoleName" . }}
    {{- if and (or (eq $containerMode.type "kubernetes") (eq $containerMode.type "kubernetes-novolume")) (not .Values.template.spec.serviceAccountName) }}
    actions.github.com/cleanup-kubernetes-mode-role-binding-name: {{ include "errand.gha-rs.kubeModeRoleBindingName" . }}
    actions.github.com/cleanup-kubernetes-mode-role-name: {{ include "errand.gha-rs.kubeModeRoleName" . }}
    actions.github.com/cleanup-kubernetes-mode-service-account-name: {{ include "errand.gha-rs.kubeModeServiceAccountName" . }}
    {{- end }}
    {{- if and (ne $containerMode.type "kubernetes") (ne $containerMode.type "kubernetes-novolume") (not .Values.template.spec.serviceAccountName) }}
    actions.github.com/cleanup-no-permission-service-account-name: {{ include "errand.gha-rs.noPermissionServiceAccountName" . }}
    {{- end }}

spec:
  githubConfigUrl: {{ required ".Values.githubConfigUrl is required" (trimSuffix "/" .Values.githubConfigUrl) }}
  githubConfigSecret: {{ include "errand.gha-rs.githubsecret" . }}
  {{- with .Values.runnerGroup }}
  runnerGroup: {{ . }}
  {{- end }}
  {{- with .Values.runnerScaleSetName }}
  runnerScaleSetName: {{ . }}
  {{- end }}
  {{- if and .Values.scaleSetLabels (kindIs "slice" .Values.scaleSetLabels) }}
  {{- range .Values.scaleSetLabels }}
  {{- if empty . }}
  {{- fail "scaleSetLabels contains an empty string, each label must be a non-empty string of less than 256 characters" }}
  {{- end }}
  {{- if ge (len .) 256 }}
  {{- fail "scaleSetLabels contains a label that is 256 characters or more, each label must be a non-empty string of less than 256 characters" }}
  {{- end }}
  {{- end }}
  runnerScaleSetLabels:
    {{- toYaml .Values.scaleSetLabels | nindent 4 }}
  {{- end }}

  {{- if .Values.githubServerTLS }}
  githubServerTLS:
    {{- with .Values.githubServerTLS.certificateFrom }}
    certificateFrom:
      configMapKeyRef:
        name: {{ .configMapKeyRef.name }}
        key: {{ .configMapKeyRef.key }}
    {{- end }}
  {{- end }}

  {{- if and .Values.keyVault .Values.keyVault.type }}
  vaultConfig:
    type: {{ .Values.keyVault.type }}
    {{- if .Values.keyVault.proxy }}
    proxy: {{- toYaml .Values.keyVault.proxy | nindent 6 }}
    {{- end }}
    {{- if eq .Values.keyVault.type "azure_key_vault" }}
    azureKeyVault:
      url: {{ .Values.keyVault.azureKeyVault.url }}
      tenantId: {{ .Values.keyVault.azureKeyVault.tenantId }}
      clientId: {{ .Values.keyVault.azureKeyVault.clientId }}
      certificatePath: {{ .Values.keyVault.azureKeyVault.certificatePath }}
      secretKey: {{ .Values.keyVault.azureKeyVault.secretKey }}
    {{- else }}
    {{- fail "Unsupported keyVault type: " .Values.keyVault.type }}
    {{- end }}
  {{- end }}

  {{- if .Values.proxy }}
  proxy:
    {{- if .Values.proxy.http }}
    http:
      url: {{ .Values.proxy.http.url }}
      {{- if .Values.proxy.http.credentialSecretRef }}
      credentialSecretRef: {{ .Values.proxy.http.credentialSecretRef }}
      {{- end }}
    {{- end }}
    {{- if .Values.proxy.https }}
    https:
      url: {{ .Values.proxy.https.url }}
      {{- if .Values.proxy.https.credentialSecretRef }}
      credentialSecretRef: {{ .Values.proxy.https.credentialSecretRef }}
      {{- end }}
    {{- end }}
    {{- if and .Values.proxy.noProxy (kindIs "slice" .Values.proxy.noProxy) }}
    noProxy: {{ .Values.proxy.noProxy | toYaml | nindent 6}}
    {{- end }}
  {{- end }}

  {{- if and (or (kindIs "int64" .Values.minRunners) (kindIs "float64" .Values.minRunners)) (or (kindIs "int64" .Values.maxRunners) (kindIs "float64" .Values.maxRunners)) }}
    {{- if gt .Values.minRunners .Values.maxRunners }}
      {{- fail "maxRunners has to be greater or equal to minRunners" }}
    {{- end }}
  {{- end }}

  {{- if or (kindIs "int64" .Values.maxRunners) (kindIs "float64" .Values.maxRunners) }}
    {{- if lt (.Values.maxRunners | int) 0 }}
      {{- fail "maxRunners has to be greater or equal to 0" }}
    {{- end }}
  maxRunners: {{ .Values.maxRunners | int }}
  {{- end }}

  {{- if or (kindIs "int64" .Values.minRunners) (kindIs "float64" .Values.minRunners) }}
    {{- if lt (.Values.minRunners | int) 0 }}
      {{- fail "minRunners has to be greater or equal to 0" }}
    {{- end }}
  minRunners: {{ .Values.minRunners | int }}
  {{- end }}

  {{- with .Values.listenerTemplate }}
  listenerTemplate:
    {{- with .metadata }}
    metadata:
      {{- with .labels }}
      labels:
        {{- include "errand.gha-rs.stringMap" . | nindent 8 }}
      {{- end }}
      {{- with .annotations }}
      annotations:
        {{- include "errand.gha-rs.stringMap" . | nindent 8 }}
      {{- end }}
      {{- with omit . "labels" "annotations" }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- end }}
    {{- with omit . "metadata" }}
    {{- toYaml . | nindent 4}}
    {{- end }}
  {{- end }}

  {{- with .Values.listenerMetrics }}
  listenerMetrics:
    {{- toYaml . | nindent 4 }}
  {{- end }}

  {{- with .Values.listenerConfig }}
  listenerConfig:
    {{- toYaml . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "autoscalingListener") }}
  autoscalingListener:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "listenerServiceAccount") }}
  listenerServiceAccountMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "listenerRole") }}
  listenerRoleMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "listenerRoleBinding") }}
  listenerRoleBindingMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "listenerConfigSecret") }}
  listenerConfigSecretMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "ephemeralRunnerSet") }}
  ephemeralRunnerSetMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "ephemeralRunner") }}
  ephemeralRunnerMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  {{- with (index $resourceMeta "ephemeralRunnerConfigSecret") }}
  ephemeralRunnerConfigSecretMetadata:
    {{- include "errand.gha-rs.resourceMetaSpec" . | nindent 4 }}
  {{- end }}

  template:
    {{- with .Values.template.metadata }}
    metadata:
      {{- with .labels }}
      labels:
        {{- include "errand.gha-rs.stringMap" . | nindent 8 }}
      {{- end }}
      {{- with .annotations }}
      annotations:
        {{- include "errand.gha-rs.stringMap" . | nindent 8 }}
      {{- end }}
    {{- end }}
    spec:
      {{- range $key, $val := .Values.template.spec }}
        {{- if and (ne $key "containers") (ne $key "volumes") (ne $key "initContainers") (ne $key "serviceAccountName") }}
      {{ $key }}: {{ $val | toYaml | nindent 8 }}
        {{- end }}
      {{- end }}
      {{- if not .Values.template.spec.restartPolicy }}
      restartPolicy: Never
      {{- end }}
      {{- $containerMode := .Values.containerMode }}
      {{- if or (eq $containerMode.type "kubernetes") (eq $containerMode.type "kubernetes-novolume") }}
      serviceAccountName: {{ default (include "errand.gha-rs.kubeModeServiceAccountName" .) .Values.template.spec.serviceAccountName }}
      {{- else }}
      serviceAccountName: {{ default (include "errand.gha-rs.noPermissionServiceAccountName" .) .Values.template.spec.serviceAccountName }}
      {{- end }}
      {{- if or .Values.template.spec.initContainers (eq $containerMode.type "dind") }}
      initContainers:
        {{- if eq $containerMode.type "dind" }}
      - name: init-dind-externals
          {{- include "errand.gha-rs.dind-init-container" . | nindent 8 }}
          {{- if (ge (.Capabilities.KubeVersion.Minor | int) 29) }}
      - name: dind
          {{- include "errand.gha-rs.dind-container" . | nindent 8 }}
          {{- end }}
        {{- end }}
        {{- with .Values.template.spec.initContainers }}
      {{- toYaml . | nindent 6 }}
        {{- end }}
      {{- end }}
      containers:
      {{- if eq $containerMode.type "dind" }}
      - name: runner
        {{- include "errand.gha-rs.dind-runner-container" . | nindent 8 }}
        {{- if not (ge (.Capabilities.KubeVersion.Minor | int) 29) }}
      - name: dind
        {{- include "errand.gha-rs.dind-container" . | nindent 8 }}
        {{- end }}
      {{- include "errand.gha-rs.non-runner-non-dind-containers" . | nindent 6 }}
      {{- else if eq $containerMode.type "kubernetes" }}
      - name: runner
        {{- include "errand.gha-rs.kubernetes-mode-runner-container" . | nindent 8 }}
      {{- include "errand.gha-rs.non-runner-containers" . | nindent 6 }}
      {{- else if eq $containerMode.type "kubernetes-novolume" }}
      - name: runner
        {{- include "errand.gha-rs.kubernetes-novolume-mode-runner-container" . | nindent 8 }}
      {{- include "errand.gha-rs.non-runner-containers" . | nindent 6 }}
      {{- else }}
      {{- include "errand.gha-rs.default-mode-runner-containers" . | nindent 6 }}
      {{- end }}
      {{- $tlsConfig := (default (dict) .Values.githubServerTLS) }}
      {{- if or .Values.template.spec.volumes (eq $containerMode.type "dind") (eq $containerMode.type "kubernetes") $tlsConfig.runnerMountPath }}
      volumes:
        {{- if $tlsConfig.runnerMountPath }}
          {{- include "errand.gha-rs.tls-volume" $tlsConfig | nindent 6 }}
        {{- end }}
        {{- if eq $containerMode.type "dind" }}
          {{- include "errand.gha-rs.dind-volume" . | nindent 6 }}
          {{- include "errand.gha-rs.dind-work-volume" . | nindent 6 }}
          {{- include "errand.gha-rs.non-work-volumes" . | nindent 6 }}
        {{- else if eq $containerMode.type "kubernetes" }}
          {{- include "errand.gha-rs.kubernetes-mode-work-volume" . | nindent 6 }}
          {{- include "errand.gha-rs.non-work-volumes" . | nindent 6 }}
        {{- else }}
          {{- with .Values.template.spec.volumes }}
        {{- toYaml . | nindent 6 }}
          {{- end }}
        {{- end }}
      {{- else if eq $containerMode.type "kubernetes-novolume" }}
      volumes: []
      {{- end }}
{{- end }}
