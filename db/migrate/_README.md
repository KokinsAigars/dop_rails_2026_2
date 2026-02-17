RECREATE DB:

1)
bin/rails db:drop db:create

2)
# run migration ap to the point
# db/migration/20260123163225_stop_before_pg_restore.rb
# (run ir container rails_dop_dev terminal)
bin/rails db:migrate:status | tail -n 20
bin/rails db:migrate VERSION=20260123163225

3)
# restore all tables script/restore_**
pg_restore

4)
continue with migration
bin/rails db:migrate
bin/rails db:seed



bin/rails db:rollback
# if to delete some migration files, 
# it should be removed from the schema_migrations table also:
bin/rails db:migrate:status | tail -n 20
DELETE FROM schema_migrations
WHERE version = '20260204060509';
WHERE version = '20260205194450';


bin/rails db:migrate:status | grep sc_04_dic_audit_trigger_function_generic

