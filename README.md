# 🧹 Nettoyage Linux

Script bash de nettoyage du système Linux, compatible **multi-distributions** (`apt`, `dnf`, `pacman`, `apk`, `zypper`).

Il libère de l'espace disque en nettoyant :

- **Paquets du système** : cache + paquets orphelins (`apt clean` / `autoremove`, `dnf clean`, `paccache`, etc.)
- **Snap** : révisions désactivées *(si `snap` est installé)*
- **Flatpak** : runtimes inutilisés *(si `flatpak` est installé)*
- **Docker** : images, conteneurs et cache de build inutilisés *(si docker est lancé)*
- **Journaux système** : `journalctl` (> 7 jours) ou, sans systemd, logs `/var/log` (> 30 jours)
- **Fichiers temporaires** : `/tmp`, `/var/tmp`, miniatures (thumbnails) et caches utilisateur (> 30 jours)
- **Corbeille** : `~/.local/share/Trash` + fichiers personnels inactifs dans `/tmp`

L'**espace libéré** sur `/` est mesuré avant/après et affiché en fin de script.

## ⚙️ Prérequis

- Bash 4+ (présent par défaut sur toutes les distributions modernes)
- Droits `sudo` pour les étapes système (paquets, journaux, snap)
- Outils optionnels utilisés **uniquement si installés** : `snap`, `flatpak`, `docker`, `numfmt`

> 💡 Le détection du gestionnaire de paquets est automatique (`apt-get` / `dnf` / `pacman` / `apk` / `zypper`).

## 🚀 Utilisation

```bash
# Mode interactif (confirmation avant chaque étape)
./nettoyage.sh

# Nettoyage automatique complet (sans questions) — sudo requis
sudo ./nettoyage.sh --tout

# Aide
./nettoyage.sh --aide
```

> ⚠️ Les étapes liées aux **caches et à la corbeille de l'utilisateur** s'appliquent à la valeur de `$HOME`.
> Utilisez `sudo` uniquement pour le nettoyage système, ou le script agira sur le compte `root`.

## 📦 Installation

```bash
git clone https://github.com/OOJessOO/CLI-LINUX.git
cd CLI-LINUX
chmod +x nettoyage.sh
```

*(Alias recommandé dans `~/.bashrc` : `alias nettoyage="sudo ~/cli-linux/nettoyage.sh --tout"`)*

## 🗺️ Compatibilité

| Gestionnaire  | Distributions (ex.)     | Paquets | Journaux | temp / corbeille |
|---------------|-------------------------|:-------:|:--------:|:----------------:|
| `apt`         | Debian, Ubuntu, Mint    | ✅      | ✅       | ✅               |
| `dnf`         | Fedora, RHEL, Rocky     | ✅      | ✅       | ✅               |
| `pacman`      | Arch, Manjaro, Endeavour| ✅      | ✅       | ✅               |
| `apk`         | Alpine                  | ✅      | ⚠️ logs fallback | ✅        |
| `zypper`      | openSUSE                | ✅      | ✅       | ✅               |

- **Journaux système** : `journalctl` si systemd, sinon purge des fichiers `*.log*` de `/var/log` plus anciens que 30 jours.
- Chaque étape est **indépendante** : une étape en échec ne bloque jamais les suivantes.

## 📄 Licence

MIT — libres de l'utiliser et de le modifier.