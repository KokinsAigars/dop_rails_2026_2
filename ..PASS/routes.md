
$ bin/rails routes -g entries
Prefix Verb   URI Pattern                                        Controller#Action

full_dic_entry GET    (/:locale)/dic/entries/:id/full(.:format)          dictionary/dic/entries#full {locale: /en|lv/}

dic_entry GET    (/:locale)/dic/entries/:id(.:format)               dictionary/dic/entries#show {locale: /en|lv/}

api_v1_dic_entry_refs GET    /api/v1/dic/entries/:entry_id/refs(.:format)       api/v1/dic/entries/refs#index {format: "json"}

POST   /api/v1/dic/entries/:entry_id/refs(.:format)       api/v1/dic/entries/refs#create {format: "json"}

api_v1_dic_entry_ref GET    /api/v1/dic/entries/:entry_id/refs/:id(.:format)   api/v1/dic/entries/refs#show {format: "json"}

DELETE /api/v1/dic/entries/:entry_id/refs/:id(.:format)   api/v1/dic/entries/refs#destroy {format: "json"}

api_v1_dic_entry_notes GET    /api/v1/dic/entries/:entry_id/notes(.:format)      api/v1/dic/entries/notes#index {format: "json"}

POST   /api/v1/dic/entries/:entry_id/notes(.:format)      api/v1/dic/entries/notes#create {format: "json"}

api_v1_dic_entry_note GET    /api/v1/dic/entries/:entry_id/notes/:id(.:format)  api/v1/dic/entries/notes#show {format: "json"}

DELETE /api/v1/dic/entries/:entry_id/notes/:id(.:format)  api/v1/dic/entries/notes#destroy {format: "json"}

api_v1_dic_entry_quotes GET    /api/v1/dic/entries/:entry_id/quotes(.:format)     api/v1/dic/entries/quotes#index {format: "json"}

POST   /api/v1/dic/entries/:entry_id/quotes(.:format)     api/v1/dic/entries/quotes#create {format: "json"}

api_v1_dic_entry_quote GET    /api/v1/dic/entries/:entry_id/quotes/:id(.:format) api/v1/dic/entries/quotes#show {format: "json"}

DELETE /api/v1/dic/entries/:entry_id/quotes/:id(.:format) api/v1/dic/entries/quotes#destroy {format: "json"}

api_v1_dic_entry_egs GET    /api/v1/dic/entries/:entry_id/egs(.:format)        api/v1/dic/entries/egs#index {format: "json"}

POST   /api/v1/dic/entries/:entry_id/egs(.:format)        api/v1/dic/entries/egs#create {format: "json"}

api_v1_dic_entry_eg GET    /api/v1/dic/entries/:entry_id/egs/:id(.:format)    api/v1/dic/entries/egs#show {format: "json"}

DELETE /api/v1/dic/entries/:entry_id/egs/:id(.:format)    api/v1/dic/entries/egs#destroy {format: "json"}

api_v1_dic_entry GET    /api/v1/dic/entries/:id(.:format)                  api/v1/dic/entries#show {format: "json"}

PATCH  /api/v1/dic/entries/:id(.:format)                  api/v1/dic/entries#update {format: "json"}

PUT    /api/v1/dic/entries/:id(.:format)                  api/v1/dic/entries#update {format: "json"}



full_dic_entry
