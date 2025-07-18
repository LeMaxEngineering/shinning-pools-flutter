# Shinning Pools - Manuel d'Utilisateur (Français)

« L'objectif de cette application est de se concentrer sur la "Maintenance", afin de rendre l'entretien des piscines facile, traçable et professionnel pour les entreprises et les employés. »

# Shinning Pools - Manuels Utilisateur

Bienvenue ! Veuillez sélectionner votre langue préférée pour le manuel utilisateur :

- [Manuel en Anglais](user_manuals_en.md)
- [Manuel en Espagnol](user_manuals_es.md)
- [Manuel en Français](user_manuals_fr.md)

> **Note :** Tous les manuels sont tenus à jour avec les dernières fonctionnalités et solutions. Si vous constatez des informations obsolètes, contactez l'équipe support.

## Table des Matières

1. [Premiers Pas](#premiers-pas)
2. [Manuel Utilisateur Root](#manuel-utilisateur-root)
3. [Manuel Utilisateur Administrateur](#manuel-utilisateur-administrateur)
4. [Manuel Utilisateur Client](#manuel-utilisateur-client)
5. [Manuel Utilisateur Employé](#manuel-utilisateur-employé)
6. [Dépannage](#dépannage)

---

## Premiers Pas

### Première Connexion

1. **Accéder à l'Application**
   - Ouvrez votre navigateur et allez sur l'application Shinning Pools
   - Optimisé pour Chrome, Firefox et Safari

2. **Création de Compte**
   - Cliquez sur « S'inscrire »
   - Entrez votre email et créez un mot de passe sécurisé
   - Vérifiez votre email (regardez dans votre boîte de réception)
   - Complétez votre profil

3. **Attribution de Rôle**
   - Nouveaux utilisateurs : rôle « Client » par défaut
   - Pour devenir administrateur d'entreprise, enregistrez votre société (voir Manuel Client)
   - Les utilisateurs root sont configurés par les administrateurs système

### Connexion

1. **Connexion Standard**
   - Entrez votre email et mot de passe
   - Cliquez sur « Se connecter »
   - Vous serez redirigé vers votre tableau de bord selon votre rôle

2. **Connexion Google**
   - Cliquez sur « Se connecter avec Google »
   - Autorisez l'application
   - Complétez le profil si c'est la première fois

3. **Récupération de Mot de Passe**
   - Cliquez sur « Mot de passe oublié ? »
   - Entrez votre email
   - Suivez les instructions reçues par email

---

## Manuel Utilisateur Root

### Vue d'Ensemble
Les utilisateurs root gèrent toute la plateforme : approbation des entreprises, gestion des utilisateurs, configuration système.

### Fonctions du Tableau de Bord
- **Gestion des Entreprises** : Voir toutes les entreprises, approuver, suspendre, supprimer
- **Gestion des Utilisateurs** : Voir tous les utilisateurs, changer les rôles, éditer les profils
- **Configuration Système** : Gérer les plans de facturation, types de maintenance, paramètres globaux

### Bonnes Pratiques
- Vérifiez les inscriptions régulièrement
- Communiquez clairement avec les entreprises
- Documentez toutes les actions
- Surveillez et maintenez le système

---

## Manuel Utilisateur Administrateur

### Vue d'Ensemble
Les administrateurs gèrent les opérations de leur entreprise : clients, piscines, équipe.

### Fonctions du Tableau de Bord
- **Statistiques de l'Entreprise** : Voir les indicateurs clés
- **Activité Récente** : Suivre les opérations récentes
- **Actions Rapides** : Accès aux fonctions fréquentes

#### **Gestion des Clients**
- Ajouter, éditer, filtrer, assigner des piscines

#### **Gestion des Piscines**
- Ajouter une piscine, saisir les dimensions (voir guide ci-dessous), surveiller l'état et l'historique, planifier les maintenances

#### **Guide de Saisie des Dimensions**
- Saisissez un nombre simple (ex : 40), un nombre décimal (25.5), ou des dimensions (25x15)
- Le système calcule automatiquement la surface si besoin
- Les unités sont ignorées, seuls les chiffres sont pris en compte

#### **Listes de Maintenances Récentes**
- **Administrateurs** : Dans l'onglet Piscines, descendez jusqu'à « Maintenance Récente (20 derniers) » pour voir et filtrer tous les maintenances de l'entreprise. Filtres disponibles : piscine, statut, période. Si un message d'erreur d'index apparaît, voir la section Dépannage.

---

## Manuel Utilisateur Client

- Voir et gérer ses propres piscines et maintenances
- Contacter l'entreprise pour assistance

---

## Manuel Utilisateur Employé

### Vue d'Ensemble
Les employés (travailleurs) voient uniquement les piscines et maintenances qui leur sont assignées.

#### **Listes de Maintenances Récentes**
- **Employés** : Dans l'onglet « Rapports », tout en bas, retrouvez « Maintenance Récente (20 derniers) ». Cette liste affiche vos 20 dernières maintenances, avec filtres piscine, statut, période. Si un message d'erreur d'index apparaît, voir la section Dépannage.

---

## Dépannage

### Erreurs d'Index Firestore
Si vous voyez un message d'erreur comme « La requête nécessite un index » ou « [cloud_firestore/failed-precondition] », Firestore a besoin d'un index composite pour vos filtres. Pour corriger :
1. Copiez le lien fourni dans le message d'erreur et ouvrez-le dans votre navigateur.
2. Cliquez sur « Créer » dans la console Firebase.
3. Attendez quelques minutes que l'index soit construit, puis rechargez l'application.
Si le lien est cassé, consultez le guide administrateur ou contactez le support pour la création manuelle d'index.

---

**Dernière mise à jour : Janvier 2025** 
*Version: 1.6.4 - Validation de Qualité de Code et Mises à Jour de Documentation*

> **📝 Mises à Jour Récentes**: 
> - **Validation de Qualité de Code (Janvier 2025)**: Validation réussie du code propre avec 0 problèmes d'analyse statique en utilisant `flutter analyze`
> - **Maintenance de Documentation**: Processus amélioré pour maintenir tous les fichiers de documentation synchronisés et à jour
> - **Confirmation du Statut du Projet**: Vérification du statut prêt pour la production avec système complet de gestion des routes
> - **Validation des Performances**: Confirmation de 78 tests réussis, 0 échecs (100% de taux de réussite) et 0 erreurs de compilation

# Problèmes connus

## Erreur de permission Firestore pour les administrateurs d'entreprise (juin 2025)
- **Problème :** Les administrateurs d'entreprise peuvent recevoir une erreur 'permission-denied' lors de l'accès aux maintenances de piscine.
- **Cause :** Cela est généralement dû à l'absence ou à la non-concordance du champ `companyId` dans les enregistrements de maintenance, ou à des règles de sécurité Firestore qui ne correspondent pas à l'entreprise de l'utilisateur.
- **Solution temporaire :** Vérifiez que tous les documents `pool_maintenances` possèdent le champ `companyId` correct correspondant à l'entreprise de l'administrateur. Si le problème persiste, contactez le support ou votre administrateur système.
- **Statut :** Une correction définitive est en attente. Ce problème est suivi dans la liste des tâches du projet.

## Statut de Qualité de Code et Performances (Janvier 2025)
- **Analyse Statique :** ✅ Code propre avec 0 problèmes détectés
- **Couverture de Tests :** ✅ 78 tests réussis, 0 échecs (100% de taux de réussite)
- **Compilation :** ✅ 0 erreurs, 154 avertissements (non bloquants)
- **Performances :** ✅ Stable et réactif sur toutes les plateformes
- **Multi-plateforme :** ✅ Support complet pour Web, Android, iOS, Desktop

**Rappel :** Vérifiez régulièrement les mises à jour de l'application et de la documentation pour bénéficier des dernières informations et fonctionnalités. 