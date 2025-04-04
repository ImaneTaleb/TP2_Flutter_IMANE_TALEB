const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./shows.db');

db.serialize(() => {
    // Création de la table 'shows'
    db.run(`
        CREATE TABLE IF NOT EXISTS shows (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT CHECK(category IN ('movie', 'anime', 'serie')) NOT NULL,
            image TEXT
            );
    `);

    // Création de la table 'users'
    db.run(`
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
    );
    `);
});

module.exports = db;
