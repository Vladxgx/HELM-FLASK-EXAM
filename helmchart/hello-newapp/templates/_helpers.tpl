{{- define "hello-newapp.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "hello-newapp.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "hello-newapp.name" .) }}
{{- end }}
{{- end }}

{{- define "hello-newapp.labels" -}}
app: {{ include "hello-newapp.fullname" . }}
app.kubernetes.io/name: {{ include "hello-newapp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "hello-newapp.selectorLabels" -}}
app: {{ include "hello-newapp.fullname" . }}
{{- end }}
