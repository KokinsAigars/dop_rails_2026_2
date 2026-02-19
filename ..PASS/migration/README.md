RECREATE DB:

1)
bin/rails db:drop db:create

2)
# run migration ap to the point
# db/migration/20260122053219_stop_before_pg_restore.rb
# (run ir container rails_dop_dev terminal)
bin/rails db:migrate:status | tail -n 20
bin/rails db:migrate VERSION=20260218063636

3)
# restore all tables script/restore_**
pg_restore

4) ** if old migration files (_2026.01.21_)
DELETE FROM sc_03_dic_entry.dic_note n
WHERE n.fk_entry_id IS NOT NULL
AND NOT EXISTS (
SELECT 1 FROM sc_03_dic_entry.dic_entry e
WHERE e.id = n.fk_entry_id
);

5)
continue with migration
bin/rails db:migrate
bin/rails db:seed

6) ** add back notes 4 tables, if old migration files (_2026.01.21_)

INSERT INTO sc_03_dic_entry.dic_note (id, fk_index_id, fk_entry_id, note_no, note_note, created_at, modified_date, modified_by, root_id, version, is_current) VALUES ('f356639a-4ea8-4ccd-b8f0-5a433c478fe0', 'c689b6c0-5d00-4944-bf97-6eb06fab05e5', 'a019a299-5ee8-4dc1-8f79-0d480c73812c', 0, 'indefinite adv. of time:', '2026-01-05 23:23:30.241954', '2026-01-05 23:23:30.241954', '{"actor": {"type": "user", "user_id": "019b99cf-0ae8-7b12-b90f-6eb587f47655", "fullname": "Aigars Kokins"}, "change": {"reason": "db insert", "ticket": "RIX-2026.01.07-01"}, "source": {"app": "python-script", "client": "postgresql"}}', 'f356639a-4ea8-4ccd-b8f0-5a433c478fe0', 1, true);
INSERT INTO sc_03_dic_entry.dic_note (id, fk_index_id, fk_entry_id, note_no, note_note, created_at, modified_date, modified_by, root_id, version, is_current) VALUES ('fa508f5e-4c75-46c0-bbee-7e80c0406a19', '7d1692b8-7517-457b-bde8-c344d508bfc3', '0b81526a-fdcc-47bc-b628-54147bf2504d', 0, 'in-definite adverb of place with a locatival sense:', '2026-01-05 23:23:30.112446', '2026-01-05 23:23:30.112446', '{"actor": {"type": "user", "user_id": "019b99cf-0ae8-7b12-b90f-6eb587f47655", "fullname": "Aigars Kokins"}, "change": {"reason": "db insert", "ticket": "RIX-2026.01.07-01"}, "source": {"app": "python-script", "client": "postgresql"}}', 'fa508f5e-4c75-46c0-bbee-7e80c0406a19', 1, true);
INSERT INTO sc_03_dic_entry.dic_note (id, fk_index_id, fk_entry_id, note_no, note_note, created_at, modified_date, modified_by, root_id, version, is_current) VALUES ('a0cb18c4-9ce4-4027-9650-a15e598670e7', '8c3dbc4c-1761-4787-8630-e98cbfb5bc2a', 'a5b62d8e-bcca-40b1-8d9f-3e4d7811e4df', 1, 'interrogative adverb of manner', '2026-01-05 23:23:30.089760', '2026-01-05 23:23:30.089760', '{"actor": {"type": "user", "user_id": "019b99cf-0ae8-7b12-b90f-6eb587f47655", "fullname": "Aigars Kokins"}, "change": {"reason": "db insert", "ticket": "RIX-2026.01.07-01"}, "source": {"app": "python-script", "client": "postgresql"}}', 'a0cb18c4-9ce4-4027-9650-a15e598670e7', 1, true);
INSERT INTO sc_03_dic_entry.dic_note (id, fk_index_id, fk_entry_id, note_no, note_note, created_at, modified_date, modified_by, root_id, version, is_current) VALUES ('71f316f0-fdce-4a54-a9a2-ff18d1693dbc', 'baf32597-fb76-4a1a-9670-45bf14cebd06', 'e31f90ce-3c45-46e1-b7ed-cdbcc35ddb0e', 3, 'gen. ~āya, Ps II 375,27 (withpubba-cetanā and sanniṭṭhāpaka-cetanā); 376,2.', '2026-01-05 23:17:54.885542', '2026-01-05 23:17:54.885542', '{"actor": {"type": "user", "user_id": "019b99cf-0ae8-7b12-b90f-6eb587f47655", "fullname": "Aigars Kokins"}, "change": {"reason": "db insert", "ticket": "RIX-2026.01.07-01"}, "source": {"app": "python-script", "client": "postgresql"}}', '71f316f0-fdce-4a54-a9a2-ff18d1693dbc', 1, true);



# if to delete some migration file, it should be removed from schema_migrations table:
bin/rails db:migrate:status | tail -n 20
bin/rails db:migrate:status
DELETE FROM schema_migrations
WHERE version = '20260219175226';


# SELECT in PostgreSQL
SELECT id FROM sc_03_dic_entry.dic_entry
WHERE name='apara-cetanā'
AND lang='pi'
AND Gender='f.'



bin/rails generate migration AddResetTokenToUsers reset_password_token:string:index reset_password_sent_at:datetime