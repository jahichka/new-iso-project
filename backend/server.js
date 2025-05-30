const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public')); // Za serviranje statičkih fajlova

// PostgreSQL konekcija
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'webapp_db',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
});

// Test konekcije sa bazom
pool.connect((err, client, release) => {
  if (err) {
    console.error('Greška prilikom konekcije sa bazom:', err.stack);
  } else {
    console.log('Uspješno povezano sa PostgreSQL bazom');
    release();
  }
});

// Kreiranje tabele korisnika ako ne postoji
async function initializeDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Tabela korisnika je kreirana ili već postoji');
  } catch (err) {
    console.error('Greška prilikom kreiranja tabele:', err);
  }
}

// Pozovi inicijalizaciju baze
initializeDatabase();

// API rute

// GET /api/users - Dohvati sve korisnike
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error('Greška prilikom dohvaćanja korisnika:', err);
    res.status(500).json({ error: 'Greška prilikom dohvaćanja korisnika' });
  }
});

// GET /api/users/:id - Dohvati jednog korisnika
app.get('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Korisnik nije pronađen' });
    }
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Greška prilikom dohvaćanja korisnika:', err);
    res.status(500).json({ error: 'Greška prilikom dohvaćanja korisnika' });
  }
});

// POST /api/users - Dodaj novog korisnika
app.post('/api/users', async (req, res) => {
  try {
    const { name, email, message } = req.body;
    
    // Validacija
    if (!name || !email) {
      return res.status(400).json({ error: 'Ime i email su obavezni' });
    }
    
    // Provjeri da li email već postoji
    const existingUser = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Korisnik sa ovim emailom već postoji' });
    }
    
    const result = await pool.query(
      'INSERT INTO users (name, email, message) VALUES ($1, $2, $3) RETURNING *',
      [name, email, message || null]
    );
    
    res.status(201).json({
      message: 'Korisnik uspješno kreiran',
      user: result.rows[0]
    });
  } catch (err) {
    console.error('Greška prilikom kreiranja korisnika:', err);
    res.status(500).json({ error: 'Greška prilikom kreiranja korisnika' });
  }
});

// PUT /api/users/:id - Ažuriraj korisnika
app.put('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, message } = req.body;
    
    // Validacija
    if (!name || !email) {
      return res.status(400).json({ error: 'Ime i email su obavezni' });
    }
    
    const result = await pool.query(
      'UPDATE users SET name = $1, email = $2, message = $3 WHERE id = $4 RETURNING *',
      [name, email, message || null, id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Korisnik nije pronađen' });
    }
    
    res.json({
      message: 'Korisnik uspješno ažuriran',
      user: result.rows[0]
    });
  } catch (err) {
    console.error('Greška prilikom ažuriranja korisnika:', err);
    res.status(500).json({ error: 'Greška prilikom ažuriranja korisnika' });
  }
});

// DELETE /api/users/:id - Obriši korisnika
app.delete('/api/users/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Korisnik nije pronađen' });
    }
    
    res.json({ message: 'Korisnik uspješno obrisan' });
  } catch (err) {
    console.error('Greška prilikom brisanja korisnika:', err);
    res.status(500).json({ error: 'Greška prilikom brisanja korisnika' });
  }
});

// Zdravstvena provjera
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Middleware za rukovanje greškama
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Nešto je pošlo po zlu!' });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Ruta nije pronađena' });
});

// Pokretanje servera
app.listen(PORT, () => {
  console.log(`Server je pokrenut na portu ${PORT}`);
  console.log(`API je dostupan na: http://localhost:${PORT}/api`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('Zatvaranje servera...');
  await pool.end();
  process.exit(0);
});