const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

app.use(express.json());
// Très important : cela permet au serveur de lire tes fichiers HTML, CSS et images
app.use(express.static('./')); 

// Route pour récupérer tous les produits
app.get('/api/stock', (req, res) => {
    const data = JSON.parse(fs.readFileSync('data.json', 'utf8'));
    res.json(data);
});

// Route pour ajouter un produit (avec catégorie)
app.post('/api/stock', (req, res) => {
    const stock = JSON.parse(fs.readFileSync('data.json', 'utf8'));
    const nouveau = { 
        id: Date.now(), // ID unique pour chaque produit
        nom: req.body.nom, 
        prix: req.body.prix, 
        categorie: req.body.categorie 
    };
    stock.push(nouveau);
    fs.writeFileSync('data.json', JSON.stringify(stock, null, 2));
    res.json(nouveau);
});

app.listen(PORT, () => {
    console.log(`Boutique lancée sur http://localhost:${PORT}`);
});