# Ansible Roles — Modernization & Lint Compliance Report

**Date:** 2026-11-12
**Scope:** All roles under `roles/` plus `shared/`.
**Nothing was committed, staged, or pushed.** Every change below is a plain,
uncommitted working-tree edit — review it with `git status` / `git diff` and
decide what to keep.

## Approach

The repo already ships a strict, comprehensive `.ansible-lint` (profile
`shared`, `strict: true`, large custom `enable_list`). Rather than inventing
an arbitrary modernization checklist, I used that existing configuration as
the objective standard: "modernize" means *bring the repo into compliance
with the rules it already opted into*, fix genuine bugs found along the way,
and flag — rather than silently apply — any lint-driven change that carries
real functional or blast-radius risk.

Baseline: `ansible-lint --offline roles shared` → **733 findings across 27
rule categories**. After this pass: **336 findings across 6 categories** —
and every one of those remaining 336 is explained below (confirmed false
positive, or a deliberate, documented deferral — nothing was silently
ignored).

## Real bugs found and fixed (not just lint style)

These were functional problems, independent of lint — found by reading the
code and, for the second one, by a systematic scan (details below), not by
the linter itself.

### 1. `shell:` parameter corruption (pre-existing, from an earlier blind FQCN find/replace)

A prior pass that converted module names to FQCN form appears to have also
matched the `user` module's `shell:` *parameter* and rewritten it to
`ansible.builtin.shell:`, which Ansible does not recognize as a parameter of
the `user` module — these tasks would fail at runtime with "Unsupported
parameters". Fixed in: `roles/samba/tasks/main.yml`,
`roles/simpleproxy/tasks/main.yml`, `roles/traefik/tasks/install-traefik.yml`,
`roles/nfs/tasks/main.yml` (commented block), `roles/nginx/tasks/install-nginx.yml`.

### 2. The same corruption pattern, found more widely by a systematic sweep

Suspecting the bug above wasn't the only instance, I wrote a small parser
(walks every task/handler YAML file, and for each task's module-parameter
dict checks whether any parameter *key* itself looks like an FQCN — module
parameters never legitimately contain dots). It found **7 more instances**
across 4 files, all the same root cause: a parameter that happens to share
its name with a core module name (`command`, `service`) was blindly rewritten
to `ansible.builtin.<name>:`, which silently becomes an unknown/ignored
parameter rather than an error in some cases, or an outright task failure in
others:

- `roles/firewalld/tasks/main.yml` — "Set firewall rules" task:
  `ansible.posix.firewalld`'s `service:` parameter was corrupted. This is the
  most important one of the batch: it meant any firewalld rule defined by
  **service name** (rather than by raw port) was never actually being passed
  to the module — those rules silently did nothing.
- `roles/docker-deploy/tasks/doploy-service.yml` — `community.docker.docker_swarm_service`'s
  `command:` override (container entrypoint override) was being swallowed.
- `roles/influxdb/tasks/install-influxdb-docker.yml` (4 occurrences) and
  `roles/mgmt/handlers/main.yml` — `community.docker.docker_container_exec`'s
  `command:` parameter was corrupted, meaning these tasks never actually sent
  the intended `influx setup` / `influx auth` / `nginx -s reload` commands
  into the containers.

All 7 were fixed with the exact parameter name restored; re-ran the full lint
and the scanner afterward — zero regressions, zero remaining instances of the
pattern anywhere in the repo.

### 3. Other genuine bugs fixed along the way

- `roles/mgmt/tasks/install-mgmt-stack.yml` — Jinja2 syntax error:
  `{{ mgmt_services_to_install | list} }` → `{{ mgmt_services_to_install | list }}`.
