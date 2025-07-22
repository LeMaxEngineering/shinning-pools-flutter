# Shinning Pools - Manuel d'Utilisateur (Français)

"L'objectif de cette application est de se concentrer sur la 'Maintenance', ce qui garantira qu'elle livre sa valeur principale : rendre la maintenance des piscines facile, traçable et professionnelle pour les entreprises et les employés."

# Shinning Pools - Manuels d'Utilisateur

Bienvenue ! Veuillez sélectionner votre langue préférée pour le manuel utilisateur :

- [English User Manual](user_manuals_en.md)
- [Manual de Usuario en Español](user_manuals_es.md)
- [Manuel d'Utilisateur en Français](user_manuals_fr.md)

> **Note :** Tous les manuels sont tenus à jour avec les dernières fonctionnalités et informations de dépannage. Si vous remarquez des informations obsolètes, veuillez contacter l'équipe de support.

## Table des Matières

1. [Premiers Pas](#premiers-pas)
2. [Manuel Utilisateur Root](#manuel-utilisateur-root)
3. [Manuel Utilisateur Administrateur](#manuel-utilisateur-administrateur)
4. [Manuel Utilisateur Client](#manuel-utilisateur-client)
5. [Manuel Utilisateur Associé](#manuel-utilisateur-associé)
6. [Dépannage](#dépannage)

---

## Premiers Pas

### Configuration Initiale

1. **Accéder à l'Application**
   - Ouvrez votre navigateur web et naviguez vers l'application Shinning Pools
   - L'application est optimisée pour Chrome, Firefox et Safari

2. **Création de Compte**
   - Cliquez sur "S'inscrire" sur l'écran de connexion
   - Entrez votre adresse e-mail et créez un mot de passe sécurisé
   - Complétez la vérification par e-mail (vérifiez votre boîte de réception)
   - Remplissez les informations de votre profil

3. **Attribution de Rôle**
   - Les nouveaux utilisateurs commencent avec le rôle "Client" par défaut
   - Pour devenir administrateur d'entreprise, enregistrez votre entreprise (voir Manuel Client)
   - Les utilisateurs root sont préconfigurés par les administrateurs système

### Processus de Connexion

1. **Connexion Régulière**
   - Entrez votre e-mail et mot de passe
   - Cliquez sur "Se Connecter"
   - Vous serez redirigé vers votre tableau de bord spécifique au rôle

2. **Connexion Google**
   - Cliquez sur "Se connecter avec Google"
   - Autorisez l'application
   - Complétez la configuration du profil si c'est la première fois

3. **Récupération de Mot de Passe**
   - Cliquez sur "Mot de passe oublié ?" sur l'écran de connexion
   - Entrez votre adresse e-mail
   - Vérifiez votre boîte de réception pour les instructions de réinitialisation

---

## Manuel Utilisateur Root

### Aperçu
Les utilisateurs root ont un accès complet au système et gèrent toute la plateforme, y compris les approbations d'entreprises, la gestion des utilisateurs et la configuration du système.

### Fonctionnalités du Tableau de Bord

#### **Gestion des Entreprises**
- **Voir Toutes les Entreprises** : Accédez à la liste complète des entreprises enregistrées
- **Statistiques des Entreprises** : Voir l'aperçu des entreprises en attente, approuvées et suspendues
- **Recherche et Filtrage** : Trouvez des entreprises spécifiques par nom, e-mail ou statut

#### **Actions d'Entreprise**
1. **Approuver une Entreprise**
   - Naviguez vers la Liste des Entreprises
   - Trouvez l'entreprise en attente
   - Cliquez sur le bouton "Approuver"
   - Le propriétaire de l'entreprise devient automatiquement le rôle Administrateur

2. **Modifier les Détails de l'Entreprise**
   - Cliquez sur le menu à trois points (⋮) à côté d'une entreprise
   - Sélectionnez "Modifier"
   - Modifiez les informations de l'entreprise
   - Sauvegardez les modifications

3. **Suspendre/Réactiver une Entreprise**
   - Utilisez le menu d'actions pour suspendre les entreprises actives
   - Fournissez la raison de suspension quand demandé
   - Réactivez les entreprises suspendues selon les besoins

4. **Supprimer une Entreprise**
   - Utilisez le menu d'actions pour supprimer les entreprises
   - Confirmez la suppression (cette action ne peut pas être annulée)
   - Les utilisateurs associés reviennent au rôle Client

#### **Gestion des Utilisateurs**
- **Voir Tous les Utilisateurs** : Accédez au répertoire complet des utilisateurs
- **Statistiques des Utilisateurs** : Surveillez l'activité et les rôles des utilisateurs
- **Gestion des Rôles** : Attribuez et modifiez les rôles des utilisateurs
- **Gestion des Comptes** : Gérez les problèmes de comptes utilisateurs

#### **Configuration du Système**
- **Paramètres de Plateforme** : Configurez les paramètres à l'échelle du système
- **Règles de Sécurité** : Gérez les politiques de sécurité Firestore
- **Surveillance des Performances** : Suivez les performances du système
- **Gestion des Sauvegardes** : Supervisez les procédures de sauvegarde des données

### Bonnes Pratiques
- Surveillance régulière du système
- Gestion proactive de la sécurité
- Flux de travail d'approbation des entreprises
- Support et formation des utilisateurs

---

## Manuel Utilisateur Administrateur

### Aperçu
Les administrateurs d'entreprise gèrent les opérations de leur entreprise, y compris la gestion des clients, les affectations de travailleurs, la planification des itinéraires et la livraison de services.

### Fonctionnalités du Tableau de Bord

#### **Aperçu de l'Entreprise**
- **Tableau de Bord des Statistiques** : Voir les métriques clés (clients, piscines, travailleurs, itinéraires)
- **Activité Récente** : Surveiller les maintenances récentes et les achèvements d'itinéraires
- **Métriques de Performance** : Suivre les indicateurs de performance de l'entreprise

#### **Gestion des Clients**
1. **Ajouter un Nouveau Client**
   - Naviguez vers la section Clients
   - Cliquez sur "Ajouter Client"
   - Entrez les informations du client :
     - Nom et coordonnées
     - Informations d'adresse
     - Exigences spéciales
   - Téléchargez une photo du client (optionnel)
   - Sauvegardez l'enregistrement du client

2. **Gestion de la Liste des Clients**
   - Voir tous les clients de l'entreprise
   - Rechercher et filtrer les clients
   - Modifier les informations du client
   - Voir l'historique de maintenance du client

3. **Liaison des Clients**
   - Quand les clients s'inscrivent avec un e-mail correspondant, ils sont automatiquement liés
   - Les clients non liés peuvent être gérés séparément
   - Le statut de liaison est clairement indiqué dans l'interface

#### **Gestion des Piscines**
1. **Ajouter une Nouvelle Piscine**
   - Naviguez vers la section Piscines
   - Cliquez sur "Ajouter Piscine"
   - Entrez les détails de la piscine :
     - Nom/identifiant de piscine
     - Adresse et emplacement
     - Type et dimensions de piscine
     - Coût mensuel de maintenance
     - Exigences spéciales
   - Téléchargez une photo de la piscine (optionnel)
   - Soumettez pour traitement

2. **Système de Dimensions de Piscine**
Le système prend maintenant en charge l'analyse intelligente des dimensions de piscine :

**💡 Bonnes Pratiques**

1. **Pour les Piscines Carrées/Rectangulaires** : Utilisez le format de dimensions `LongueurxLargeur` (ex., `25x15`)
2. **Pour les Piscines Circulaires** : Entrez l'aire directement (ex., `450`)
3. **Pour les Piscines Irrégulières** : Entrez l'aire totale (ex., `320.5`)
4. **Incluez les Décimales** : Pour des mesures précises (ex., `25.75x12.5`)

**⚠️ Notes Importantes**

- Le système stocke la valeur calculée finale comme nombre dans la base de données
- Lors de l'édition de piscines existantes, le nombre stocké est affiché
- Pour le format de dimensions (`LxL`), le système calcule et stocke l'aire totale
- Toutes les mesures sont affichées avec les unités `m²` dans l'interface

3. **Suivi de Maintenance des Piscines**
   - Voir les enregistrements de maintenance récents (20 derniers)
   - Filtrer la maintenance par piscine, statut et date
   - Accéder aux informations détaillées de maintenance
   - Surveiller les taux d'achèvement de maintenance

#### **Gestion des Travailleurs**
1. **Inviter des Travailleurs**
   - Naviguez vers la section Travailleurs
   - Cliquez sur "Inviter Travailleur"
   - Entrez l'adresse e-mail du travailleur
   - Ajoutez un message personnel (optionnel)
   - Envoyez l'invitation

2. **Exigences d'Invitation de Travailleur**
   - Le travailleur doit avoir un compte enregistré
   - Le travailleur doit avoir le rôle "Client"
   - Le travailleur ne peut pas avoir de piscines enregistrées
   - Le travailleur doit accepter l'invitation

3. **Processus d'Intégration du Travailleur**
   - Le travailleur reçoit une notification d'invitation
   - Le travailleur examine les détails de l'invitation
   - Le travailleur accepte ou rejette l'invitation
   - Le rôle change en "Travailleur" lors de l'acceptation

4. **Fonctionnalités de Gestion des Travailleurs**
   - Voir tous les travailleurs de l'entreprise
   - Envoyer des rappels d'invitation (refroidissement de 24 heures)
   - Exporter les données des travailleurs (format CSV/JSON)
   - Surveiller la performance des travailleurs

#### **Gestion des Itinéraires**
1. **Créer des Itinéraires**
   - Naviguez vers la section Itinéraires
   - Cliquez sur "Créer Itinéraire"
   - Sélectionnez les piscines pour l'itinéraire
   - Assignez un travailleur à l'itinéraire
   - Définissez les paramètres d'itinéraire

2. **Optimisation d'Itinéraire**
   - Utilisez l'intégration Google Maps pour des itinéraires optimaux
   - Commencez les itinéraires depuis l'emplacement de l'utilisateur
   - Optimisez pour le temps et la distance
   - Voir la visualisation d'itinéraire sur la carte

3. **Surveillance d'Itinéraire**
   - Suivre le statut d'achèvement d'itinéraire
   - Surveiller le progrès du travailleur
   - Voir les données historiques d'itinéraire
   - Accéder aux analyses de performance d'itinéraire

#### **Gestion de Maintenance**
1. **Liste de Maintenance Récente**
   - Voir les 20 derniers enregistrements de maintenance
   - Filtrer par piscine, statut et plage de dates
   - Accéder aux informations détaillées de maintenance
   - Surveiller les taux d'achèvement de maintenance

2. **Détails de Maintenance**
   - Voir les enregistrements de maintenance complets
   - Données d'utilisation de produits chimiques et qualité de l'eau
   - Activités de maintenance physique
   - Suivi des coûts et informations de facturation

3. **Rapports de Maintenance**
   - Générer des rapports d'achèvement de maintenance
   - Suivre l'utilisation de produits chimiques et les coûts
   - Surveiller les tendances de qualité de l'eau
   - Analyser l'efficacité de maintenance

#### **Rapports et Analyses**
- **Rapports de Maintenance** : Générer des rapports de service
- **Analyses de Performance** : Voir la performance d'équipe et d'itinéraire
- **Rapports Clients** : Analyser la satisfaction client
- **Rapports Financiers** : Suivre la facturation et les revenus
- **Fonctionnalité d'Exportation** : Télécharger les données au format CSV/JSON

### Bonnes Pratiques
- Communication régulière avec les clients
- Programmation proactive de maintenance
- Formation et supervision d'équipe
- Contrôle qualité et normes de service

---

## Manuel Utilisateur Client

### Aperçu
Les clients gèrent leurs informations de piscine, consultent les rapports de maintenance et communiquent avec leur fournisseur de services.

### Fonctionnalités du Tableau de Bord

#### **Enregistrement d'Entreprise**
1. **Enregistrer Votre Entreprise**
   - Cliquez sur "Enregistrer Entreprise" sur le tableau de bord
   - Remplissez les informations de l'entreprise :
     - Nom de l'entreprise
     - Adresse
     - Numéro de téléphone
     - Description
   - Soumettez pour approbation
   - Attendez l'approbation de l'utilisateur root

2. **Statut d'Enregistrement**
   - "En Attente d'Approbation" : Votre demande est en cours d'examen
   - "Approuvé" : Vous pouvez maintenant accéder aux fonctionnalités d'administrateur
   - "Rejeté" : Contactez le support pour assistance

#### **Recevoir une Invitation de Travailleur**
Si un administrateur d'entreprise vous invite à devenir travailleur, vous verrez une notification sur votre tableau de bord.
1. **Examiner** : Cliquez sur la notification pour examiner les détails de l'invitation.
2. **Répondre** : Vous pouvez choisir d'**Accepter** ou **Rejeter** l'invitation.
   - **Accepter** changera votre rôle en "Travailleur" et vous donnera accès aux itinéraires et tâches de l'entreprise.
   - **Rejeter** ne fera aucun changement à votre compte.

#### **Gestion des Piscines**
1. **Ajouter une Nouvelle Piscine**
   - Naviguez vers la section Piscines
   - Cliquez sur "Ajouter Piscine"
   - Entrez les détails de la piscine :
     - Nom/identifiant de piscine
     - Taille et type
     - Détails d'emplacement
     - Exigences spéciales
   - Soumettez pour traitement

2. **Surveillance des Piscines**
   - Voir l'historique de maintenance des piscines
   - Vérifier les rapports de qualité de l'eau
   - Surveiller l'état de l'équipement
   - Demander des services supplémentaires

#### **Rapports et Communication**
- **Rapports de Service** : Voir les rapports détaillés de maintenance
- **Informations de Facturation** : Vérifier les factures de service
- **Communication** : Contacter votre fournisseur de services
- **Commentaires** : Fournir des évaluations et commentaires de service

#### **Gestion de Profil**
- **Informations Personnelles** : Mettre à jour les coordonnées
- **Préférences** : Définir les préférences de notification
- **Sécurité** : Changer le mot de passe et les paramètres de sécurité

### Bonnes Pratiques
- Maintenir les informations de piscine à jour
- Examiner régulièrement les rapports de maintenance
- Communiquer les exigences spéciales promptement
- Fournir des commentaires pour améliorer le service

---

## Manuel Utilisateur Associé

### Aperçu
Les utilisateurs associés (travailleurs de terrain) exécutent les itinéraires de maintenance, enregistrent les activités de service et mettent à jour le statut des piscines.

### Fonctionnalités du Tableau de Bord

#### **Suivi de Maintenance Récente**
1. **Voir la Maintenance Récente**
   - Accédez à la section "Maintenance Récente" dans l'onglet Rapports
   - Voir les 20 derniers enregistrements de maintenance que vous avez effectués
   - Filtrer par piscine, statut et plage de dates
   - Voir les adresses de piscines et noms de clients clairement affichés

2. **Détails de Maintenance**
   - Cliquez sur n'importe quel enregistrement de maintenance pour une vue détaillée
   - Examiner l'utilisation de produits chimiques et les données de qualité de l'eau
   - Vérifier les activités de maintenance physique effectuées
   - Accéder aux notes et observations de maintenance

#### **Gestion d'Itinéraire**
1. **Voir les Itinéraires Assignés**
   - Vérifier les affectations d'itinéraire quotidiennes
   - Voir les détails d'itinéraire et informations de piscines
   - Accéder aux informations de contact du client
   - Examiner les instructions spéciales

2. **Exécution d'Itinéraire**
   - Commencer l'itinéraire quand vous commencez à travailler
   - Mettre à jour le progrès pendant que vous complétez les piscines
   - Enregistrer tout problème ou retard
   - Marquer l'itinéraire comme complet

3. **Intégration de Carte**
   - Utiliser des cartes interactives pour la navigation d'itinéraire
   - Voir les emplacements de piscines avec des marqueurs personnalisés
   - Accéder aux directions d'itinéraire optimisées
   - Suivre votre emplacement actuel

#### **Maintenance des Piscines**
1. **Enregistrement de Service**
   - Sélectionner la piscine de l'itinéraire
   - Enregistrer les activités de maintenance :
     - Niveaux et utilisation de produits chimiques
     - Travail d'équipement effectué
     - Vérifications de qualité de l'eau
     - Observations générales
   - Ajouter des photos si nécessaire
   - Soumettre le rapport de service

2. **Fonctionnalités du Formulaire de Maintenance**
   - Suivi complet des produits chimiques
   - Liste de vérification de maintenance physique
   - Enregistrement des métriques de qualité de l'eau
   - Calcul des coûts et facturation
   - Programmation du prochain maintenance

3. **Rapport de Problèmes**
   - Signaler les problèmes d'équipement
   - Noter les problèmes de qualité de l'eau
   - Marquer les préoccupations du client
   - Demander des actions de suivi

#### **Communication**
- **Mises à Jour Clients** : Informer les clients de l'achèvement du service
- **Communication d'Équipe** : Mettre à jour les superviseurs sur le progrès
- **Contacts d'Urgence** : Accéder aux informations de contact d'urgence
- **Notes de Service** : Laisser des notes détaillées pour les membres d'équipe

#### **Gestion de Profil**
- **Informations Personnelles** : Mettre à jour les coordonnées
- **Préférences de Travail** : Définir la disponibilité et les préférences
- **Suivi de Performance** : Voir vos statistiques de maintenance
- **Matériaux de Formation** : Accéder aux ressources de formation

### Bonnes Pratiques
- Compléter les enregistrements de maintenance avec précision
- Suivre les protocoles de sécurité
- Communiquer les problèmes promptement
- Maintenir l'apparence professionnelle
- Mettre à jour le progrès d'itinéraire régulièrement

---

## Dépannage

### Problèmes Courants

#### **Problèmes d'Authentification**
- **Problèmes de Connexion** : Vérifier l'e-mail et le mot de passe
- **Vérification E-mail** : Vérifier le dossier spam pour les e-mails de vérification
- **Réinitialisation de Mot de Passe** : Utiliser la fonction "Mot de passe oublié ?"
- **Connexion Google** : S'assurer que le navigateur permet les pop-ups

#### **Problèmes de Chargement de Données**
- **Chargement Lent** : Vérifier la connexion internet
- **Données Manquantes** : Actualiser la page ou vider le cache
- **Mises à Jour en Temps Réel** : Assurer une connexion stable
- **Problèmes de Filtre** : Vider les filtres et réessayer

#### **Problèmes de Carte et Localisation**
- **Permissions de Localisation** : Activer l'accès à la localisation dans le navigateur
- **Carte Ne Charge Pas** : Vérifier la connexion internet
- **Marqueurs Personnalisés** : S'assurer que les actifs d'image sont disponibles
- **Optimisation d'Itinéraire** : Vérifier la clé API Google Maps

#### **Problèmes de Téléchargement de Fichiers**
- **Téléchargement de Photos** : Vérifier la taille et le format de fichier
- **Erreurs CORS** : Le mode développement utilise une méthode de stockage de secours
- **Formats Supportés** : Images JPG, PNG jusqu'à des tailles raisonnables

#### **Problèmes Techniques**
- **Page Ne Charge Pas** : Vider le cache et cookies du navigateur
- **Performance Lente** : Vérifier la connexion internet
- **Problèmes Mobiles** : Utiliser la version desktop pour la fonctionnalité complète

### Obtenir de l'Aide

#### **Canaux de Support**
- **Aide dans l'Application** : Utiliser la section d'aide dans votre tableau de bord
- **Support E-mail** : Contacter support@shinningpools.com
- **Support Téléphonique** : Appeler pendant les heures de bureau
- **Documentation** : Se référer à ce manuel et aux ressources en ligne

#### **Contacts d'Urgence**
- **Problèmes Techniques** : Équipe de support IT
- **Urgences de Service** : Votre fournisseur de services assigné
- **Questions de Facturation** : Département comptabilité

### Exigences Système

#### **Navigateur Web**
- Chrome 90+ (Recommandé)
- Firefox 88+
- Safari 14+
- Edge 90+

#### **Appareils Mobiles**
- iOS 13+ (Safari)
- Android 8+ (Chrome)
- Design responsive pour toutes les tailles d'écran

#### **Connexion Internet**
- Minimum 1 Mbps vitesse de téléchargement
- Connexion stable pour les fonctionnalités en temps réel
- Mode hors ligne disponible pour les travailleurs de terrain

### Erreurs d'Index Firestore
Si vous voyez un message d'erreur comme "The query requires an index" ou "[cloud_firestore/failed-precondition]", cela signifie que Firestore a besoin d'un index composite pour vos filtres. Pour corriger :
1. Copiez le lien fourni dans le message d'erreur et ouvrez-le dans votre navigateur.
2. Cliquez sur "Create" dans la Console Firebase.
3. Attendez quelques minutes pour que l'index se construise, puis rechargez l'application.
Si le lien est cassé, consultez le guide administrateur ou contactez le support pour les étapes de création manuelle d'index.

---

## Référence Rapide

### Raccourcis Clavier
- **Ctrl + S** : Sauvegarder les modifications
- **Ctrl + F** : Rechercher dans la page actuelle
- **Ctrl + R** : Actualiser la page
- **Esc** : Fermer les dialogues

### Indicateurs de Statut
- 🟢 **Actif** : Opération normale
- 🟡 **En Attente** : En attente d'action
- 🔴 **Suspendu** : Temporairement désactivé
- ⚫ **Inactif** : Non utilisé

### Actions Courantes
- **Modifier** : Cliquer sur l'icône crayon ou menu à trois points
- **Supprimer** : Utiliser l'icône poubelle avec confirmation
- **Voir Détails** : Cliquer sur le nom de l'élément
- **Exporter** : Utiliser l'icône téléchargement pour les rapports

---

*Dernière Mise à Jour : 21 Juillet 2025*
*Version : 1.6.9 - Corrections du Tableau de Bord des Travailleurs et Améliorations de Qualité de Code*

> **📝 Mises à Jour Récentes**: 
> - **Correction des Cartes de Maintenance Récente du Tableau de Bord des Travailleurs (Juillet 2025)** : Résolu le problème "Adresse inconnue" en implémentant la récupération de données appropriée depuis Firestore. Améliorée la récupération des noms de clients et améliorée l'affichage des données.
> - **Améliorations de Qualité de Code (Juillet 2025)** : Corrigés 29 problèmes critiques, réduits les problèmes totaux de 288 à 259. Améliorée la qualité et la maintenabilité de la base de code.
> - **Intégration de Base de Données de la Carte de Maintenance (Juillet 2025)** : Remplacé les données simulées par des données en direct de Firestore, ajoutée la visualisation de statut de maintenance réelle avec des points verts/rouges.
> - **Optimisation du Zoom de la Carte d'Itinéraire Historique (Juillet 2025)** : Améliorés les niveaux de zoom de la carte et le positionnement de la caméra pour une meilleure expérience utilisateur.

## Fonctionnalités de Carte et Sélection de Piscines (Mise à Jour 2025)

### Marqueur de Localisation Utilisateur Personnalisé
- La carte affiche maintenant votre localisation actuelle avec une icône personnalisée (user_marker.png).
- Si vous ne voyez pas votre marqueur de localisation, assurez-vous que les permissions de localisation sont activées et que l'actif d'image existe dans assets/img/user_marker.png.

### Marqueurs de Piscines et Statut de Maintenance
- **Points Verts** : Piscines qui ont été maintenues aujourd'hui
- **Points Rouges** : Piscines qui ont besoin de maintenance
- **Marqueurs Bleus** : Emplacements généraux de piscines
- Chaque marqueur affiche l'adresse de la piscine. Si l'adresse manque, elle affichera 'Aucune adresse'.

### Interface de Sélection de Piscines
- La section 'Piscine Sélectionnée' apparaît maintenant immédiatement après la boîte de recherche pour un flux de travail plus facile.
- Vous pouvez rechercher des piscines par nom, adresse ou client, ou sélectionner depuis la carte.
- Les piscines maintenues affichent "(Non Sélectionnable)" dans les fenêtres d'information et ne peuvent pas être sélectionnées pour une nouvelle maintenance.

### Filtrage de Piscines Basé sur la Distance
- Les cartes peuvent afficher seulement les 10 piscines les plus proches de votre emplacement actuel
- Basculer entre "Piscines Proches" et "Toutes les Piscines de l'Entreprise"
- Calcul intelligent de distance utilisant la formule de Haversine

## Menu d'Aide (Tiroir Latéral)

Un nouveau menu d'Aide est disponible depuis le tableau de bord principal pour tous les rôles utilisateur (travailleur, administrateur d'entreprise, client, root). Ouvrez-le en utilisant l'icône de menu dans le coin supérieur gauche. Le menu d'Aide fournit :

- **À Propos** : Version de l'application, dernière mise à jour, nom de l'entreprise (Lemax Engineering LLC) et informations de contact (+1 561 506 9714).
- **Vérifier les Mises à Jour** : Vérifier si une nouvelle version est disponible.
- **Bienvenue** : Message de bienvenue et aperçu de l'application.
- **Liens du Manuel Utilisateur** : Liens directs vers le manuel utilisateur (PDF), démarrage rapide et guides de dépannage.
- **Contact et Support** : Appeler ou envoyer un e-mail au support directement depuis l'application.

## Fonctionnalités de Maintenance Récente (Juillet 2025)

### Maintenance Récente du Tableau de Bord des Travailleurs
- **Affichage d'Adresse de Piscine** : Les adresses de piscines s'affichent maintenant correctement comme titres principaux
- **Noms de Clients** : Les noms de clients s'affichent comme sous-titres au lieu de "Adresse inconnue"
- **Formatage de Date** : Les dates s'affichent au format "Mois JJ, AAAA"
- **Filtrage Avancé** : Filtrer par piscine, statut et plage de dates
- **Source de Données** : Utilise la récupération de données locale pour une meilleure fiabilité

### Suivi de Maintenance d'Administrateur d'Entreprise
- **Liste de Maintenance Récente** : Voir les 20 derniers enregistrements de maintenance dans l'onglet Piscines
- **Filtrage Complet** : Filtrer par piscine, travailleur, statut et date
- **Détails de Maintenance** : Accéder aux informations détaillées de maintenance
- **Surveillance de Performance** : Suivre les taux d'achèvement de maintenance

## Architecture du Système de Maintenance (Juillet 2025)

### Enregistrements de Maintenance
- **Suivi Complet** : Utilisation de produits chimiques, maintenance physique, métriques de qualité de l'eau
- **Calcul des Coûts** : Calcul automatique des coûts basé sur les matériaux utilisés
- **Programmation du Prochain Maintenance** : Programmation automatique basée sur le type de service
- **Documentation Photographique** : Télécharger des photos pour les enregistrements de maintenance

### Sécurité et Contrôle d'Accès
- **Accès Basé sur les Rôles** : Différentes permissions pour différents rôles utilisateur
- **Isolation d'Entreprise** : Les utilisateurs ne peuvent accéder qu'aux données de leur entreprise
- **Validation de Maintenance** : Empêche les enregistrements de maintenance dupliqués par piscine par jour
- **Piste d'Audit** : Historique complet de toutes les activités de maintenance

## État de Qualité de Code et Performance (Juillet 2025)
- **Analyse Statique** : ✅ Base de code propre avec 259 problèmes totaux (réduits de 288)
- **Couverture de Tests** : ✅ 78 tests réussis, 0 échecs (100% taux de réussite)
- **Compilation** : ✅ 0 erreurs, performance stable
- **Performance** : ✅ Stable et responsive sur toutes les plateformes
- **Multiplateforme** : ✅ Support complet pour Web, Android, iOS, Desktop
- **Intégration de Données** : ✅ Récupération robuste de données clients avec gestion d'erreurs

**Rappel** : Vérifiez toujours les dernières mises à jour de l'application et de la documentation pour vous assurer d'avoir les informations et fonctionnalités les plus récentes. 