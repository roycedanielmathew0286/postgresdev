-- 00_init.sql: Entry point
-- Connect to dynamically created database
\c __PG_DB__

-- Include other SQL files in order
\i /sql_scripts/schemas.sql
\i /sql_scripts/tables.sql
\i /sql_scripts/data.sql
