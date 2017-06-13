# Make a backup

```bash
pg_dump -Fc --no-acl --no-owner -h localhost -U {same-username-as-your-rails-app} {database-name} > {path-to-pgdump-file}
```

# Restore it

```bash
psql -U {same-username-as-your-rails-app} {database-name} < {path-to-pgsql-file}
```

* Create the DB as your rails-app db user or you get permissions problems later on
