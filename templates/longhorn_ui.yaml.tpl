apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: longhorn-replace-path
  namespace: ${longhorn_namespace}
spec:
  replacePathRegex:
    regex: ^${subpath}(/|$)(.*)
    replacement: /$2
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: basic-auth
  namespace: ${longhorn_namespace}
spec:
  basicAuth:
    secret: basic-auth-secret
---
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: longhorn-ui
  namespace: ${longhorn_namespace}
spec:
  entryPoints:
    - web
    %{if expose_https}
    - websecure
    %{endif}
  routes:
    - match: Host(`${base_domain}`) && PathPrefix(`${subpath}`)
      kind: Rule
      services:
        - name: longhorn-frontend
          port: 80
      middlewares:
        - name: basic-auth
        - name: longhorn-replace-path
%{if expose_https}
  tls:
    secretName: wildcard-domain-secret
%{endif}