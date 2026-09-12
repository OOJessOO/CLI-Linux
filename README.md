# 🧹 Nettoyage Linux

Script bash de nettoyage du système Linux (Debian / Ubuntu et familles `apt` + `systemd`).

Il supprime les fichiers inutiles pour libérer de l'espace disque :

- **Paquets apt** : `clean`, `autoremove --purge`, régénération de la liste des paquets
- **Journaux système** : `journalctl` — purges des journaux de plus de 7 jours
- **Fichiers temporaires** : `/tmp`, `/var/tmp`, miniatures (thumbnails) et caches utilisateur (> 30 jours)
- **Corbeille** : `~/.local/share/Trash`

## ⚙️ Prérequis

- Linux avec **Debian / Ubuntu** (ou dérivé `apt`)
- **systemd** (pour le nettoyage des journaux)
- Outils de base : `bash`, `apt-get`, `journalctl`

> ⚠️ Les parties `apt` et `journalctl` nécessitent les droits **root** (`sudo`).

## 🚀 Utilisation

```bash
# Mode interactif (confirmation avant chaque étape)
./nettoyage.sh

# Nettoyage automatique complet (sans questions)
sudo ./nettoyage.sh --tout
```

## 📦 Installation

```bash
git clone https://github.com/OOJessOO/CLI-LINUX.git
cd CLI_LINUX
chmod +x nettoyage.sh
```

*(Alias recommandé dans `~/.bashrc` : `alias nettoyage="sudo ~/nettoyage-linux/nettoyage.sh --tout"`)*

## 🗺️ Compatibilité

| Distribution       | apt | journalctl | temp / corbeille |
|--------------------|:---:|:----------:|:----------------:|
| Debian / Ubuntu    | ✅  | ✅         | ✅               |
| Fedora / RHEL      | ❌  | ✅         | ✅               |
| Arch / Manjaro     | ❌  | ✅         | ✅               |
| Alpine (OpenRC)    | ❌  | ❌         | ✅               |

Sur les distributions non `apt`, seul le nettoyage des paquets est ignoré ; les autres étapes restent fonctionnelles (en mode interactif, elles vous seront proposées).

Les journaux d'erreurs (`ERREUR`) ne bloquent pas le script : chaque étape s'exécute de façon indépendante.

## 📄 Licence

MIT — libres de l'utiliser et de le modifier.