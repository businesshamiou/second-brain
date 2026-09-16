#!/usr/bin/env python3
# Garde-fou de fraicheur des index (Mission 089), reecrit en Python par la
# Mission 137-B : meme verdict, memes messages, memes codes de retour que
# tools/check-indexes-fresh.sh, en un seul processus. Ne regenere jamais, ne
# modifie jamais rien ; lit le format que tools/build-indexes.sh produit
# (Mission 080), ne le redefinit pas -- meme liste de dossiers elagues, meme
# grammaire de champ. Le refus est la position par defaut.
#
# Trois appels Git fixes (arbitrage Owner du 2026-09-04, option 2), jamais un
# par entree ni par fichier : git diff --cached (jeu stage), git ls-files
# (contenu des dossiers dans l'arbre stage), git cat-file --batch (tous les
# contenus en une passe). La semantique de l'ancien Bash est conservee : tout
# est lu dans l'ARBRE STAGE, jamais dans le worktree.
#
# Sortie : les ecarts d'index vont sur stdout, la butee de MISSION-INDEX.md
# sur stderr, comme dans le Bash d'origine. Ecriture en binaire (UTF-8, LF)
# pour ne pas subir la traduction CRLF de Python sous Windows.

import os
import re
import subprocess
import sys

# --- Sortie : LF strict, UTF-8, jamais de traduction de fin de ligne --------


def out(line):
    sys.stdout.buffer.write((line + "\n").encode("utf-8"))


def err(line):
    sys.stderr.buffer.write((line + "\n").encode("utf-8"))


