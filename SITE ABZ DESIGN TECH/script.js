// --- 1. CONFIGURATION FIREBASE ---
const firebaseConfig = {
    apiKey: "AIzaSyCBhvDjA3PDeM54vtfPCezkdyczyTAVtOw",
    authDomain: "abz-design-tech.firebaseapp.com",
    projectId: "abz-design-tech",
    storageBucket: "abz-design-tech.firebasestorage.app",
    messagingSenderId: "228872777031",
    appId: "1:228872777031:web:5235c1ee176bb903b73062",
    databaseURL: "https://abz-design-tech-default-rtdb.europe-west1.firebasedatabase.app"
};

let catalogueComplet = []; 
let panier = JSON.parse(localStorage.getItem('abz_panier')) || [];

if (!firebase.apps.length) {
    firebase.initializeApp(firebaseConfig);
}
const db = firebase.database();

// --- 2. GESTION DU PANIER ---
function ajouterAuPanier(nom, prix) {
    panier.push({ nom, prix: parseInt(prix) });
    localStorage.setItem('abz_panier', JSON.stringify(panier));
    mettreAJourCompteur();
    if(typeof chargerPagePanier === "function") chargerPagePanier();
    alert("✅ " + nom + " ajouté au panier !");
}

function mettreAJourCompteur() {
    const count = document.getElementById('cart-count');
    if(count) count.innerText = panier.length;
}

