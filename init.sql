-- Kreiranje baze podataka (ako se pokreće kao superuser)
-- CREATE DATABASE webapp_db;

-- Korištenje baze
\c webapp_db;

-- Kreiranje tabele korisnika
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kreiranje indeksa za bolje performanse
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Kreiranje trigera za automatsko ažuriranje updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Dodavanje početnih test podataka
INSERT INTO users (name, email, message) VALUES 
    ('Marko Marković', 'marko@example.com', 'Dobrodošli u našu novu aplikaciju!'),
    ('Ana Anić', 'ana@example.com', 'Odličan dizajn i funkcionalnost.'),
    ('Petar Petrović', 'petar@example.com', 'Sve radi kako treba!')
ON CONFLICT (email) DO NOTHING;

-- Kreiranje view-a za statistike
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as new_users_week,
    COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_users_month
FROM users;

-- Kreiranje stored procedure za čišćenje starih zapisa (opciono)
CREATE OR REPLACE FUNCTION cleanup_old_users(days_old INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM users 
    WHERE created_at < CURRENT_DATE - INTERVAL '1 day' * days_old
    AND message IS NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Kreiranje korisnika za aplikaciju (opciono - za produkciju)
-- CREATE USER webapp_user WITH PASSWORD 'webapp_password';
-- GRANT CONNECT ON DATABASE webapp_db TO webapp_user;
-- GRANT USAGE ON SCHEMA public TO webapp_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON users TO webapp_user;
-- GRANT USAGE, SELECT ON SEQUENCE users_id_seq TO webapp_user;

-- Dodavanje komentara
COMMENT ON TABLE users IS 'Tabela korisnika aplikacije';
COMMENT ON COLUMN users.id IS 'Jedinstveni identifikator korisnika';
COMMENT ON COLUMN users.name IS 'Ime i prezime korisnika';
COMMENT ON COLUMN users.email IS 'Email adresa korisnika (jedinstvena)';
COMMENT ON COLUMN users.message IS 'Poruka korisnika (opciono)';
COMMENT ON COLUMN users.created_at IS 'Datum i vrijeme kreiranja';
COMMENT ON COLUMN users.updated_at IS 'Datum i vrijeme poslednje izmjene';

-- Log za završetak inicijalizacije
SELECT 'Baza podataka uspješno inicijalizovana!' as status;