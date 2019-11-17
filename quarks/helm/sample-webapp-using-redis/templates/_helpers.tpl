{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "quarks.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "quarks.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "quarks.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "quarks.labels" -}}
helm.sh/chart: {{ include "quarks.chart" . }}
{{ include "quarks.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "quarks.selectorLabels" -}}
app.kubernetes.io/name: {{ include "quarks.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "quarks.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "quarks.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Get the metadata name for an ops file.
*/}}
{{- define "quarks.ops-name" -}}
{{- printf "%s-ops-%s" .Fullname (base .OpsPath | trimSuffix (ext .OpsPath) | lower | replace "_" "-") -}}
{{- end -}}

{{- /*
  Template "quarks.dig" takes a dict and a list; it indexes the dict with each
  successive element of the list.

  For example, given (using JSON prepresentations)
    $a = { foo: { bar: { baz: 1 } } }
    $b = [ foo bar baz ]
  Then `template "quarks.dig" $a $b` will return "1".
  Note that if the key is missing there will be a rendering error.
*/ -}}
{{- define "quarks.dig" }}
{{- $obj := first . }}
{{- $keys := last . }}
{{- range $key := $keys }}{{ $obj = index $obj $key }}{{ end }}
{{- $obj | quote }}
{{- end }}