# --- Bloc Bash l.13-16 : garde Git ------------------------------------------
# Le Bash fait `git rev-parse --show-toplevel`. Ici la racine est trouvee en
# remontant jusqu'a un .git : meme resultat, aucun processus supplementaire.
# REPO_ROOT n'apparait dans aucun message : sa forme (Windows ou POSIX) est
# sans effet sur la sortie.
def find_repo_root():
    d = os.path.abspath(os.getcwd())
    while True:
        if os.path.exists(os.path.join(d, ".git")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


REPO_ROOT = find_repo_root()
if REPO_ROOT is None:
    err("REFUS : hors d'un depot Git : gardien non executable.")
    sys.exit(1)

# Le Bash fait `cd "$REPO_ROOT"` (l.261) avant d'inspecter les dossiers.
os.chdir(REPO_ROOT)

# --- Bloc Bash l.20 : dossiers elagues --------------------------------------
# `skills-warehouse` ajoute (Mission 168, arbitrage Owner 2026-09-11, option
# b) : sous-arbre adopte tel quel (fichiers suivis seulement, T24), avec ses
# propres standards (AGENTS.md, CLAUDE.md, *_STANDARD.md) et sans la
# convention d'index du Vault -- il n'a jamais porte qu'un seul index.md
# natif (skill-collections/index.md), pas un par dossier. Hors perimetre de
# ce gardien, comme tools/ ou state/ le sont deja pour d'autres raisons.
# ".agents" ajoute (ticket 06, Mission 168) : meme motif que ".claude" et
# ".codex" deja presents -- emplacement officiel des skills et sous-agents
# Codex (T11), un dossier machine-lu par un outil tiers, jamais un contenu
# du corpus documentaire indexe par ce script.
# "_trash" ajoute (Mission 175, etape 7) : corbeille du produit, contenu
# retire de la distribution et fige (Decision 110852) -- jamais navigue par
# l'ordre de recherche par index (assistant/ASSISTANT.md), donc jamais
# indexe, meme motif que "state".
# "web-package" ajoute (Mission 183-C01), meme liste que
# tools/build_indexes.py : paquet genere pour un Projet web, jamais indexe.
PRUNE_NAMES = set(
    ".git .githooks .claude .codex .agents graphify-out tools patterns "
    "node_modules state .venv venv __pycache__ skills-warehouse _trash "
    "web-package".split()
)

# Mission 140 : index.md et ses archives figees ne s'indexent jamais eux-memes
# (meme regle que tools/build_indexes.py).
ARCHIVE_RE = re.compile(r"^index-archive-.+\.md$")


def is_index_name(name):
    return name == "index.md" or bool(ARCHIVE_RE.match(name))


# --- Bloc Bash l.22-35 : is_pruned_dir --------------------------------------
def is_pruned_dir(d):
    if d == ".":
        return False
    return any(comp in PRUNE_NAMES for comp in d.split("/"))


# --- Bloc Bash l.78-79 : butee MISSION-INDEX.md -----------------------------
# Chemin relatif a la racine du DEPOT COURANT (celui qui commite -- un projet
# cree par tools/project-bootstrap.sh, dont le registre vit a la racine de
# son propre dossier missions/, jamais sous un sous-dossier d'atelier :
# "workshop-production/" etait un chemin d'atelier laisse en dur (Mission
# 174, audit ; Mission 175, etape 2), sans effet sur un projet reel puisque
# ce sous-dossier n'y existe jamais -- la butee ne se declenchait donc
# jamais hors de l'atelier de l'Owner. Mesure au meme rapport : ce depot
# (second-brain) lui-meme ne porte aucun dossier missions/ a sa racine, donc
# ce changement ne modifie la severite d'aucun contenu reel de ce depot.
MISSION_INDEX_LINE_CAP_BASELINE = 122
MISSION_INDEX_PATH = "missions/MISSION-INDEX.md"

FAIL = 0


# --- Bloc Bash l.113-119 : report_gap (stdout) ------------------------------
def report_gap(dossier, ecart, index_path):
    global FAIL
    out("INDEX-FRESHNESS [%s]" % dossier)
    out("  Ecart    : %s" % ecart)
    out(
        "  Consigne : bash tools/build-indexes.sh <racine> ; git add %s ; "
        "relire git diff --cached" % index_path
    )
    FAIL = 1


# --- Appels Git (trois, fixes) ----------------------------------------------
# Point d'appel unique : toute commande externe du gardien passe ici. Il est
# invoque exactement trois fois, jamais dans une boucle (voir GIT_CALLS).
GIT_CALLS = []


def git_out(args, payload=None):
    GIT_CALLS.append(" ".join(["git"] + args))
    return subprocess.run(["git"] + args, input=payload, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout


def decode(b):
    return b.decode("utf-8", errors="surrogateescape")


# Appel 1 -- Bloc Bash l.259 : jeu stage.
diff_raw = decode(
    git_out(
        [
            "diff",
            "--cached",
            "--name-status",
            "-M",
            "--diff-filter=ACDMR",
            "--",
            "*.md",
        ]
    )
)

# Appel 2 -- Bloc Bash l.128 : fichiers presents dans l'arbre stage.
lsfiles_raw = git_out(["ls-files", "-z"])
TRACKED = [decode(p) for p in lsfiles_raw.split(b"\x00") if p]


# --- Bloc Bash l.236-259 : dossiers touches par un .md stage ----------------
DIRS = []
for line in diff_raw.split("\n"):
    if not line:
        continue
    fields = line.split("\t")
    st = fields[0]
    if not st:
        continue
    # R*/C* portent deux chemins ; les autres un seul (l.240-243).
    paths = fields[1:3] if st[:1] in ("R", "C") else fields[1:2]
    for p in paths:
        if not p:
            continue
        if not p.endswith(".md"):
            continue
        fn = p.rsplit("/", 1)[-1]
        if is_index_name(fn):
            continue
        d = p.rsplit("/", 1)[0] if "/" in p else "."
        if is_pruned_dir(d):
            continue
        if d not in DIRS:
            DIRS.append(d)

# --- Mission 161 : union avec tout dossier indexe de l'arbre stage ----------
# La boucle ci-dessus ne retient qu'un dossier ayant recu un .md non-index
# dans le commit en cours. Un dossier que le commit ne touche pas n'etait donc
# jamais controle : angle mort mesure au rapport 160 -- cinq index restes au
# format ancien quatre jours durant, et decisions/index.md monte a 16 495
# octets, 206 % du plafond, sans qu'aucun gardien ne le voie. Tout dossier de
# l'arbre stage portant un index.md est desormais controle, que le commit y
# touche ou non.
# Aucun appel Git ajoute (arbitrage du 2026-09-04, trois appels fixes) :
# TRACKED vient du `git ls-files` deja lu a l'appel 2. La grammaire n'est pas
# touchee -- ni ENTRY_RE, ni check_dir, ni PRUNE_NAMES.
for p in TRACKED:
    if p.rsplit("/", 1)[-1] != "index.md":
        continue
    d = p.rsplit("/", 1)[0] if "/" in p else "."
    if is_pruned_dir(d):
        continue
    if d not in DIRS:
        DIRS.append(d)


# --- Bloc Bash l.128-136 : .md de profondeur 1 d'un dossier, tries ----------
# Tri par octets : identique au `sort` du contexte, mesure du 2026-09-05 sur
# les 154 noms reels de missions/.
def disk_files_of(d):
    prefix = "" if d == "." else d + "/"
    res = []
    for f in TRACKED:
        if not f.startswith(prefix):
            continue
        rel = f[len(prefix):]
        if "/" in rel or is_index_name(rel) or not rel.endswith(".md"):
            continue
        res.append(rel)
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


# --- Appel 3 : tous les contenus de l'arbre stage, en une passe -------------
# Remplace les `git show ":$path"` et `git cat-file -e ":$path"` que le Bash
# lancait par fichier (l.143, l.149, l.177, l.82, l.85).
def batch_read(specs):
    if not specs:
        return {}
    payload = ("\n".join(specs) + "\n").encode("utf-8", errors="surrogateescape")
    raw = git_out(["cat-file", "--batch"], payload)
    res = {}
    pos = 0
    for spec in specs:
        nl = raw.find(b"\n", pos)
        if nl == -1:
            break
        header = raw[pos:nl]
        pos = nl + 1
        if header.endswith(b" missing"):
            res[spec] = None
            continue
        size = int(header.split(b" ")[2])
        res[spec] = raw[pos:pos + size]
        pos += size + 1  # le contenu est suivi d'un \n ajoute par cat-file
    return res


DISK = {d: disk_files_of(d) for d in DIRS}

# Mission 140 : archives figees d'un dossier, presentes dans l'arbre stage.
ARCHIVES = {}
for d in DIRS:
    prefix_d = "" if d == "." else d + "/"
    found = []
    for f in TRACKED:
        if not f.startswith(prefix_d):
            continue
        rel = f[len(prefix_d):]
        if "/" not in rel and ARCHIVE_RE.match(rel):
            found.append(f)
    ARCHIVES[d] = sorted(found, key=lambda s: s.encode("utf-8", errors="surrogateescape"))

specs = []
for d in DIRS:
    if not DISK[d]:
        continue
    specs.append(":" + ("index.md" if d == "." else d + "/index.md"))
    for arch in ARCHIVES[d]:
        specs.append(":" + arch)
    prefix = "" if d == "." else d + "/"
    for fn in DISK[d]:
        fpath = prefix + fn
        if fpath.startswith("./"):  # l.176
            fpath = fpath[2:]
        specs.append(":" + fpath)
specs.append(":" + MISSION_INDEX_PATH)
BLOBS = batch_read(specs)


def staged_text(path):
    b = BLOBS.get(":" + path)
    if b is None:
        return None
    # `$(git show ...)` supprime les newlines finaux (l.149, l.177, l.85).
    return decode(b).rstrip("\n")


# --- Bloc Bash l.39-48 : fm_status_desc, meme grammaire que build-indexes ---
def fm_status_desc(text):
    infm = False
    status = ""
    description = ""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
                continue
        if infm and line == "---":
            infm = False
        if infm and line.startswith("status:"):
            v = re.sub(r"^status:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            status = v
        if infm and line.startswith("description:"):
            v = re.sub(r"^description:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            description = v
    return status, description


# --- Bloc Bash l.50-58 : fm_type -------------------------------------------
def fm_type(text):
    infm = False
    ty = ""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
                continue
        if infm and line == "---":
            infm = False
        if infm and line.startswith("type:"):
            v = re.sub(r"^type:[ \t\r\f\v]*", "", line)
            v = re.sub(r'^"|"$', "", v)
            ty = v
    return ty if ty else "inconnu"


# --- Bloc Bash l.60-66 : contenu_section -----------------------------------
def contenu_section(text):
    on = False
    res = []
    for line in text.split("\n"):
        if re.match(r"^## Contenu[ \t\r\f\v]*$", line):
            on = True
            continue
        if line.startswith("## "):
            on = False
        if on:
            res.append(line)
    return res


# --- Mission 140 : format de ligne en localisateur -------------------------
# "- `<identifiant>` · <statut> · <titre court> · `<nom de fichier>`"
# suivi, le cas echeant, de " — REMPLACÉ par <nom>". Le statut ne contient
# jamais de "·" ; le titre peut en contenir, d'ou le groupe gourmand.
ENTRY_RE = re.compile(r"^- `[^`]*` · ([^·]*?) · .* · `([^`]*)`$")
MARK = " — REMPLACÉ par "


def parse_entry(line):
    """Rend (nom de fichier, statut) pour une ligne d'entree, sinon None."""
    if MARK in line:
        line = line.split(MARK, 1)[0]
    m = ENTRY_RE.match(line)
    if not m:
        return None
    return m.group(2), m.group(1)


# --- Bloc Bash l.155 : comm -13 sur deux listes triees ---------------------
def comm_13(disk, index_names):
    i = j = 0
    only_second = []
    while i < len(disk) and j < len(index_names):
        a = disk[i].encode("utf-8", errors="surrogateescape")
        b = index_names[j].encode("utf-8", errors="surrogateescape")
        if a == b:
            i += 1
            j += 1
        elif a < b:
            i += 1
        else:
            only_second.append(index_names[j])
            j += 1
    only_second.extend(index_names[j:])
    return only_second


# --- Bloc Bash l.121-232 : check_dir ---------------------------------------
def check_dir(d):
    prefix = "" if d == "." else d + "/"

    disk_files = DISK[d]
    if not disk_files:  # l.138 : pas un dossier indexe
        return

    index_path = "index.md" if d == "." else d + "/index.md"

    index_content = staged_text(index_path)
    if index_content is None:  # l.143-146
        report_gap(
            d,
            "dossier indexe sans index.md (%s absent de l'arbre stage)" % index_path,
            index_path,
        )
        return

    # Mission 140 : l'index d'un dossier peut etre scinde en un index vivant
    # et des archives figees (DECISION-2026-09-05-124647 point 4). L'ensemble
    # des noms se lit sur la reunion des deux -- le vivant seul est une vue
    # partielle, et refuserait a tort toute entree archivee.
    contenu = contenu_section(index_content)
    for arch_path in ARCHIVES.get(d, []):
        arch_text = staged_text(arch_path)
        if arch_text is not None:
            contenu = contenu + contenu_section(arch_text)

    index_entries = {}  # nom de fichier -> statut porte par l'index
    for line in contenu:
        parsed = parse_entry(line)
        if parsed:
            index_entries[parsed[0]] = parsed[1]
    index_names = sorted(
        index_entries, key=lambda s: s.encode("utf-8", errors="surrogateescape")
    )

    # l.153-163 : entrees en trop.
    for fn in comm_13(disk_files, index_names):
        if not fn:
            continue
        report_gap(
            d,
            "entree en trop dans l'index : %s (absent du dossier apres le commit)" % fn,
            index_path,
        )

    # l.165-231 : entree manquante, puis desynchro status/description.
    for fn in disk_files:
        if not fn:
            continue

        if fn not in index_names:  # l.170-173
            report_gap(d, "entree manquante dans l'index : %s" % fn, index_path)
            continue

        fpath = (prefix + fn)
        if fpath.startswith("./"):
            fpath = fpath[2:]
        fm_content = staged_text(fpath)
        if fm_content is None:
            fm_content = ""
        st, _ = fm_status_desc(fm_content)
        ty = fm_type(fm_content)

        # Mission 140 : la ligne est un localisateur, le statut y est un champ
        # a part entiere ; la description a disparu des index (DECISION
        # 124647 point 1), sa comparaison disparait donc aussi.
        expected = st if st else ty
        found = index_entries.get(fn)
        if found != expected:
            if st:
                report_gap(
                    d,
                    'status desynchronise pour %s (fichier: "%s")' % (fn, st),
                    index_path,
                )
            else:
                report_gap(
                    d,
                    "status desynchronise pour %s (fichier: aucun status)" % fn,
                    index_path,
                )


# --- Bloc Bash l.81-109 : butee 300 caracteres (stderr) --------------------
def check_mission_index_line_cap():
    global FAIL
    content = staged_text(MISSION_INDEX_PATH)
    if content is None:  # l.82 : git cat-file -e ... || return 0
        return

    line_no = 0
    for line in content.split("\n"):
        line_no += 1
        # l.89-92 : motif "| `NNN` |" en tete de ligne.
        m = re.match(r"^\| `([0-9]+)`.*", line)
        if not m:
            continue
        nnn = int(m.group(1))
        if nnn <= MISSION_INDEX_LINE_CAP_BASELINE:  # l.97
            continue
        # l.99 : `wc -m` compte les caracteres, pas les octets, et le newline
        # n'est pas compte (printf '%s').
        length = len(line)
        if length > 300:
            err("INDEX-LINE-CAP [%s]" % MISSION_INDEX_PATH)
            err("  Ligne    : %d (Mission %d)" % (line_no, nnn))
            err(
                "  Longueur : %d caracteres > 300 (Decision 191407)" % length
            )
            FAIL = 1


# --- Bloc Bash l.263-273 : ordre d'execution -------------------------------
for d in DIRS:
    check_dir(d)

# l.271-273 : butee seulement si MISSION-INDEX.md est stage dans ce commit.
staged_now = set()
for line in diff_raw.split("\n"):
    if not line:
        continue
    fields = line.split("\t")
    if not fields[0]:
        continue
    if fields[0][:1] in ("A", "C", "M", "R"):
        staged_now.update(p for p in fields[1:3] if p)
if MISSION_INDEX_PATH in staged_now:
    check_mission_index_line_cap()

# --- Bloc Bash l.275 -------------------------------------------------------
sys.stdout.buffer.flush()
sys.stderr.buffer.flush()
sys.exit(FAIL)
