-- EAI Configuration Database Initialization
-- This script sets up the basic schema for EAI adapter configuration

-- Create adapter configurations table
CREATE TABLE IF NOT EXISTS adapter_configs (
    id SERIAL PRIMARY KEY,
    adapter_name VARCHAR(100) NOT NULL UNIQUE,
    adapter_type VARCHAR(50) NOT NULL,
    config_json JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create adapter routes table
CREATE TABLE IF NOT EXISTS adapter_routes (
    id SERIAL PRIMARY KEY,
    adapter_name VARCHAR(100) NOT NULL,
    route_id VARCHAR(100) NOT NULL,
    route_config JSONB NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adapter_name) REFERENCES adapter_configs(adapter_name) ON DELETE CASCADE
);

-- Create adapter metrics table for business metrics
CREATE TABLE IF NOT EXISTS adapter_metrics (
    id SERIAL PRIMARY KEY,
    adapter_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL,
    metric_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    labels JSONB,
    FOREIGN KEY (adapter_name) REFERENCES adapter_configs(adapter_name) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_adapter_configs_name ON adapter_configs(adapter_name);
CREATE INDEX IF NOT EXISTS idx_adapter_configs_type ON adapter_configs(adapter_type);
CREATE INDEX IF NOT EXISTS idx_adapter_routes_adapter ON adapter_routes(adapter_name);
CREATE INDEX IF NOT EXISTS idx_adapter_routes_route_id ON adapter_routes(route_id);
CREATE INDEX IF NOT EXISTS idx_adapter_metrics_adapter ON adapter_metrics(adapter_name);
CREATE INDEX IF NOT EXISTS idx_adapter_metrics_timestamp ON adapter_metrics(metric_timestamp);

-- Insert default configurations
INSERT INTO adapter_configs (adapter_name, adapter_type, config_json) VALUES
('eai-adapter-sample', 'sample', '{
    "polling_interval": 30000,
    "batch_size": 100,
    "retry_attempts": 3,
    "timeout": 10000
}') ON CONFLICT (adapter_name) DO NOTHING;

INSERT INTO adapter_configs (adapter_name, adapter_type, config_json) VALUES
('eai-adapter-orders', 'orders', '{
    "polling_interval": 60000,
    "batch_size": 50,
    "retry_attempts": 5,
    "timeout": 15000,
    "database_connection_pool_size": 10
}') ON CONFLICT (adapter_name) DO NOTHING;

INSERT INTO adapter_configs (adapter_name, adapter_type, config_json) VALUES
('eai-adapter-products', 'products', '{
    "polling_interval": 120000,
    "batch_size": 200,
    "retry_attempts": 3,
    "timeout": 20000,
    "cache_ttl": 300
}') ON CONFLICT (adapter_name) DO NOTHING;

-- Insert default routes
INSERT INTO adapter_routes (adapter_name, route_id, route_config) VALUES
('eai-adapter-sample', 'data-processing-route', '{
    "from": "timer:processData?period=30000",
    "to": ["direct:fetchData", "direct:transformData"],
    "error_handler": "deadLetterChannel:direct:error"
}') ON CONFLICT DO NOTHING;

INSERT INTO adapter_routes (adapter_name, route_id, route_config) VALUES
('eai-adapter-orders', 'order-processing-route', '{
    "from": "timer:processOrders?period=60000",
    "to": ["direct:fetchOrders", "direct:validateOrders", "direct:processOrders"],
    "error_handler": "deadLetterChannel:direct:orderError"
}') ON CONFLICT DO NOTHING;

INSERT INTO adapter_routes (adapter_name, route_id, route_config) VALUES
('eai-adapter-products', 'product-sync-route', '{
    "from": "timer:syncProducts?period=120000",
    "to": ["direct:fetchProducts", "direct:transformProducts", "direct:syncProducts"],
    "error_handler": "deadLetterChannel:direct:productError"
}') ON CONFLICT DO NOTHING;

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
CREATE TRIGGER update_adapter_configs_updated_at BEFORE UPDATE ON adapter_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_adapter_routes_updated_at BEFORE UPDATE ON adapter_routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create user for application access
CREATE USER eai_app_user WITH PASSWORD 'eai_app_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON adapter_configs TO eai_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON adapter_routes TO eai_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON adapter_metrics TO eai_app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO eai_app_user;
