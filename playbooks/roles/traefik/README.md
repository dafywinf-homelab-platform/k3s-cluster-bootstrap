DHLWinfield - Fix Breaking Change

# Traefik Role

Copied from the enmanuel role which is broken due to a change the Traefik team made in the way they handle their
configuration files.

ports.websecure.expose: true

has become

ports.websecure.expose:default: true

in file traefik/templates/traefik-chart-values.yaml.j2