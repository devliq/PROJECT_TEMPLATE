-- Database initialization script for the project template
-- This script sets up the initial database schema and data

-- Create database if it doesn't exist
-- Note: This is handled by docker-compose environment variables

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create roles for better security
CREATE ROLE IF NOT EXISTS app_user;
CREATE ROLE IF NOT EXISTS app_admin;

-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Set search path
SET search_path TO app, public;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    role VARCHAR(50) DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- Create user profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    avatar_url VARCHAR(500),
    bio TEXT,
    website VARCHAR(255),
    location VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Create audit log table
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token_hash ON sessions(token_hash);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

-- Enable Row Level Security for enhanced security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (example - customize based on your auth system)
-- Note: These are basic examples; implement proper user context functions
CREATE POLICY users_self ON users FOR ALL USING (id = current_setting('app.current_user_id')::UUID);
CREATE POLICY user_profiles_self ON user_profiles FOR ALL USING (user_id = current_setting('app.current_user_id')::UUID);
CREATE POLICY sessions_self ON sessions FOR ALL USING (user_id = current_setting('app.current_user_id')::UUID);
CREATE POLICY audit_logs_admin ON audit_logs FOR SELECT USING (current_setting('app.user_role') = 'admin');

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Audit logging triggers
CREATE OR REPLACE FUNCTION audit_log_changes() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (user_id, action, resource_type, resource_id, old_values, new_values, ip_address, user_agent)
    VALUES (
        current_setting('app.current_user_id', true)::UUID,
        TG_OP,
        TG_TABLE_NAME,
        CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
        CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE row_to_json(OLD) END,
        CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE row_to_json(NEW) END,
        current_setting('app.current_ip', true),
        current_setting('app.current_user_agent', true)
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_log_changes();

CREATE TRIGGER audit_user_profiles AFTER INSERT OR UPDATE OR DELETE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION audit_log_changes();

CREATE TRIGGER audit_sessions AFTER INSERT OR UPDATE OR DELETE ON sessions
    FOR EACH ROW EXECUTE FUNCTION audit_log_changes();

-- Insert sample data for development
INSERT INTO users (email, username, password_hash, first_name, last_name, is_verified, role)
VALUES
    ('admin@example.com', 'admin', '$2b$10$dummy.hash.for.development', 'Admin', 'User', true, 'admin'),
    ('user@example.com', 'user', '$2b$10$dummy.hash.for.development', 'Regular', 'User', true, 'user')
ON CONFLICT (email) DO NOTHING;

-- Insert sample profiles
INSERT INTO user_profiles (user_id, bio, location, timezone)
SELECT
    u.id,
    CASE
        WHEN u.username = 'admin' THEN 'System administrator'
        ELSE 'Regular application user'
    END,
    CASE
        WHEN u.username = 'admin' THEN 'Server Room'
        ELSE 'Remote Office'
    END,
    'UTC'
FROM users u
WHERE u.username IN ('admin', 'user')
ON CONFLICT (user_id) DO NOTHING;

-- Create a view for active users
CREATE OR REPLACE VIEW active_users AS
SELECT
    u.id,
    u.email,
    u.username,
    u.first_name,
    u.last_name,
    u.role,
    u.created_at,
    u.last_login_at,
    p.bio,
    p.location,
    p.timezone
FROM users u
LEFT JOIN user_profiles p ON u.id = p.user_id
WHERE u.is_active = true;

-- Grant permissions to specific roles instead of PUBLIC for better security
GRANT USAGE ON SCHEMA app TO app_user, app_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user;
GRANT ALL ON ALL TABLES IN SCHEMA app TO app_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA app TO app_user, app_admin;

-- Create a function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sessions WHERE expires_at < CURRENT_TIMESTAMP;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Create a function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats()
RETURNS TABLE (
    total_users BIGINT,
    active_users BIGINT,
    verified_users BIGINT,
    admin_users BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) as total_users,
        COUNT(*) FILTER (WHERE is_active = true) as active_users,
        COUNT(*) FILTER (WHERE is_verified = true) as verified_users,
        COUNT(*) FILTER (WHERE role = 'admin') as admin_users
    FROM users;
END;
$$ LANGUAGE plpgsql;

-- Add comments for documentation
COMMENT ON TABLE users IS 'Main users table containing authentication and profile information';
COMMENT ON TABLE user_profiles IS 'Extended user profile information';
COMMENT ON TABLE sessions IS 'User session management';
COMMENT ON TABLE audit_logs IS 'Audit trail for user actions';
COMMENT ON VIEW active_users IS 'View of all active users with their profiles';
COMMENT ON FUNCTION cleanup_expired_sessions() IS 'Removes expired user sessions, returns count of deleted sessions';
COMMENT ON FUNCTION get_user_stats() IS 'Returns statistics about user accounts';

-- Create a development data insertion (only if in development)
DO $$
BEGIN
    IF current_database() LIKE '%dev%' OR current_database() LIKE '%test%' THEN
        -- Add development-specific data here if needed
        RAISE NOTICE 'Development database detected - additional setup can be added here';
    END IF;
END $$;

-- Connection pooling and performance configuration
-- Note: These are example settings; adjust based on your infrastructure
ALTER SYSTEM SET max_connections = 100;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Reload configuration
SELECT pg_reload_conf();