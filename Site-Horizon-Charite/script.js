document.addEventListener('DOMContentLoaded', () => {

    // --- 1. GESTION DES DONS (Redirections) ---
    const btnLocal = document.getElementById('btn-pay-local');
    const btnInter = document.getElementById('btn-pay-inter');

    if (btnLocal) {
        btnLocal.onclick = function() {
            this.innerText = "Redirection...";
            // Remplace par ton lien réel Kopar Express
            window.location.href = "https://apps.koparexpress.com/apps/collectes/xvr81rg92l"; 
        };
    }

    if (btnInter) {
        btnInter.onclick = function() {
            window.location.href = "https://paypal.me/aziz24661";
        };
    }

    // --- 2. SLIDER PRINCIPAL (Haut de page) ---
    const mainSlides = document.querySelectorAll('.slide');
    let currentMainSlide = 0;

    if (mainSlides.length > 0) {
        setInterval(() => {
            mainSlides[currentMainSlide].classList.remove('active');
            currentMainSlide = (currentMainSlide + 1) % mainSlides.length;
            mainSlides[currentMainSlide].classList.add('active');
        }, 4000); // Défilement toutes les 4 secondes
    }

    // --- 3. MINI-SLIDER "À PROPOS" (Images qui défilent) ---
    // Script pour le mini-slider de la section À Propos
const aboutSlides = document.querySelectorAll('.about-slide');
let currentAboutSlide = 0;

function nextAboutSlide() {
    if (aboutSlides.length > 0) {
        aboutSlides[currentAboutSlide].classList.remove('active');
        currentAboutSlide = (currentAboutSlide + 1) % aboutSlides.length;
        aboutSlides[currentAboutSlide].classList.add('active');
    }
}

// Change d'image toutes les 3.5 secondes
setInterval(nextAboutSlide, 3500);
    // --- 4. ANIMATIONS AU SCROLL & COMPTEUR ---
    const aboutSection = document.querySelector('#a-propos');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                entry.target.classList.add('active-reveal');
                
                const counter = entry.target.querySelector('.number');
                // On ne lance le compteur que s'il affiche "0" pour éviter de recommencer sans arrêt
                if (counter && counter.innerText === "0") {
                    animateCounter(counter);
                }
            }
        });
    }, { threshold: 0.2 });

    if (aboutSection) {
        observer.observe(aboutSection);
    }

    function animateCounter(el) {
        const target = parseInt(el.getAttribute('data-target'));
        let count = 0;
        const duration = 2000; // 2 secondes
        const stepTime = duration / target;

        const updateCount = () => {
            if (count < target) {
                count++;
                el.innerText = count;
                setTimeout(updateCount, stepTime);
            } else {
                el.innerText = target + "+";
            }
        };
        updateCount();
    }
});

// --- 5. FONCTION PARTAGE (Hors du DOMContentLoaded pour être accessible par onclick) ---
function partagerSite() {
    if (navigator.share) {
        navigator.share({
            title: 'Horizon de Charité - Dakar',
            text: 'Soutenez les orphelins de Dakar. Faites un don !',
            url: 'https://horizon-charite-dakar.web.app'
        }).catch(err => console.log("Erreur de partage:", err));
    } else {
        // Fallback pour les navigateurs PC qui ne supportent pas navigator.share
        const url = 'https://horizon-charite-dakar.web.app';
        navigator.clipboard.writeText(url);
        alert("Lien copié dans le presse-papier ! Partagez-le partout.");
    }
}