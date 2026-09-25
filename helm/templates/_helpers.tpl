{{/*
Workbench image tag. Uses .Values.workbench.image.tag when set; otherwise looks up
the ImageStream and picks the tag annotated as recommended by OpenShift AI.
Falls back to .Values.workbench.image.fallbackTag (e.g. with "helm template").
*/}}
{{- define "workbench.imageTag" -}}
{{- $img := .Values.workbench.image -}}
{{- $tag := $img.tag -}}
{{- if not $tag -}}
{{- $is := lookup "image.openshift.io/v1" "ImageStream" $img.namespace $img.imageStream -}}
{{- if $is -}}
{{- range $is.spec.tags -}}
{{- if and .annotations (eq (index .annotations "opendatahub.io/workbench-image-recommended" | default "") "true") -}}
{{- $tag = .name -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $tag | default $img.fallbackTag -}}
{{- end -}}

{{- define "workbench.image" -}}
{{- $img := .Values.workbench.image -}}
{{- printf "image-registry.openshift-image-registry.svc:5000/%s/%s:%s" $img.namespace $img.imageStream (include "workbench.imageTag" .) -}}
{{- end -}}
