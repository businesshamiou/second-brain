#!/usr/bin/env python3
# Generateur d'index (Mission 080, reecrit en Python par la Mission 140 pour
# appliquer la DECISION-2026-09-05-124647). Regenere un index.md par dossier
# eligible, sous chaque racine passee en argument. Genere uniquement : ne
# jamais editer un index.md a la main.
#
# usage: build_indexes.py [-v|--verbose] <racine...>
#
# Mission 172, audit defect 3: quiet by default (one summary line per
# invocation) since Mission 172; -v/--verbose restores the full per-file
# detail this file used to always print.
#
# SEMANTIQUE CONSERVEE de tools/build-indexes.sh (lu en entier avant
# reecriture) : parcours du WORKTREE (jamais de l'arbre stage -- c'est le
# gardien de fraicheur qui lit l'arbre stage), memes noms de dossiers elagues,
# .md de profondeur 1 par dossier hors index.md, tri par chemin, marquage
# "REMPLACE par" depuis le champ supersedes, ecriture de superseded-files.txt
# par racine (supprime s'il serait vide, Mission 127), meme front-matter
# d'index, meme section Liens avec chemin relatif et suffixe "(hors Vault)".
#
# CE QUI CHANGE (DECISION-2026-09-05-124647) :
#   point 1 -- une ligne d'index est un LOCALISATEUR, jamais une description :
#              "- `<identifiant>` · <statut> · <titre court> · `<nom>`".
#              La description du front-matter n'est plus reprise : elle vit
#              dans le fichier pointe.
#   point 4 -- si l'index d'un dossier depasse WEIGHT_CAP octets, il est
#              scinde : index.md garde les N entrees les plus recentes,
#              index-archive.md porte le reste. N est CALCULE ici a chaque
#              generation, jamais fixe a la main.
#
# CHOIX DELEGUES PAR LA MISSION 140 ET PRECISION OWNER DU 2026-09-05, fixes
# ici une fois pour toutes et documentes :
#   1. Titre court : TITLE_MAX = 80 caracteres, troncature a l'ellipse.
#   2. Archives NUMEROTEES sur une cle STABLE, jamais recalculee : une entree
#      ne change jamais de fichier d'archive.
#        - dossiers dont les noms portent un numero de Mission (missions/,
#          reports/, prompt-archive/) : tranches fixes de ARCHIVE_SLICE
#          numeros, fichier index-archive-<debut>-<fin>.md ;
#        - autres dossiers dates : par periode close, granularite
#          ARCHIVE_PERIOD, fichier index-archive-<AAAA-MM>.md.
#      Seule la derniere tranche grandit ; les precedentes sont figees.
#   3. Taille de tranche CALCULEE sur les donnees reelles (Mission 140,
#      2026-09-05), la tranche la plus dense devant tenir sous WEIGHT_CAP :
#        tranche 10 -> 16 archives, plus dense 2 768 o
#        tranche 20 ->  9 archives, plus dense 4 685 o (missions/)
#                       7 archives, plus dense 6 306 o (reports/)
#        tranche 25 ->  7 archives, plus dense 5 681 o / 7 029 o
#        tranche 50 ->  4 archives, plus dense 10 403 o  DEPASSE
#      Retenu : 20, la marge la plus sure (21 % au pire) pour un nombre
#      d'archives raisonnable. Periode : le mois (pire cas mesure 5 811 o,
#      captures/ 2026-08) ; le trimestre et la semaine depassent sur reports/.
#   4. Interpretation du point 4 de la Decision, consignee : les archives
#      forment une partition EXHAUSTIVE et STABLE de toutes les entrees ;
#      l'index vivant est une VUE des N entrees les plus recentes (N calcule
#      a chaque generation pour tenir sous le plafond), en doublon assume
#      avec la derniere archive. "Ouvert/clos" n'est pas derivable du
#      front-matter -- le status d'une Mission est fige a AUTHORIZED par
#      doctrine du gabarit, et la notion n'a pas de sens pour reports/ ou
#      decisions/ ; "les plus recentes" en tient lieu, le tri par nom etant
#      chronologique.

import os
import re
import sys

