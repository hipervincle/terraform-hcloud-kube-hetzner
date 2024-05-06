apiVersion: v1
kind: Secret
metadata:
  name: basic-auth-secret
  namespace: ${ingress_controller_namespace}
  %{if reflector_enabled}
  annotations:
    reflector.v1.k8s.emberstack.com/reflection-allowed: 'true'
    reflector.v1.k8s.emberstack.com/reflection-allowed-namespaces: ''
    reflector.v1.k8s.emberstack.com/reflection-auto-enabled: 'true'
    reflector.v1.k8s.emberstack.com/reflection-auto-namespaces: ''
  %{endif}
data:
  users: |2
    ${basic_auth_hash}
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: ${ingress_controller_namespace}
spec:
  basicAuth:
    secret: basic-auth-secret
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: traefik-strip-prefix
  namespace: ${ingress_controller_namespace}
spec:
  stripPrefix:
    prefixes:
    - ${subpath}
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard
  namespace: ${ingress_controller_namespace}
  labels:
    app.kubernetes.io/instance: traefik
    app.kubernetes.io/name: traefik-dashboard
spec:
  ports:
    - name: traefik
      port: 9000
      targetPort: traefik
      protocol: TCP
  selector:
    app.kubernetes.io/instance: traefik-${ingress_controller_namespace}
    app.kubernetes.io/name: traefik
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: ${ingress_controller_namespace}
spec:
  entryPoints:
    - web
    %{if expose_https}
    - websecure
    %{endif}
  routes:
    - match: Host(`${base_domain}`) && (PathPrefix(`${subpath}`) || HeaderRegexp(`Referer`, `.*${subpath}/.*`))
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
      middlewares:
        - name: basic-auth
        - name: traefik-strip-prefix
%{if expose_https}
  tls:
    secretName: wildcard-domain-secret
%{endif}