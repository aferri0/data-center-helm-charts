{{/*This file contains template snippets used by the other files in this directory.*/}}
{{/*Most of them were generated by the "helm chart create" tool, and then some others added.*/}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "bitbucket.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bitbucket.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bitbucket.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "bitbucket.labels" -}}
helm.sh/chart: {{ include "bitbucket.chart" . }}
{{ include "bitbucket.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ with .Values.additionalLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bitbucket.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bitbucket.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "bitbucket.baseUrl" -}}
{{ $httpPortMismatch := (and (eq .Values.bitbucket.proxy.scheme "http") (ne (int .Values.bitbucket.proxy.port) 80) ) -}}
{{ $httpsPortMismatch := (and (eq .Values.bitbucket.proxy.scheme "https") (ne (int .Values.bitbucket.proxy.port) 443) ) -}}
{{ .Values.bitbucket.proxy.scheme }}://{{ .Values.bitbucket.proxy.fqdn -}}
{{ if or $httpPortMismatch $httpsPortMismatch }}:{{ .Values.bitbucket.proxy.port }}{{ end }}
{{- end }}

{{/*
The command that should be run by the nfs-fixer init container to correct the permissions of the shared-home root directory.
*/}}
{{- define "sharedHome.permissionFix.command" -}}
{{- if .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{ .Values.volumes.sharedHome.nfsPermissionFixer.command }}
{{- else }}
{{- printf "(chgrp %s %s; chmod g+w %s)" .Values.bitbucket.gid .Values.volumes.sharedHome.nfsPermissionFixer.mountPath .Values.volumes.sharedHome.nfsPermissionFixer.mountPath }}
{{- end }}
{{- end }}

{{- define "bitbucket.image" -}}
{{- if .Values.image.registry -}}
{{ .Values.image.registry}}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
For each additional library declared, generate a volume mount that injects that library into the Bitbucket lib directory
*/}}
{{- define "bitbucket.additionalLibraries" -}}
{{- range .Values.bitbucket.additionalLibraries -}}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bitbucket/app/WEB-INF/lib/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
For each additional plugin declared, generate a volume mount that injects that library into the Bitbucket plugins directory
*/}}
{{- define "bitbucket.additionalBundledPlugins" -}}
{{- range .Values.bitbucket.additionalBundledPlugins -}}
- name: {{ .volumeName }}
  mountPath: "/opt/atlassian/bitbucket/app/WEB-INF/atlassian-bundled-plugins/{{ .fileName }}"
  {{- if .subDirectory }}
  subPath: {{ printf "%s/%s" .subDirectory .fileName | quote }}
  {{- else }}
  subPath: {{ .fileName | quote }}
  {{- end }}
{{- end }}
{{- end }}