WEIGHT_CAP = 8000  # DECISION-2026-09-05-124647 point 3
TITLE_MAX = 80  # choix delegue 1
ARCHIVE_SLICE = 20  # choix delegue 3 : tranche de numeros, calculee
ARCHIVE_PERIOD = "mois"  # choix delegue 3 : granularite des dossiers dates
ARCHIVE_PREFIX = "index-archive-"

# Bloc Bash l.18 : memes noms elagues, a n'importe quelle profondeur.
# `skills-warehouse` ajoute (ticket 02, Mission 168, meme motif et arbitrage
# Owner que la correction deja appliquee a tools/check_indexes_fresh.py,
# ticket 01 §16.3) : ce sous-arbre ne suit pas la convention d'index du
# Vault (un seul index.md natif, skill-collections/index.md), jamais un par
# dossier -- generer ici y creerait de nouveau les ~155 fichiers fantomes
# supprimes a la main lors du ticket 01, cette fois de facon reproductible.
# ".agents" ajoute (ticket 06, Mission 168) : meme motif que ".claude" et
# ".codex" deja presents -- emplacement officiel des skills et sous-agents
# Codex (T11), un dossier machine-lu par un outil tiers, jamais un contenu
# du corpus documentaire indexe par ce script.
# "_trash" ajoute (Mission 175, etape 7) : corbeille du produit, contenu
# retire de la distribution et fige (Decision 110852) -- jamais navigue par
# l'ordre de recherche par index (assistant/ASSISTANT.md), donc jamais
# indexe, meme motif que "state".
PRUNE_NAMES = {
    ".git", ".githooks", ".claude", ".codex", ".agents", "graphify-out",
    "tools", "patterns", "node_modules", "state", ".venv", "venv",
    "__pycache__", "skills-warehouse", "_trash",
}

ARCHIVE_RE = re.compile(r"^index-archive-.+\.md$")


def is_index_name(name):
    """Les index generes ne s'indexent jamais eux-memes."""
    return name == "index.md" or bool(ARCHIVE_RE.match(name))


def read_text(path):
    # Le worktree peut porter des CRLF (4 fichiers .md du vault, mesure
    # Mission 142) la ou l'arbre stage rend des LF : sans cette
    # normalisation, la ligne d'ouverture du front-matter vaut "---\r", le
    # front-matter n'est pas reconnu, et l'entree tombe en "(sans titre)" /
    # "inconnu" -- regression mesuree contre l'awk d'origine, qui lisait ces
    # memes fichiers correctement.
    with open(path, "rb") as fh:
        raw = fh.read().decode("utf-8", errors="surrogateescape")
    return raw.replace("\r\n", "\n")


def write_text(path, text):
    with open(path, "wb") as fh:
        fh.write(text.encode("utf-8", errors="surrogateescape"))


# --- Bloc Bash l.25-40 : list_fields, meme grammaire de champ ---------------
FIELD_RE = {
    k: re.compile(r"^%s:[ \t\r\f\v]*(.*)$" % k)
    for k in ("title", "type", "status", "description")
}


def front_matter(text):
    """title/type/status/description, meme traitement des guillemets que l'awk
    d'origine (retrait d'un guillemet en tete et en fin), aucune valeur de
    repli ici -- les defauts sont appliques par l'appelant."""
    out = {"title": "", "type": "", "status": "", "description": ""}
    lines = text.split("\n")
    infm = False
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
            continue
        if infm and line == "---":
            infm = False
            continue
        if not infm:
            continue
        for key, rx in FIELD_RE.items():
            m = rx.match(line)
            if m:
                v = re.sub(r'^"|"$', "", m.group(1))
                out[key] = v
    return out


# --- Bloc Bash l.46-68 : extract_supersedes_raw ----------------------------
SUPERSEDES_RE = re.compile(r"^supersedes:[ \t\r\f\v]*(.*)$")
LIST_ITEM_RE = re.compile(r"^[ \t]+-[ \t]*(.*)$")
MD_NAME_RE = re.compile(r"([A-Za-z0-9._-]+\.md)")


