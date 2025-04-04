const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../database');  // Assurez-vous que vous avez configuré correctement votre DB

const router = express.Router();
router.get('/', (req, res) => {
    db.all('SELECT * FROM users', [], (err, rows) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(rows);
    });
});

// Fonction de validation et d'enregistrement
const validateRegistration = [
    body('email').isEmail().withMessage('Please enter a valid email').normalizeEmail(),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('name').notEmpty().withMessage('Name is required'),
];

// Route pour l'enregistrement d'un utilisateur
router.post('/register', validateRegistration, async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, name } = req.body;

    try {
        // Vérifier si l'utilisateur existe déjà
        db.get('SELECT * FROM users WHERE email = ?', [email], async (err, row) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }

            if (row) {
                return res.status(400).json({ error: 'Email already in use' });
            }

            // Hacher le mot de passe
            const hashedPassword = await bcrypt.hash(password, 10);

            // Insérer l'utilisateur dans la base de données
            db.run(
                'INSERT INTO users (username, email, password) VALUES (?, ?, ?)',
                [name, email, hashedPassword],
                function (err) {
                    if (err) {
                        return res.status(500).json({ error: err.message });
                    }

                    res.status(201).json({ message: 'User created successfully', id: this.lastID });
                }
            );
        });
    } catch (err) {
        res.status(500).json({ error: 'An error occurred while processing your request' });
    }
});

// Route pour la connexion (login)
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        db.get('SELECT * FROM users WHERE email = ?', [email], async (err, row) => {
            if (err) {
                return res.status(500).json({ error: err.message });
            }

            if (!row) {
                return res.status(400).json({ error: 'Invalid credentials' });
            }

            // Comparer le mot de passe avec celui stocké
            const match = await bcrypt.compare(password, row.password);
            if (!match) {
                return res.status(400).json({ error: 'Invalid credentials' });
            }

            // Générer un token JWT
            const token = jwt.sign({ userId: row.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
            const name=row.name;
            delete row.password;

            res.json({
                message: 'Login successful',
                token: token,
                user : row


            });
        });
    } catch (err) {
        res.status(500).json({ error: 'An error occurred while processing your request' });
    }
});



module.exports = router;
