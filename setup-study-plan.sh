#!/usr/bin/env bash
# setup-study-plan.sh
# Sets up GitHub tracking for the Hands-on Study Plan (Terraform, CI/CD, Kubernetes):
#   - 7 topic labels
#   - 9 weekly milestones (Week 0 to Week 8) with due dates
#   - Issues for Week 0 and Week 1, with "Done when" checklists
#
# Usage:
#   ./setup-study-plan.sh                    # uses the repo in the current folder
#   ./setup-study-plan.sh OWNER/REPO         # or name the repo explicitly
#   ./setup-study-plan.sh OWNER/REPO --dry-run   # show what would happen, change nothing
#
# Safe to run more than once: existing labels are updated, and milestones and
# issues that already exist (same title) are skipped.

set -euo pipefail

# ---------- Settings you can change ----------
# Due date of Week 0 (a Sunday). Each later week is due 7 days after the one before.
WEEK0_DUE="2026-11-01"
# ---------------------------------------------

REPO=""
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) REPO="$arg" ;;
  esac
done

# --- Checks ---
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed. Run: brew install gh" >&2
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  echo "You're not logged in to GitHub CLI. Run: gh auth login" >&2
  exit 1
fi
if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
    echo "Couldn't detect a repo here. Run this inside your cloned repo, or pass OWNER/REPO." >&2
    exit 1
  }
fi
echo "Repository: $REPO"
$DRY_RUN && echo "(dry run: nothing will be changed)"

run() {
  if $DRY_RUN; then
    printf '  would run: %s\n' "$*"
  else
    "$@"
  fi
}

# Adds N days to a YYYY-MM-DD date; works with macOS (BSD) and Linux (GNU) date.
add_days() {
  local start="$1" days="$2"
  date -j -v+"${days}"d -f "%Y-%m-%d" "$start" "+%Y-%m-%d" 2>/dev/null \
    || date -d "$start + $days days" "+%Y-%m-%d"
}

# ---------- Labels ----------
echo
echo "== Labels =="
create_label() {  # name color description
  echo "- $1"
  run gh label create "$1" --repo "$REPO" --color "$2" --description "$3" --force >/dev/null
}
create_label "terraform"  "7B42BC" "Infrastructure as code with Terraform"
create_label "ci-cd"      "2088FF" "GitHub Actions and Azure DevOps pipelines"
create_label "kubernetes" "326CE5" "Containers, ACR and AKS"
create_label "az-104"     "FBCA04" "AZ-104 exam study"
create_label "setup"      "C5DEF5" "Accounts, tools and repo housekeeping"
create_label "docs"       "0E8A16" "README, diagrams and write-ups"
create_label "blocked"    "D93F0B" "Stuck: needs help or a decision"

# ---------- Milestones ----------
echo
echo "== Milestones =="
MILESTONES=(
  "Week 0 – Setup"
  "Week 1 – Terraform basics"
  "Week 2 – Repeatable environments"
  "Week 3 – Configure Tomcat and app"
  "Week 4 – CI with GitHub Actions"
  "Week 5 – CD with Azure DevOps"
  "Week 6 – Containers"
  "Week 7 – Kubernetes on AKS"
  "Week 8 – Pipeline to AKS and polish"
)
existing_milestones=""
if ! $DRY_RUN; then
  existing_milestones=$(gh api "repos/$REPO/milestones?state=all&per_page=100" --jq '.[].title')
fi
for i in "${!MILESTONES[@]}"; do
  title="${MILESTONES[$i]}"
  due=$(add_days "$WEEK0_DUE" $((i * 7)))
  if grep -qxF "$title" <<<"$existing_milestones"; then
    echo "- $title (already exists, skipped)"
    continue
  fi
  echo "- $title (due $due)"
  run gh api "repos/$REPO/milestones" --method POST \
    -f title="$title" -f due_on="${due}T23:59:59Z" >/dev/null
done

