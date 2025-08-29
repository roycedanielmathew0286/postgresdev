-- tables.sql
CREATE TABLE IF NOT EXISTS dev_schema.my_table (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
