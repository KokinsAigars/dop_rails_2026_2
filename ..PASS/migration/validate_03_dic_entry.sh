#!/usr/bin/env bash
set -euo pipefail

psql -h localhost -p 5433 -U dop_dev -d dop_dev -c \
"select 'dic_entry' as t, count(*) from sc_03_dic_entry.dic_entry
union all select 'dic_index', count(*) from sc_03_dic_entry.dic_index
union all select 'dic_vocab', count(*) from sc_03_dic_entry.dic_vocab
union all select 'dic_scan', count(*) from sc_03_dic_entry.dic_scan
union all select 'dic_ref', count(*) from sc_03_dic_entry.dic_ref
union all select 'dic_eg', count(*) from sc_03_dic_entry.dic_eg
union all select 'dic_quote', count(*) from sc_03_dic_entry.dic_quote
union all select 'dic_note', count(*) from sc_03_dic_entry.dic_note;"

# export PGPASSWORD='2WlOsZw6QLPQXI3k'