- `roles/k8s/control-plane/defaults/main.yml` /
  `roles/k8s/control-plane/templates/kubelet-conf.yml.j2` — variable casing
  bugs: `k8s_clusterDNS` → `k8s_cluster_dns`, `k8s_gVisor_manifest` →
  `k8s_gvisor_manifest` (mixed-case Ansible variables are fragile/confusing;
  normalized to the repo's own snake_case convention).

## Lint categories fully resolved (0 remaining, were non-zero at baseline)

| Category | Baseline | Now |
|---|---|---|
| `var-naming[no-role-prefix]` | 227 | *(see "Deliberately not changed")* |
| `jinja[spacing]` | 93 | 0 |
| `name[casing]` | 80 | 0 |
| `yaml[indentation]` | 46 | 0 |
| `syntax-check[unknown-module]` | 30 | *(see below — false positive)* |
| `risky-file-permissions` | 27 | 0 |
| `fqcn[action-core]` | 25 | 0 |
| `no-changed-when` | 18 | 0 |
| `role-name` | 15 | *(see "Deliberately not changed")* |
| `package-latest` | 15 | 0 (1 intentional `noqa` exception, see below) |
| `yaml[colons]` | 12 | 0 |
| `no-log-password` | 11 | 0 |
| `yaml[octal-values]` | 10 | 0 |
| `no-handler` | 9 | *(see "Deliberately not changed")* |
| `literal-compare` | 8 | 0 |
| `ignore-errors` | 8 | 0 |
| `empty-string-compare` | 7 | 0 |
| `args[module]` | 5 | 1 *(false positive, see below)* |
| `yaml[truthy]` | 4 | 0 |
| `yaml[empty-lines]` | 3 | 0 |
| `risky-shell-pipe` | 3 | 0 |
| `command-instead-of-shell` | 3 | 0 |
| `var-naming[pattern]` | 2 | 0 |
| `command-instead-of-module` | 2 | 0 |
| `yaml[comments]` | 1 | 0 |
| `yaml[brackets]` | 1 | 0 |
| `jinja[invalid]` | 1 | 0 |

Representative fixes behind these numbers: FQCN added everywhere a short
module name was used (`community.general.timezone`, `community.mysql.*`,
`community.mongodb.mongodb_user`, `ansible.posix.firewalld`,
`ansible.posix.authorized_key`, `azure.azcollection.azure_rm_dnsrecordset`,
`hetzner.hcloud.hcloud_ssh_key_info`, `community.grafana.*`, etc. — each
verified against current collection docs rather than guessed, after I caught
myself guessing `ansible.builtin.timezone` wrong once and corrected it);
`mode:` added to every file/copy/template/lineinfile task that lacked one;
blanket `ignore_errors: true` replaced with precise `failed_when`/`changed_when`;
`state: latest` → `state: present` for package installs (upgrades should be
deliberate, not implicit); literal/empty-string boolean comparisons rewritten
idiomatically (`x == false` → `not x`); and the `roles/traefik` GitHub-releases
download rewritten to resolve the URL via `lookup("url", ...) | from_json`
instead of a brittle shell/curl/grep/cut pipeline.

## Partially addressed

`yaml[line-length]`: 68 → 54. The remainder are long Jinja expressions or
URLs that can't be wrapped without either breaking the Jinja or hurting
readability — left as-is rather than forcing an awkward line break.

## Deliberately NOT changed (with reasoning)

- **`no-handler` (9 instances).** Ansible handlers run at *end of play* by
  default. Several of the flagged tasks have real sequential/ordering
  dependencies within the same task file — converting them would change
  *when* they execute, which is a functional regression risk for a lint-style
  gain. Left as `ansible.builtin.command`/`service` tasks with correct
  `changed_when`, not auto-converted to handlers.

- **`role-name` (15 roles) and `var-naming[no-role-prefix]` (227 variables).**
  I investigated the blast radius rather than renaming blind:
  - The 15 hyphenated role directories (`app-deploy`, `azure-dns`,
    `cloudflare-dns`, `docker-deploy`, `gitlab-runner`, `k8s/control-plane`,
    `k8s/grafana-mimir`, `k8s/hcloud-autoscale-conf`, `k8s/ingress-kong`,
    `k8s/ingress-nginx`, `k8s/ingress-traefik`, `k8s/worker-join`,
    `k8s/worker-leave`, `netlify-dns`, `node-exporter`) are referenced **only**
    from files inside this repo (`pb_local.yml`, `pb_k8s_remote.yml`,
    `playbooks/pb_main.yml`, `pb_home.yml`, `pb_hcloud_personal.yml`,
    `pb_aks-oauth.yml`, `pb_k8s_cri_test.yml`, `.pre-commit-config.yaml`, the
    auto-generated `docs.md`) — no dynamic/templated role names, nothing
    external. This is lower risk and I have the full list of every file that
    needs a matching update; I didn't execute it in this pass because it's
    still a broad, simultaneous, 20+-file change better done as its own
    reviewed commit.
  - The 227 variables split into two very different risk tiers: **43** are
    `register:`/`set_fact:` names (task-local, never overridden externally —
    safe to rename anytime). The other **184** are declared in
    `defaults/main.yml` — i.e. the role's *public* interface. Your README
    shows the real inventory (`group_vars`/`host_vars` that override these
    defaults) is mounted from **outside this repo entirely**
    (`-v /d/servermgmt/cci:/inventory`), which this session can't see.
    Renaming those 184 would silently break any external override using the
    old name — Ansible just falls back to the new default with no error, a
    dangerous invisible regression on a repo that manages real hosts. I'm
    leaving this as a scoped, risk-stratified recommendation rather than
    guessing at what your external inventory does or doesn't override.
  - One variable worth calling out specifically: `firwalld_rules` in
    `roles/firewalld` is an actual typo of `firewalld_rules`, not just a
    missing prefix — included in the same deferred set for the same reason.

- **`syntax-check[unknown-module]` (30, false positive).**
  `ansible-galaxy collection install` is blocked in this sandbox
  (`galaxy.ansible.com` returns `403` via the org's egress proxy — confirmed
  network-level, not a typo). All 30 flagged modules were manually verified
  to already be correctly FQCN'd; the linter just can't resolve them without
  the collections installed. This should not reproduce in an environment
  with normal Galaxy access.

- **`args[module]` (1 remaining, false positive).** `pip`'s
  `break_system_packages` is an `ansible-core` 2.17+ feature; this sandbox's
  lint environment runs `ansible-core` 2.16.20, which doesn't recognize it.
  Not a real problem if your actual `ansible-core` is 2.17+.

- **`roles/maintenance/tasks/system-updates.yml:158` ("Upgrade packages")**
  kept `state: latest` intentionally — that task's entire purpose is to apply
  upgrades — and got a `# noqa: package-latest` comment explaining why,
  instead of being "fixed" into a no-op.

## New files / structural additions

- **`requirements.yml`** (repo root) — lists the 11 collections actually
  referenced via FQCN in `roles/`/`shared/` (`amazon.aws`, `ansible.posix`,
  `azure.azcollection`, `community.crypto`, `community.docker`,
  `community.general`, `community.grafana`, `community.mongodb`,
  `community.mysql`, `hetzner.hcloud`, `kubernetes.core`). Left unpinned with
  a comment explaining why — I didn't want to guess at version numbers that
  could differ from what's running in production.
- **`.ansible-lint`** `exclude_paths` broadened from 3 narrow entries to
  blanket globs (`roles/*/files/`, `roles/*/*/files/`, `roles/*/data/`,
  `roles/*/*/data/`). The first autofix pass had wrongly reformatted ~25
  static deployment artifacts (K8s manifests, Prometheus/Traefik/Promtail
  configs that get copied verbatim to hosts) before this was caught — those
  were reverted via `git restore`.
- **`roles/firewalld/meta/main.yml` + `roles/firewalld/meta/argument_specs.yml`**
  — a worked example. **Zero** of the 46 roles in this repo had a
  `meta/main.yml` or `argument_specs.yml` before this pass (this isn't a lint
  violation in the `shared` profile — `meta-no-info`/`meta-no-tags` only fire
  when `meta/main.yml` exists but is incomplete — so it's a "nice to have,"
  not something I mechanically rolled out to all 46 roles, which would risk
  inaccurate argument specs without testing against real hosts). This one
  role shows the pattern concretely if you want to extend it.

## Side notes — pre-existing, unrelated to this session

Flagging only so `git status` noise isn't mistaken for something I touched:
`playbooks/pb_k8s_cri_test.yml` was already moved (with edits) to a
root-level, untracked `pb_k8s_cri_test.yml` before this session started; and
`kata.yaml`, `docs.md`, `gen-var-docs.txt`, `inventroy/`, `pb_aks-oauth.yml`
are untracked files that already existed and that I never touched.

One mechanical side effect: because `requirements.yml` now exists,
`ansible-lint` will try `ansible-galaxy collection install -r requirements.yml`
before linting — which fails in this sandbox (Galaxy blocked). Use
`ansible-lint --offline` here; shouldn't matter wherever Galaxy is reachable.

## How to review / re-verify

- Nothing is committed or staged — `git status` / `git diff` shows the full,
  uncommitted set of changes (148 tracked files modified, 3 new untracked
  files: `requirements.yml` and the two `roles/firewalld/meta/*` files, plus
  this report).
- Re-run the same check I used throughout:
  `ansible-lint --offline roles shared`
- The `.ansible/` cache/lock directory that earlier lint runs left inside
  the repo has been deleted (it's lint-tool scratch state, not something
  that belongs in your working tree).

## Recommended next steps (not executed — your call)

1. Rename the 43 safe (`register`/`set_fact`) `var-naming` violations first;
   tackle the 184 `defaults/`-level ones in lockstep with whatever updates
   your external inventory repo needs, as its own dedicated, tested change.
2. Rename the 15 hyphenated role directories — I have the exact list of
   every file/line that references each one, ready to execute as a single
   reviewed change whenever you want it.
3. Decide whether to roll `meta/main.yml` + `argument_specs.yml` out to the
   other 45 roles, using `roles/firewalld` as the template.
4. Pin `requirements.yml` versions once you've confirmed what's actually
   running in production (`ansible-galaxy collection list` on a host that's
   successfully run this repo).
5. Regenerate `docs.md` (`python3 gen-var-docs.txt`) after any variable or
   role-directory renames, since it's auto-generated from exactly those names.
