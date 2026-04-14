import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getFirestore, collection, onSnapshot } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

// 1. Configuration Firebase
const firebaseConfig = {
    apiKey: "AIzaSyCr87n6c40d3vLLPHDEw2MpVSRxPVhQXZU",
    authDomain: "terang-art.firebaseapp.com",
    projectId: "terang-art",
    storageBucket: "terang-art.firebasestorage.app",
    messagingSenderId: "83033431595",
    appId: "1:83033431595:web:9b0ec75e4aed126262616e"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// 2. Gestion du Panier (Lecture immédiate du localStorage)
let panier = JSON.parse(localStorage.getItem('monPanier')) || [];

// Mise à jour du petit chiffre sur l'icône du panier
window.majCompteur = function() {
    const compteur = document.getElementById('cart-count');
    if (compteur) {
        compteur.innerText = panier.length;
        // Correction : On utilise 'flex' pour un meilleur centrage si possible
        compteur.style.display = panier.length > 0 ? "flex" : "none";
    }
};

// FORCE l'affichage dès que le script est chargé (Important pour l'index !)
window.majCompteur();

window.ajouterAuPanier = function(nom, prix, idTaille, idCouleur, idQty) {
    const taille = document.getElementById(idTaille).value;
    const couleur = document.getElementById(idCouleur).value;
    const quantite = parseInt(document.getElementById(idQty).value);

    panier.push({ nom, prix, taille, couleur, quantite });
    localStorage.setItem('monPanier', JSON.stringify(panier));
    window.majCompteur();
    alert(`✅ ${nom} ajouté au panier !`);
};

window.ouvrirPanier = function() {
    const modal = document.getElementById('cart-modal');
    const itemsDiv = document.getElementById('cart-items');
    const totalSpan = document.getElementById('total-price');
    if (!modal) return;

    itemsDiv.innerHTML = "";
    let total = 0;

    if (panier.length === 0) {
        itemsDiv.innerHTML = "<p style='text-align:center; padding:20px;'>Votre panier est vide.</p>";
    } else {
        panier.forEach((item, index) => {
            total += item.prix * item.quantite;
            itemsDiv.innerHTML += `
                <div class="cart-item" style="border-bottom:1px solid #eee; padding:10px; margin-bottom:10px; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <p style="margin:0;"><strong>${item.nom}</strong></p>
                        <p style="margin:0;"><small>${item.taille} | ${item.couleur}</small></p>
                        <p style="margin:0;">${item.quantite} x ${item.prix.toLocaleString()} FCFA</p>
                    </div>
                    <button onclick="supprimerArticle(${index})" style="color:red; border:none; background:none; cursor:pointer; font-size:1.1rem;">&times;</button>
                </div>`;
        });
    }

    totalSpan.innerText = total.toLocaleString();
    modal.style.display = "flex";
};

window.fermerPanier = function() {
    document.getElementById('cart-modal').style.display = "none";
};

window.supprimerArticle = function(index) {
    panier.splice(index, 1);
    localStorage.setItem('monPanier', JSON.stringify(panier));
    window.ouvrirPanier();
    window.majCompteur();
};

// 3. Commande WhatsApp
window.envoyerCommandeWhatsApp = function() {
    if (panier.length === 0) {
        alert("Votre panier est vide !");
        return;
    }
    let message = "Bonjour TERANG'ART, voici ma commande :\n\n";
    let totalGlobal = 0;
    panier.forEach(item => {
        message += `🛍️ *${item.nom}*\n📏 Taille: ${item.taille}\n🎨 Couleur: ${item.couleur}\n🔢 Qté: ${item.quantite}\n💰 Sous-total: ${item.prix * item.quantite} FCFA\n\n`;
        totalGlobal += item.prix * item.quantite;
    });
    message += `━━━━━━━━━━━━━━━\n💵 *TOTAL À PAYER : ${totalGlobal.toLocaleString()} FCFA*`;
    const telephone = "221773912100";
    window.open(`https://wa.me/${telephone}?text=${encodeURIComponent(message)}`, '_blank');
};

// 4. Chargement des produits
function chargerProduitsCloud() {
    onSnapshot(collection(db, "produits"), (snapshot) => {
        const containers = {
            'habillement': document.getElementById('liste-produits-hab'),
            'accessoires': document.getElementById('liste-produits-acc'),
            'cosmetiques': document.getElementById('liste-produits-cos')
        };

        Object.values(containers).forEach(div => { if(div) div.innerHTML = ""; });

        snapshot.forEach((docSnap) => {
            const p = docSnap.data();
            const container = containers[p.cat];

            if (container) {
                const idUnique = docSnap.id;
                const optionsTaille = p.tailles ? p.tailles.split(',').map(t => `<option value="${t.trim()}">${t.trim()}</option>`).join('') : '<option value="Standard">Standard</option>';
                const optionsCouleur = p.couleurs ? p.couleurs.split(',').map(c => `<option value="${c.trim()}">${c.trim()}</option>`).join('') : '<option value="Unique">Unique</option>';
                
                const cheminImage = p.img.startsWith('http') ? p.img : `images/${p.img}`;

                container.innerHTML += `
                    <div class="product-card">
                        <div class="product-image">
                            <img src="${cheminImage}" onerror="this.src='images/placeholder.jpg'">
                        </div>
                        <div class="product-info">
                            <h3>${p.nom}</h3>
                            <p class="price">${Number(p.prix).toLocaleString()} FCFA</p>
                            <div class="product-options">
                                <select id="taille-${idUnique}" class="product-select">${optionsTaille}</select>
                                <select id="couleur-${idUnique}" class="product-select">${optionsCouleur}</select>
                                <input type="number" id="qty-${idUnique}" class="product-qty" value="1" min="1">
                            </div>
                            <button onclick="ajouterAuPanier('${p.nom.replace(/'/g, "\\'")}', ${p.prix}, 'taille-${idUnique}', 'couleur-${idUnique}', 'qty-${idUnique}')" class="buy-wa">
                                Ajouter au panier
                            </button>
                        </div>
                    </div>`;
            }
        });
    });
}

// 5. Lancement au démarrage
document.addEventListener('DOMContentLoaded', () => {
    window.majCompteur();
    chargerProduitsCloud();
});