bin/rails db:drop db:create
bin/rails db:migrate VERSION=20260120041142   # base schema
pg_restore --data-only ...
bin/rails db:migrate                          # hardening