// --- 3. CHARGEMENT DYNAMIQUE DES PRODUITS ---
function chargerProduitsPublics(secteurCible) {
    console.log("Chargement du secteur :", secteurCible);
    db.ref('stock').on('value', (snapshot) => {
        const data = snapshot.val();
        if (!data) {
            console.warn("Aucune donnée trouvée dans Firebase.");
            return;
        }

        catalogueComplet = [];
        Object.keys(data).forEach(key => {
            let item = data[key];
            item.id = key; 
            catalogueComplet.push(item);
        });

        const containers = {
            reseaux: document.getElementById('container-reseaux'),
            cablage: document.getElementById('container-cablage'),
            fibre: document.getElementById('container-fibre'),
            surveillance: document.getElementById('container-surveillance'),
            acces: document.getElementById('container-acces'),
            domotique: document.getElementById('container-domotique'),
            tableau: document.getElementById('container-tableau'),
            solaire: document.getElementById('container-solaire'),
            general: document.getElementById('produits-container')
        };

        // Vider les containers existants
        Object.values(containers).forEach(c => { if(c) c.innerHTML = ""; });

        catalogueComplet.forEach(p => {
            if (p.secteur === secteurCible || secteurCible === "Tous") {
                const descComplete = p.description || "Aucune description.";
                const descAffichee = descComplete.length > 100 ? descComplete.substring(0, 100) + "..." : descComplete;
                
                // Nettoyage des apostrophes pour le onclick
                const nomEscaped = p.nom.replace(/'/g, "\\'");
                const descEscaped = descComplete.replace(/'/g, "\\'").replace(/\n/g, " ");

                const cardHTML = `
                    <div class="product-card" data-nom="${p.nom}" onclick="ouvrirDetail('${nomEscaped}', '${p.image}', '${descEscaped}', ${p.prix}, ${p.stock}, '${p.reference || ''}')">
                        <div class="product-img">
                            <span class="product-ref-badge">${p.reference || 'REF'}</span>
                            <img src="${p.image}" alt="${p.nom}" onerror="this.src='images/default.jpg'">
                        </div>
                        <div class="product-info">
                            <h3>${p.nom}</h3>
                            <p class="product-description">${descAffichee}</p>
                            <div class="price-action">
                                <span class="price">${parseInt(p.prix).toLocaleString()} F</span>
                                <button class="btn-add-cart" onclick="event.stopPropagation(); ajouterAuPanier('${nomEscaped}', ${p.prix})">
                                    <i class="fas fa-plus"></i>
                                </button>
                            </div>
                        </div>
                    </div>`;

                if (secteurCible === "Informatique") {
                    if (p.sousCat === "Équipements Réseaux & Connectivité" && containers.reseaux) containers.reseaux.innerHTML += cardHTML;
                    else if (p.sousCat === "Solutions de Câblage Ethernet" && containers.cablage) containers.cablage.innerHTML += cardHTML;
                    else if (p.sousCat === "Infrastructure Fibre Optique" && containers.fibre) containers.fibre.innerHTML += cardHTML;
                } 
                else if (secteurCible === "Sécurité") {
                    if (p.sousCat === "Équipements de Surveillance IP" && containers.surveillance) containers.surveillance.innerHTML += cardHTML;
                    else if (p.sousCat === "Contrôle d'accès" && containers.acces) containers.acces.innerHTML += cardHTML;
                    else if (p.sousCat === "Domotique & Protection Intrusion" && containers.domotique) containers.domotique.innerHTML += cardHTML;
                }
                else if (secteurCible === "Électrique") {
                    if (p.sousCat === "Protection & Tableau Électrique" && containers.tableau) containers.tableau.innerHTML += cardHTML;
                    else if (p.sousCat === "Solaire & Autonomie Énergétique" && containers.solaire) containers.solaire.innerHTML += cardHTML;
                }
                if (containers.general) containers.general.innerHTML += cardHTML;
            }
        });
        
        verifierRedirectionRecherche();
    });
}

// --- 4. RECHERCHE ET REDIRECTION ---
function filtrerArticles() {
    const input = document.getElementById('search-input').value.toLowerCase().trim();
    const resultsContainer = document.getElementById('search-results');
    if (input.length < 2) {
        resultsContainer.style.display = "none";
        return;
    }

    const trouves = catalogueComplet.filter(p => 
        (p.nom || "").toLowerCase().includes(input) || (p.reference || "").toLowerCase().includes(input)
    );

    resultsContainer.innerHTML = "";
    if (trouves.length > 0) {
        trouves.forEach(p => {
            const div = document.createElement('div');
            div.className = "suggestion-item";
            div.innerHTML = `<span>${p.nom}</span> <small>${p.prix} F</small>`;
            div.onclick = () => {
                let page = "index.html";
                if(p.secteur === "Informatique") page = "informatique.html";
                if(p.secteur === "Sécurité") page = "securite.html";
                if(p.secteur === "Électrique") page = "electrique.html";
                window.location.href = `${page}?goto=${encodeURIComponent(p.nom)}`;
            };
            resultsContainer.appendChild(div);
        });
        resultsContainer.style.display = "block";
    }
}

// Fonction pour scroller automatiquement vers un produit après redirection
function verifierRedirectionRecherche() {
    const urlParams = new URLSearchParams(window.location.search);
    const nomCible = urlParams.get('goto');
    if (nomCible) {
        const nomDecoded = decodeURIComponent(nomCible);
        const cartes = document.querySelectorAll('.product-card');
        cartes.forEach(c => {
            if (c.getAttribute('data-nom') === nomDecoded) {
                c.scrollIntoView({ behavior: 'smooth', block: 'center' });
                c.style.outline = "3px solid #0062ff";
                setTimeout(() => c.click(), 500);
            }
        });
    }
}

/// --- 5. MODALE DETAIL ---
function ouvrirDetail(nom, image, desc, prix, stock, ref) {
    const modal = document.getElementById('product-modal');
    if (!modal) return;

    // 1. Remplissage des textes
    if (document.getElementById('modal-title')) document.getElementById('modal-title').innerText = nom;
    if (document.getElementById('modal-desc')) document.getElementById('modal-desc').innerText = desc || "Aucune description.";
    if (document.getElementById('modal-price')) document.getElementById('modal-price').innerText = parseInt(prix).toLocaleString() + " F";
    
    const refEl = document.getElementById('modal-ref');
    if (refEl) refEl.innerText = "REF: " + (ref || 'N/A');

    // 2. Gestion de l'image et du ZOOM
    const img = document.getElementById('modal-img');
    const container = img.parentElement; // Le conteneur .modal-img-container

    if (img) {
        img.src = image;
        img.style.transform = "scale(1)"; // Reset le zoom à l'ouverture
        
        // Effet de zoom au mouvement de la souris
        container.onmousemove = (e) => {
            // Calcule la position de la souris par rapport au conteneur
            const x = e.offsetX;
            const y = e.offsetY;
            
            img.style.transformOrigin = `${x}px ${y}px`;
            img.style.transform = "scale(2.5)"; // Niveau de zoom (2.5 fois)
        };

        // Reset quand la souris sort
        container.onmouseleave = () => {
            img.style.transform = "scale(1)";
            img.style.transformOrigin = "center";
        };
    }

    // 3. Gestion du bouton panier
    let footer = document.querySelector('.modal-footer-action');
    if (!footer) {
        footer = document.createElement('div');
        footer.className = 'modal-footer-action';
        modal.querySelector('.modal-content').appendChild(footer);
    }

    const nomEscaped = nom.replace(/'/g, "\\'");
    footer.innerHTML = `
        <button class="btn-modal-add" onclick="ajouterAuPanier('${nomEscaped}', ${prix})">
            <i class="fas fa-shopping-cart"></i> Ajouter au panier
        </button>
    `;

    modal.style.display = 'flex';
}
function fermerDetail() {
    document.getElementById('product-modal').style.display = 'none';
}

// Initialisation
document.addEventListener('DOMContentLoaded', () => {
    mettreAJourCompteur();
});
// SECURITÉ : Fermer si on clique en dehors du cadre blanc
window.onclick = function(event) {
    const modalDetail = document.getElementById('product-modal');
    const modalPanier = document.getElementById('cart-modal');
    
    if (event.target == modalDetail) {
        fermerDetail();
    }
    if (event.target == modalPanier) {
        fermerPanier();
    }
}

function fermerDetail() {
    document.getElementById('product-modal').style.display = 'none';
}

// --- 4. NAVIGATION & MODALE ---
function ouvrirPanier() {
    const modal = document.getElementById('cart-modal');
    if (modal) {
        modal.style.display = 'flex';
        chargerPagePanier();
    }
}

function fermerPanier() {
    const modal = document.getElementById('cart-modal');
    if (modal) modal.style.display = 'none';
}

window.onclick = function(event) {
    const modal = document.getElementById('cart-modal');
    if (event.target == modal) modal.style.display = "none";
}

// --- 5. AFFICHAGE DU PANIER ---
function chargerPagePanier() {
    const conteneur = document.getElementById('liste-panier'); 
    const affichageTotal = document.getElementById('total-panier');
    
    if (!conteneur) return;

    conteneur.innerHTML = "";
    let total = 0;

    if (panier.length === 0) {
        conteneur.innerHTML = `<p style="text-align:center; padding:20px; color:#888;">Votre panier est vide.</p>`;
        if(affichageTotal) affichageTotal.innerText = "0";
        return;
    }

    panier.forEach((item, index) => {
        total += parseInt(item.prix);
        conteneur.innerHTML += `
            <div class="item-panier" style="display:flex; justify-content:space-between; align-items:center; padding:10px; border-bottom:1px solid #eee;">
                <div>
                    <h4 style="margin:0; font-size:0.9rem;">${item.nom}</h4>
                    <span style="color:#0062ff; font-weight:bold;">${item.prix.toLocaleString()} FCFA</span>
                </div>
                <button onclick="supprimerDuPanier(${index})" style="background:none; border:none; color:#dc3545; cursor:pointer; font-size:1.1rem;">
                    <i class="fas fa-trash-alt"></i>
                </button>
            </div>`;
    });

    if(affichageTotal) affichageTotal.innerText = total.toLocaleString();
}

function supprimerDuPanier(index) {
    panier.splice(index, 1);
    localStorage.setItem('abz_panier', JSON.stringify(panier));
    mettreAJourCompteur();
    chargerPagePanier();
}

// --- 6. COMMANDE WHATSAPP ---
function envoyerCommandeWhatsApp() {
    if (panier.length === 0) return alert("Votre panier est vide !");
    
    let message = "Bonjour ABZ DESIGN TECH, voici ma commande :%0A%0A";
    let total = 0;
    
    panier.forEach(item => {
        message += "• " + item.nom + " (" + item.prix.toLocaleString() + " FCFA)%0A";
        total += item.prix;
    });
    
    message += "%0A*Total : " + total.toLocaleString() + " FCFA*";
    const telephone = "221773912100";
    window.open(`https://wa.me/${telephone}?text=${message}`);
}

// --- 7. THÈME & INITIALISATION ---
const themeToggle = document.getElementById('theme-toggle');
if (themeToggle) {
    if (localStorage.getItem('theme') === 'dark') document.body.classList.add('dark-mode');
    themeToggle.addEventListener('click', () => {
        document.body.classList.toggle('dark-mode');
        const isDark = document.body.classList.contains('dark-mode');
        localStorage.setItem('theme', isDark ? 'dark' : 'light');
        themeToggle.innerHTML = isDark ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
    });
}

document.addEventListener('DOMContentLoaded', () => {
    mettreAJourCompteur();
});
function afficherDetails(nom, texte) {
    alert("Détails de " + nom + " :\n\n" + texte);
}

// --- Fonction de Zoom (Loupe) ---
function imageZoom(imgID, lensClass) {
    let img, lens, result, cx, cy;
    img = document.getElementById(imgID);
    
    // Créer la loupe dynamiquement
    lens = document.createElement("DIV");
    lens.setAttribute("class", lensClass);
    
    // Insérer la loupe avant l'image
    img.parentElement.insertBefore(lens, img);
    
    // Calculer le ratio entre la loupe et l'image zoomée (x2 ici)
    cx = lens.offsetWidth / (lens.offsetWidth / 2); 
    cy = lens.offsetHeight / (lens.offsetHeight / 2);
    
    // Définir l'image de fond de la loupe (la même que l'image d'origine)
    lens.style.backgroundImage = "url('" + img.src + "')";
    lens.style.backgroundSize = (img.width * cx) + "px " + (img.height * cy) + "px";
    
    // Événements pour la souris et le tactile
    lens.addEventListener("mousemove", moveLens);
    img.addEventListener("mousemove", moveLens);
    lens.addEventListener("touchmove", moveLens);
    img.addEventListener("touchmove", moveLens);
    
    function moveLens(e) {
        let pos, x, y;
        // Empêcher le comportement par défaut (scroll sur mobile)
        e.preventDefault();
        // Obtenir les coordonnées de la souris/du doigt
        pos = getCursorPos(e);
        // Calculer la position de la loupe
        x = pos.x - (lens.offsetWidth / 2);
        y = pos.y - (lens.offsetHeight / 2);
        
        // Empêcher la loupe de sortir de l'image
        if (x > img.width - lens.offsetWidth) {x = img.width - lens.offsetWidth;}
        if (x < 0) {x = 0;}
        if (y > img.height - lens.offsetHeight) {y = img.height - lens.offsetHeight;}
        if (y < 0) {y = 0;}
        
        // Définir la position de la loupe
        lens.style.left = x + "px";
        lens.style.top = y + "px";
        
        // Définir la position de l'image de fond de la loupe (le zoom)
        lens.style.backgroundPosition = "-" + (x * cx) + "px -" + (y * cy) + "px";
    }
    
    function getCursorPos(e) {
        let a, x = 0, y = 0;
        e = e || window.event;
        // Obtenir les coordonnées de l'image
        a = img.getBoundingClientRect();
        // Calculer les coordonnées relatives à l'image
        x = e.pageX - a.left;
        y = e.pageY - a.top;
        // Prendre en compte le scroll de la page
        x = x - window.pageXOffset;
        y = y - window.pageYOffset;
        return {x : x, y : y};
    }
}
// ==========================================
// 1. GESTION DE LA MODALE
// ==========================================

function ouvrirModalConnexion() {
    const modal = document.getElementById('auth-modal');
    if (modal) modal.style.display = 'flex';
}

function fermerModalAuth() {
    const modal = document.getElementById('auth-modal');
    if (modal) modal.style.display = 'none';
}

// Fermeture si on clique à l'extérieur de la modale
window.onclick = function(event) {
    const modal = document.getElementById('auth-modal');
    if (event.target == modal) {
        modal.style.display = "none";
    }
}

// Basculer entre Connexion et Inscription
function switchAuth(mode) {
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    
    if (mode === 'register') {
        if(loginForm) loginForm.style.display = 'none';
        if(registerForm) registerForm.style.display = 'block';
    } else {
        if(loginForm) loginForm.style.display = 'block';
        if(registerForm) registerForm.style.display = 'none';
    }
}

// ==========================================
// 2. AUTHENTIFICATION FIREBASE
// ==========================================

// Fonction de connexion Google
function connexionGoogle() {
    const provider = new firebase.auth.GoogleAuthProvider();

    firebase.auth().signInWithPopup(provider)
        .then((result) => {
            console.log("Connecté avec succès :", result.user.displayName);
            fermerModalAuth(); 
            alert("Bienvenue " + result.user.displayName + " !");
        })
        .catch((error) => {
            console.error("Erreur Google Auth :", error.code, error.message);
            
            // Diagnostics précis pour l'utilisateur
            if (error.code === 'auth/operation-not-allowed') {
                alert("Erreur : Google n'est pas activé dans la console Firebase.");
            } else if (error.code === 'auth/unauthorized-domain') {
                alert("Erreur : Ce domaine n'est pas autorisé. Ajoutez-le dans Firebase > Authentication > Settings.");
            } else if (error.code === 'auth/popup-closed-by-user') {
                console.log("Fenêtre fermée par l'utilisateur");
            } else {
                alert("La connexion a échoué : " + error.message);
            }
        });
}

// Fonction de déconnexion
function deconnexion() {
    firebase.auth().signOut().then(() => {
        alert("Déconnexion réussie !");
        location.reload(); 
    }).catch((error) => {
        console.error("Erreur de déconnexion:", error);
    });
}

// ==========================================
// 3. OBSERVATEUR D'ÉTAT (TEMPS RÉEL)
// ==========================================

firebase.auth().onAuthStateChanged((user) => {
    const userText = document.querySelector('.user-text');
    const userContainer = document.querySelector('.user-account-container');

    if (userText && userContainer) {
        if (user) {
            // Utilisateur connecté
            console.log("Utilisateur actif :", user.displayName);
            userText.innerText = user.displayName ? user.displayName.split(' ')[0] : "Mon Compte";
            userContainer.style.color = "#ffcc00"; // Couleur or
            
            // On change l'action : Cliquer propose désormais la déconnexion
            userContainer.onclick = function() {
                if(confirm("Voulez-vous vous déconnecter de votre compte ABZ ?")) {
                    deconnexion();
                }
            };
        } else {
            // Utilisateur déconnecté
            userText.innerText = "Connexion";
            userContainer.style.color = "";
            userContainer.onclick = ouvrirModalConnexion;
        }
    }
});
function demarrerSlider() {
    const slides = document.querySelectorAll('.slide');
    let indexCourant = 0;

    if (slides.length > 0) {
        setInterval(() => {
            // Retirer la classe active de l'image actuelle
            slides[indexCourant].classList.remove('active');

            // Passer à l'image suivante (boucle à la fin)
            indexCourant = (indexCourant + 1) % slides.length;

            // Ajouter la classe active à la nouvelle image
            slides[indexCourant].classList.add('active');
        }, 4000); // Change toutes les 4 secondes
    }
}

// Lancer le slider au chargement de la page
document.addEventListener('DOMContentLoaded', demarrerSlider);
window.onscroll = function() { fixNav() };

const nav = document.querySelector(".nav-sticky");
const sticky = nav.offsetTop; // Détecte la position d'origine de la barre

function fixNav() {
  if (window.pageYOffset > sticky) {
    nav.classList.add("is-fixed");
  } else {
    nav.classList.remove("is-fixed");
  }
}
let deferredPrompt;
const installBtn = document.getElementById('install-btn');

// On écoute l'événement magique de Chrome
window.addEventListener('beforeinstallprompt', (e) => {
    // 1. On empêche Chrome d'afficher sa propre petite barre en bas
    e.preventDefault();
    // 2. On stocke l'événement pour plus tard
    deferredPrompt = e;
    // 3. On rend ton beau bouton visible
    installBtn.style.display = 'block';
    console.log("✅ L'installation est prête, le bouton va fonctionner !");
});

// Ce qui se passe quand on clique sur TON bouton
installBtn.addEventListener('click', () => {
    if (deferredPrompt) {
        // Affiche la fenêtre d'installation officielle
        deferredPrompt.prompt();
        
        // Attend la réponse de l'utilisateur (Installer ou Annuler)
        deferredPrompt.userChoice.then((choiceResult) => {
            if (choiceResult.outcome === 'accepted') {
                console.log('L’utilisateur a installé ABZ Tech !');
            } else {
                console.log('L’utilisateur a annulé l’installation');
            }
            deferredPrompt = null;
        });
    } else {
        alert("L'installation n'est pas encore prête. Vérifiez que l'app n'est pas déjà installée !");
    }
});

// On cache le bouton une fois installé
window.addEventListener('appinstalled', () => {
    installBtn.style.display = 'none';
    deferredPrompt = null;
    console.log('PWA installée !');
});
// Effet de texte dynamique
const titleElement = document.querySelector('h1');
const words = ["Sécurité", "Expert", "Succès"];
let wordIndex = 0;
let charIndex = 0;
let isDeleting = false;

function typeEffect() {
    const currentWord = words[wordIndex];
    const displayText = isDeleting 
        ? currentWord.substring(0, charIndex--) 
        : currentWord.substring(0, charIndex++);

    titleElement.innerHTML = `ABZ DESIGN TECH : Votre <span style="color:#FFD700">${displayText}</span> à Dakar`;

    if (!isDeleting && charIndex === currentWord.length + 1) {
        isDeleting = true;
        setTimeout(typeEffect, 1500); // Pause à la fin du mot
    } else if (isDeleting && charIndex === 0) {
        isDeleting = false;
        wordIndex = (wordIndex + 1) % words.length;
        setTimeout(typeEffect, 500);
    } else {
        setTimeout(typeEffect, isDeleting ? 50 : 100);
    }
}