def supersedes_values(text):
    """Valeurs du champ supersedes : scalaire ou items d'une liste YAML."""
    vals = []
    lines = text.split("\n")
    infm = False
    insup = False
    for i, line in enumerate(lines):
        if i == 0:
            if line == "---":
                infm = True
            continue
        if infm and line == "---":
            infm = False
            insup = False
            continue
        if not infm:
            continue
        m = SUPERSEDES_RE.match(line)
        if m:
            insup = True
            if m.group(1) != "":
                vals.append(m.group(1))
            continue
        if insup:
            mi = LIST_ITEM_RE.match(line)
            if mi:
                vals.append(mi.group(1))
            else:
                insup = False
    return vals


# --- Bloc Bash l.85 et l.127-135 : parcours du worktree --------------------
def walk_dirs(root_abs):
    """Dossiers sous la racine, elagage identique au find -prune du Bash."""
    for dirpath, dirnames, _ in os.walk(root_abs):
        dirnames[:] = [d for d in dirnames if d not in PRUNE_NAMES]
        if any(part in PRUNE_NAMES for part in dirpath.replace("\\", "/").split("/")):
            continue
        yield dirpath


def md_files_of(dirpath):
    """.md de profondeur 1, hors index generes, tries par octets comme sort."""
    try:
        names = os.listdir(dirpath)
    except OSError:
        return []
    res = [
        n for n in names
        if n.endswith(".md")
        and not is_index_name(n)
        and os.path.isfile(os.path.join(dirpath, n))
    ]
    res.sort(key=lambda s: s.encode("utf-8", errors="surrogateescape"))
    return res


def short_title(title):
    """Titre court, choix delegue 1. Troncature sur la longueur en caracteres."""
    t = title if title else "(sans titre)"
    if len(t) > TITLE_MAX:
        t = t[: TITLE_MAX - 1].rstrip() + "…"
    return t


def identifier(name, fields):
    """Identifiant de l'entree (DECISION point 1 : numero, horodatage ou nom).
    Derive du nom de fichier, jamais saisi : numero de Mission ou de rapport
    quand le nom en porte un (140, 137-B), sinon l'horodatage, sinon le nom
    sans extension."""
    # Variante d'une lignee : suffixe court et type seulement (132-A, 137-B,
    # 002-C01, 128-bis). Un mot de slug qui suit le numero n'en est pas une :
    # sans cette restriction, 133-vault-entry-chain rendrait "133-vault"
    # (mesure Mission 140, 2026-09-05, sur les 157 entrees reelles).
    m = re.match(
        r"^(?:MISSION|REPORT|PROMPT)-\d{4}-\d{2}-\d{2}-\d{6}-"
        r"(\d+(?:-(?:[A-Z]{1,2}|C\d+|bis|ter))?)(?:-|$)",
        name,
    )
    if m:
        return m.group(1)
    m = re.match(r"^[A-Z-]+-(\d{4}-\d{2}-\d{2}-\d{6})-", name)
    if m:
        return m.group(1)
    m = re.match(r"^[A-Z-]+-(\d{4}-\d{2}-\d{2})-", name)
    if m:
        return m.group(1)
    return name[:-3] if name.endswith(".md") else name


def entry_line(name, fields, superseded_by):
    """Ligne d'index en localisateur (DECISION point 1).
    Forme exacte : "- `<id>` · <statut> · <titre court> · `<nom>`", suivie
    de " — REMPLACE par <nom>" quand le fichier est remplace."""
    ident = identifier(name, fields)
    status = fields["status"] if fields["status"] else (
        fields["type"] if fields["type"] else "inconnu"
    )
    line = "- `%s` · %s · %s · `%s`" % (
        ident, status, short_title(fields["title"]), name
    )
    if name in superseded_by:
        line += " — REMPLACÉ par %s" % superseded_by[name]
    return line


# --- Cle d'archive STABLE (precision Owner 2026-09-05) ---------------------
NUM_RE = re.compile(r"^[A-Z-]+-\d{4}-\d{2}-\d{2}-\d{6}-(\d+)")
DATE_RE = re.compile(r"^[A-Z-]+-(\d{4})-(\d{2})-\d{2}-")


