%{if expose}
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth-secret
  namespace: ${ingress_controller_namespace}
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
  name: redirect-https
  namespace: ${ingress_controller_namespace}
spec:
  redirectScheme:
    scheme: https
    permanent: true
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
    - websecure
  routes:
    - match: Host(`${base_domain}`) && (PathPrefix(`${subpath}`) || HeadersRegexp(`Referer`, `.*${subpath}/.*`))
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
      middlewares:
        - name: redirect-https
        - name: basic-auth
        - name: traefik-strip-prefix
  tls:
    secretName: wildcard-domain-secret
%{endif}