# ---------- Issues ----------
echo
echo "== Issues =="
existing_issues=""
if ! $DRY_RUN; then
  existing_issues=$(gh issue list --repo "$REPO" --state all --limit 500 --json title --jq '.[].title')
fi
create_issue() {  # title milestone labels body
  local title="$1" milestone="$2" labels="$3" body="$4"
  if grep -qxF "$title" <<<"$existing_issues"; then
    echo "- $title (already exists, skipped)"
    return
  fi
  echo "- $title"
  run gh issue create --repo "$REPO" --title "$title" --milestone "$milestone" \
    --label "$labels" --body "$body" >/dev/null
}

W0="${MILESTONES[0]}"
W1="${MILESTONES[1]}"

create_issue "Week 0: Azure subscription and cost guardrails" "$W0" "setup" \
"Set up a personal Azure subscription with a spending cap before building anything.

**Done when**
- [ ] Azure free or pay-as-you-go account created (personal, not Vertex)
- [ ] Budget of \$25/month in Cost Management
- [ ] Email alerts at 50% and 90% of budget
- [ ] \`az login\` works from the Mac terminal"

create_issue "Week 0: Azure DevOps organization" "$W0" "setup,ci-cd" \
"Create the Azure DevOps organization used in Week 5.

**Done when**
- [ ] Azure DevOps organization created (free tier)
- [ ] Project created (public, or plan a self-hosted agent on the Mac)
- [ ] Note in this issue which option was chosen and why"

create_issue "Week 0: Install tools on the Mac" "$W0" "setup" \
"Install everything the plan uses.

**Done when**
- [ ] VS Code with HashiCorp Terraform, Microsoft Terraform, Azure Resources and Kubernetes extensions
- [ ] Azure CLI (\`az version\`)
- [ ] Terraform CLI (\`terraform version\`)
- [ ] Git and GitHub CLI (\`git --version\`, \`gh --version\`)
- [ ] Docker Desktop or Colima, and kubectl (\`kubectl version --client\`)
- [ ] VS Code set to format .tf files with the HashiCorp extension"

create_issue "Week 0: Repo housekeeping" "$W0" "setup,docs" \
"Get the repo ready for the weeks ahead.

**Done when**
- [ ] README has the starter content and roadmap
- [ ] .gitignore has the extra lines (macOS, .vscode, Java build output, .env, kubeconfig)
- [ ] Secret scanning push protection is on (Settings → Code security)
- [ ] Labels, milestones and issues created by this script
- [ ] Project board created and linked to the repo"

create_issue "Week 1: Terraform – resource group, VNet and subnet" "$W1" "terraform" \
"First Terraform configuration using the azurerm provider.

**Done when**
- [ ] Provider configured; \`terraform init\` succeeds
- [ ] Resource group, VNet and subnet defined
- [ ] \`terraform plan\` output reviewed and understood
- [ ] \`terraform apply\` creates them; verified in the portal"

create_issue "Week 1: Terraform – Linux VM and clean teardown" "$W1" "terraform" \
"Add a Linux VM to the network and prove the whole thing can be removed cleanly.

**Done when**
- [ ] Linux VM in the subnet, reachable over SSH (key, not password)
- [ ] \`terraform destroy\` removes everything; resource group gone in the portal
- [ ] \`.terraform.lock.hcl\` committed; no state files in the repo
- [ ] Short notes added to the README"

create_issue "Week 1: AZ-104 – Identities and governance" "$W1" "az-104" \
"About 4 hours of study on the first exam area.

**Done when**
- [ ] Microsoft Learn modules on Entra ID users and groups
- [ ] Role-based access control (RBAC) and scopes
- [ ] Azure Policy, tags and resource locks
- [ ] Subscriptions, management groups and cost management
- [ ] One-paragraph summary of what was hardest, added as a comment here"

echo
if $DRY_RUN; then
  echo "Dry run complete. Run again without --dry-run to make the changes."
else
  echo "Done. View the results:"
  echo "  Issues:     https://github.com/$REPO/issues"
  echo "  Milestones: https://github.com/$REPO/milestones"
fi