def archive_key(name):
    """Cle d'archive d'une entree : figee par le nom du fichier, jamais
    recalculee d'une generation a l'autre. Rend (cle_de_tri, suffixe) ou None
    si l'entree n'a pas de cle stable (elle reste alors dans l'index vivant)."""
    m = NUM_RE.match(name)
    if m:
        n = int(m.group(1))
        start = (n // ARCHIVE_SLICE) * ARCHIVE_SLICE
        end = start + ARCHIVE_SLICE - 1
        return ((0, start), "%d-%d" % (start, end))
    m = DATE_RE.match(name)
    if m:
        y, mo = m.group(1), m.group(2)
        if ARCHIVE_PERIOD == "mois":
            return ((1, "%s-%s" % (y, mo)), "%s-%s" % (y, mo))
        q = (int(mo) - 1) // 3 + 1
        return ((1, "%s-T%d" % (y, q)), "%s-T%d" % (y, q))
    return None


# --- Bloc Bash l.152-185 : rendu d'un index --------------------------------
def render(title, entries, rel_std, hors_suffix, archive_note=""):
    parts = [
        "---",
        "type: index",
        'title: "Index — %s"' % title,
        'description: "Index généré automatiquement par tools/build-indexes.sh."',
        "status: active",
        "generated_by: tools/build-indexes.sh",
        "---",
        "",
        "# Index — %s" % title,
        "",
        "Index généré automatiquement. Ne pas éditer à la main : régénérer via "
        "`tools/build-indexes.sh`.",
        "",
    ]
    if archive_note:
        parts += [archive_note, ""]
    parts += ["## Contenu", ""]
    parts += entries
    parts += ["", "## Liens", ""]
    if rel_std:
        parts.append(
            "- `prescribed by` — [Standard de liens entre documents](%s)%s"
            % (rel_std, hors_suffix)
        )
    return "\n".join(parts) + "\n"


def main(argv):
    # Mission 172, audit defect 3: this used to write one stderr line per
    # regenerated index.md/archive unconditionally -- across the 3 calls a
    # nominal install makes (Save-ClonePendingChanges x2, project-bootstrap.sh
    # x1), that dumped the full list three times over, with no per-step
    # result line to make sense of it. Default is now one summary line per
    # invocation; -v/--verbose restores the full per-file detail this file
    # used to always print (kept byte-identical when passed, so a
    # troubleshooting session loses nothing).
    verbose = False
    roots = []
    for arg in argv:
        if arg in ("-v", "--verbose"):
            verbose = True
        else:
            roots.append(arg)
    argv = roots

    if not argv:
        sys.stderr.write("usage: build_indexes.py [-v|--verbose] <racine...>\n")
        return 1

    live_count = 0
    archive_count = 0

    def emit(message):
        if verbose:
            sys.stderr.write(message)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    vault_root = os.path.abspath(os.path.join(script_dir, ".."))
    std_link_target = os.path.join(
        vault_root, "rules", "RULES-2026-08-21-115658-document-linking-standard.md"
    )

    for root in argv:
        if not os.path.isdir(root):
            continue
        root_abs = os.path.abspath(root)

        # Carte des remplacements, portee a cette racine (bloc Bash l.88-96).
        superseded_by = {}
        all_md = []
        for dirpath in walk_dirs(root_abs):
            for name in md_files_of(dirpath):
                all_md.append(os.path.join(dirpath, name))
        for path in all_md:
            try:
                text = read_text(path)
            except OSError:
                continue
            for raw in supersedes_values(text):
                m = MD_NAME_RE.search(raw)
                if m:
                    superseded_by[m.group(1)] = os.path.basename(path)

        # superseded-files.txt de la racine (bloc Bash l.110-125).
        listed = sorted(
            (
                os.path.relpath(p, root_abs).replace("\\", "/")
                for p in all_md
                if os.path.basename(p) in superseded_by
            ),
            key=lambda s: s.encode("utf-8", errors="surrogateescape"),
        )
        sup_file = os.path.join(root_abs, "superseded-files.txt")
        if listed:
            write_text(sup_file, "\n".join(listed) + "\n")
        elif os.path.exists(sup_file):
            os.remove(sup_file)

        for dirpath in walk_dirs(root_abs):
            names = md_files_of(dirpath)
            if not names:
                continue

            title = os.path.basename(dirpath)
            rel_std = os.path.relpath(std_link_target, dirpath).replace("\\", "/")
            if not rel_std.startswith(("../", "./")):
                rel_std = "./" + rel_std
            hors = ""
            if not (dirpath == vault_root or dirpath.startswith(vault_root + os.sep)):
                hors = " (hors Vault)"

            entries = []
            for name in names:
                try:
                    fields = front_matter(read_text(os.path.join(dirpath, name)))
                except OSError:
                    continue
                entries.append(entry_line(name, fields, superseded_by))

            index_path = os.path.join(dirpath, "index.md")

            # Archives existantes de ce dossier, pour retirer celles qui ne
            # sont plus produites (aucune suppression de contenu : le fichier
            # n'existe que s'il porte des entrees).
            existing_archives = {
                n for n in os.listdir(dirpath) if ARCHIVE_RE.match(n)
            }

            whole = render(title, entries, rel_std, hors)
            if len(whole.encode("utf-8", errors="surrogateescape")) <= WEIGHT_CAP:
                write_text(index_path, whole)
                for stale in existing_archives:
                    os.remove(os.path.join(dirpath, stale))
                live_count += 1
                emit(index_path + "\n")
                continue

            # --- Scission (DECISION point 4, precision Owner 2026-09-05) ---
            # Archives : partition EXHAUSTIVE et STABLE par cle figee.
            buckets = {}
            no_key = []
            for name, line in zip(names, entries):
                key = archive_key(name)
                if key is None:
                    no_key.append(line)
                else:
                    buckets.setdefault(key, []).append(line)

            produced = set()
            for (sort_key, suffix) in sorted(buckets, key=lambda k: k[0]):
                lines = buckets[(sort_key, suffix)]
                arch_name = "%s%s.md" % (ARCHIVE_PREFIX, suffix)
                arch_note = (
                    "Archive figée : les entrées de cette tranche n'en changent "
                    "jamais. L'index courant est [`index.md`](./index.md) "
                    "(DECISION-2026-09-05-124647, point 4)."
                )
                arch = render(
                    "%s — archive %s" % (title, suffix), lines, rel_std, hors, arch_note
                )
                arch_path = os.path.join(dirpath, arch_name)
                write_text(arch_path, arch)
                produced.add(arch_name)
                size = len(arch.encode("utf-8", errors="surrogateescape"))
                flag = "" if size <= WEIGHT_CAP else "  DEPASSE LE PLAFOND"
                archive_count += 1
                emit("%s (%d o)%s\n" % (arch_path, size, flag))

            for stale in existing_archives - produced:
                os.remove(os.path.join(dirpath, stale))

            # Index vivant : vue des N entrees les plus recentes, N calcule.
            arch_list = ", ".join(
                "[`%s%s.md`](./%s%s.md)" % (ARCHIVE_PREFIX, s, ARCHIVE_PREFIX, s)
                for (_, s) in sorted(buckets, key=lambda k: k[0])
            )
            note = (
                "Index vivant : les entrées les plus récentes. La totalité est "
                "répartie en archives figées — %s." % arch_list
            )
            n = len(entries)
            while n > 0:
                cand = render(title, entries[len(entries) - n:], rel_std, hors, note)
                if len(cand.encode("utf-8", errors="surrogateescape")) <= WEIGHT_CAP:
                    break
                n -= 1
            live = render(title, entries[len(entries) - n:], rel_std, hors, note)
            write_text(index_path, live)
            live_count += 1
            emit("%s (vivant, N=%d)\n" % (index_path, n))

    # Mission 173 step 7 (Q17): silent by default, full stop -- even the
    # one-line summary Mission 172 kept is noise once the installer prints
    # its own named step-per-line journal; -v/--verbose still restores
    # every per-file line AND this summary, unchanged.
    if verbose:
        sys.stderr.write(
            "build_indexes.py: %d index(es) regenerated (%d archived) across %d root(s)\n"
            % (live_count, archive_count, len(argv))
        )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
