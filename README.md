# Wolfie's website

Sync clients, projects, and media from Notion
`bin/rails notion:sync`

Sync clients only
`bin/rails notion:sync_clients`

Sync projects from Notion
`bin/rails notion:sync_projects`

Sync media appearances from Notion
`bin/rails notion:sync_media`

Force-sync one project (by Notion page ID)
`bin/rails 'notion:sync_project[PAGE_ID]'`

Sync projects from Notion on production
`kamal app exec "bin/rails notion:sync"`

