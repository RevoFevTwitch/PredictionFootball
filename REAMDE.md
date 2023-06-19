# PredictionFootball

Ce projet a pour objectif d'explorer les meilleures techniques de prédiction sportive pour le football en utilisant des modèles statistiques de plus en plus complexes. Les scripts inclus dans ce repository sont destinés à créer, estimer et utiliser ces modèles de prédiction.

## Streaming en direct

Vous pouvez suivre mes sessions de travail en direct sur ma [chaîne Twitch](https://www.twitch.tv/revolutionfever) où je partagerai mon écran et montrerai le processus de développement du code. Vous êtes invités à rejoindre et à participer à la discussion. Si vous souhaitez contribuer, vous pouvez soumettre des pull requests avec vos modifications.

## Langages de programmation

Les scripts de ce projet seront écrit en Julia, mais vous êtes libre d'ajouter vos propres versions en Python ou R. Cependant, veuillez noter que seuls les fichiers de code doivent être téléchargés. Tout fichier de données est strictement interdit.

## Exécution des scripts et dépendances

Pour éxécuter les scripts, il suffit d'obtenir une version de Julia 1.6 puis, après avoir cloné ce repository et l'avoir défini en tant que working directory, éxecuter les commandes suivantes:
```julia
Pkg.activate("PredictionFootball")

Pkg.instantiate()
```
Les dépendances requises pour exécuter les scripts sont répertoriées dans les fichiers `Manifest.toml` et `Project.toml`. Vous pouvez les installer en utilisant les commandes standard de gestion des packages Julia. Chaque script peut être exécuté individuellement sans commande spécifique. Assurez-vous d'utiliser la version 1.6 de Julia pour une compatibilité optimale.

## Fichiers de données

Aucun fichier de données n'est nécessaire pour utiliser les scripts fournis. Si nécessaire, les commandes pour récupérer des données libres d'accès seront fournies dans la documentation et les commentaires du script.

---

N'hésitez pas à explorer les différents scripts et à les utiliser comme base pour vos propres modèles de prédiction de matches de football. Si vous avez des questions, des suggestions ou des idées d'amélioration, n'hésitez pas à les partager dans la section des problèmes (Issues) de ce repository.

Bonne exploration et bonnes prédictions !
