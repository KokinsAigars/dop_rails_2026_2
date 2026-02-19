# bin/rails generate migration AddLogAuditEventFunction
# bin/rails db:migrate

# frozen_string_literal: true

class AddLogAuditEventFunction < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION sc_05_audit.fn_log_audit_event()
      RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      DECLARE
        v_audit_table regclass := TG_ARGV[0]::regclass; 
        v_action text := TG_OP;

        v_session_id text := current_setting('app.session_id', true);
        v_user_id text := current_setting('app.user_id', true);
        v_oauth_app_id text := current_setting('app.oauth_application_id', true);
        v_request_id text := current_setting('app.request_id', true);
        v_ip text := current_setting('app.ip', true);
        v_user_agent text := current_setting('app.user_agent', true);
        v_reason text := current_setting('app.reason', true);

        v_row_id uuid;
        v_root_id uuid;
        v_version integer;
        v_diff jsonb;
        v_snapshot jsonb;

        sql text;
      BEGIN
        IF TG_OP = 'DELETE' THEN
          v_row_id := OLD.id;
          v_root_id := COALESCE(OLD.root_id, OLD.id);
          v_version := OLD.version;
          v_snapshot := to_jsonb(OLD);
          v_diff := NULL;

        ELSIF TG_OP = 'INSERT' THEN
          v_row_id := NEW.id;
          v_root_id := COALESCE(NEW.root_id, NEW.id);
          v_version := NEW.version;
          v_snapshot := to_jsonb(NEW);
          v_diff := NULL;

        ELSE -- UPDATE
          v_row_id := NEW.id;
          v_root_id := COALESCE(NEW.root_id, NEW.id);
          v_version := NEW.version;
          v_snapshot := to_jsonb(NEW);
          v_diff := jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
        END IF;

        sql := format($f$
          INSERT INTO %s
          (
            action, table_name, row_id,
            root_id, version,
            session_id, user_id, oauth_application_id, request_id, ip, user_agent,
            reason, diff, snapshot
          )
          VALUES
          (
            lower($1), $2, $3,
            $4, $5,
            $6,
            $7::uuid,
            $8::uuid,
            $9,
            $10::inet,
            $11,
            $12,
            $13,
            $14
          )
        $f$, v_audit_table);

        EXECUTE sql
        USING
          v_action,
          TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
          v_row_id,
          v_root_id,
          v_version,
          NULLIF(v_session_id, ''),
          NULLIF(v_user_id, ''),
          NULLIF(v_oauth_app_id, ''),
          NULLIF(v_request_id, ''),
          NULLIF(v_ip, ''),
          NULLIF(v_user_agent, ''),
          NULLIF(v_reason, ''),
          v_diff,
          v_snapshot;

        RETURN NULL; -- IMPORTANT: correct for AFTER triggers
      END;
      $$;
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION IF EXISTS sc_05_audit.fn_log_audit_event();
    SQL
  end
end
