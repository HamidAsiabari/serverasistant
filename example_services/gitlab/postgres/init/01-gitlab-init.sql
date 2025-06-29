-- GitLab PostgreSQL initialization script
-- This script runs when the PostgreSQL container starts for the first time

-- Create GitLab database
CREATE DATABASE gitlabhq_production;

-- Create GitLab user with proper permissions
CREATE USER gitlab WITH PASSWORD 'gitlab_password';

-- Grant privileges to GitLab user
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_production TO gitlab;

-- Connect to GitLab database
\c gitlabhq_production;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO gitlab;

-- Create extensions that GitLab needs
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Set proper encoding and locale
ALTER DATABASE gitlabhq_production SET client_encoding TO 'utf8';
ALTER DATABASE gitlabhq_production SET default_transaction_isolation TO 'read committed';

-- Optimize PostgreSQL settings for GitLab
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '256MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';

-- Reload configuration
SELECT pg_reload_conf();

-- Create additional databases for testing if needed
CREATE DATABASE gitlabhq_test;
CREATE DATABASE gitlabhq_development;

-- Grant privileges for test databases
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_test TO gitlab;
GRANT ALL PRIVILEGES ON DATABASE gitlabhq_development TO gitlab;

-- Create a backup user for automated backups
CREATE USER gitlab_backup WITH PASSWORD 'backup_password_secure';
GRANT CONNECT ON DATABASE gitlabhq_production TO gitlab_backup;
GRANT USAGE ON SCHEMA public TO gitlab_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO gitlab_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO gitlab_backup;

-- Set up monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create a view for database statistics
CREATE OR REPLACE VIEW db_stats AS
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY tablename, attname;

-- Grant access to monitoring views
GRANT SELECT ON db_stats TO gitlab;
GRANT SELECT ON pg_stat_statements TO gitlab; 