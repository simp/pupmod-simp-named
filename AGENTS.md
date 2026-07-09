# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-named` is a SIMP Puppet module that manages **BIND (`named`)** on
Enterprise Linux systems in one of two mutually-exclusive modes:

- **Authoritative / general `named`** — `include 'named'` installs BIND and
  pulls its entire configuration (zone files, `named.conf`, etc.) from an
  **rsync** server, either inside a **chroot jail** or not. The chroot decision
  is auto-detected from SELinux state (chroot is disabled when SELinux is
  enforcing, because named chroot jails are incompatible with enforcing
  SELinux). Optionally opens the DNS firewall port (53 tcp/udp) via
  `simp/iptables`.
- **Caching nameserver** — `include 'named::caching'` stands up a
  forwarding/caching resolver with a module-provided `named.conf` template and
  bundled zone/hint files, plus `named::caching::forwarders` (a define) to add
  forwarder entries and `named::caching::hints` to control the root-hints
  (`named.ca`) file.

The two entry classes are **mutually exclusive**: each `fail()`s if the other is
already declared (`manifests/init.pp:81-83`, `manifests/caching.pp:23-25`).

The heavy lifting (fetching config) is delegated to `simp/rsync`. This module
does **not** template `named.conf` in the authoritative path — it rsyncs it —
so most of the real DNS content lives on the rsync server, not in this module.

### Business logic

Public API (consumers declare these):

- **`named` (`manifests/init.pp:69-127`)** — Public entry class for the
  authoritative/general server (not `assert_private()`'d). Parameters
  (`init.pp:69-80`):
  - `$chroot_path` (`Stdlib::Absolutepath`, **no default**) — required; supplied
    from module data (`data/common.yaml` → `/var/named/chroot`).
  - `$chroot` (`Boolean`) — auto-detected:
    `!pick($facts['os']['selinux']['enforced'], false)` (`init.pp:71`), i.e.
    chroot **off** when SELinux is enforcing, on otherwise.
  - `$bind_dns_rsync` (`String`, default `'default'`) — the rsync target under
    `${rsync_base}/bind_dns`.
  - `$firewall`, `$rsync_server`, `$rsync_timeout` — from the `simp_options`
    seam (see table below) (`init.pp:73-78`).
  - `$sebool_named_write_master_zones` (`Boolean`, default `false`).
  It runs `simplib::assert_metadata($module_name)` (`init.pp:85`) and
  `simplib::validate_net_list($rsync_server)` (`init.pp:87`), then branches on
  `$chroot`: chroot path includes `named::chroot` + `service` + `install`;
  non-chroot path includes `named::non_chroot` + `service`/`install` with
  `chroot => false` (`init.pp:89-104`). Sets the `named_write_master_zones`
  SELinux boolean only when SELinux is enforcing (`init.pp:108-114`), and adds
  `iptables::listen::tcp_stateful`/`udp` for port 53 (trusted_nets `['ALL']`)
  when `$firewall` (`init.pp:116-126`).
- **`named::caching` (`manifests/caching.pp:19-164`)** — Public entry class for
  the caching resolver (not `assert_private()`'d). Required param `$chroot_path`
  (`Stdlib::Absolutepath`, from `data/common.yaml` via the
  `named::caching::chroot_path` alias). Computes an effective chroot path that
  is blanked out when SELinux is enforcing (`caching.pp:31-35`), declares
  `named::install`/`named::service`, and builds `/etc/named_caching.forwarders`
  via `concat`/`concat_fragment` plus a set of bundled zone/hint files from
  `files/chroot/...` and a templated `named.conf`
  (`templates/named.caching.conf.erb`) (`caching.pp:62-161`).
- **`named::caching::forwarders` (`manifests/caching/forwarders.pp:14-26`)** —
  Public **define**. `include`s `named::caching` and adds a
  `concat_fragment` forwarder entry. `$name` may be a whitespace-delimited list
  of forwarder IPs; `127.0.0.1`/`::1` are stripped out
  (`caching/forwarders.pp:18-25`).
- **`named::caching::hints` (`manifests/caching/hints.pp:13-28`)** — Public
  class. `include`s `named::caching` and writes
  `/var/named/chroot/var/named/named.ca` from `templates/named.ca.erb`. Params
  `$content` (verbatim hint content) and `$use_defaults`.

Private (helper) classes — all call `assert_private()`:

- **`named::install` (`manifests/install.pp:15-54`)** — installs `bind`,
  `bind-libs`, and (conditionally) `bind-chroot`; creates `/var/named`, the
  `named` group (gid 25) and `named` user (uid 25). `$ensure` from the
  `simp_options::package_ensure` seam (`install.pp:18`).
- **`named::service` (`manifests/service.pp:27-70`)** — manages the BIND
  service. Service name is selected from `$chroot`:
  `$chroot_service_name` (`named-chroot`) vs `$non_chroot_service_name`
  (`named`) (`service.pp:36-39`), both from `data/common.yaml`. When
  `$use_systemd` (module data → `true`), it drops a full replacement
  `named-chroot.service` unit (`templates/named-chroot.service.erb`) and runs a
  `systemctl daemon-reload` exec — a workaround for RH bug 1278082
  (`service.pp:41-61`).
- **`named::chroot` (`manifests/chroot.pp:25-97`)** — builds the chroot
  directory tree and rsyncs config into it; symlinks `/etc/named.conf` into the
  jail (`chroot.pp:82-84`).
- **`named::non_chroot` (`manifests/non_chroot.pp:23-68`)** — the non-chroot
  variant: manages `/etc/named.conf` and rsyncs `var/named` and `etc/*` into
  place.

### Gotchas / non-obvious details

- **`named` and `named::caching` are mutually exclusive.** Declaring both
  triggers `fail('You cannot include both ::named and ::named::caching')`
  (`init.pp:81-83`, `caching.pp:23-25`). Pick one entry class.
- **Chroot is driven by SELinux, and enforcing SELinux wins.** In `named`,
  `$chroot` defaults to *off* when SELinux is enforcing (`init.pp:71`); in
  `named::caching` the effective chroot path is blanked when SELinux is
  enforcing regardless of `$chroot_path` (`caching.pp:31-35`). named chroot
  jails are incompatible with enforcing SELinux — forcing `$chroot => true` on
  such a host can make named non-functional (`init.pp:43-48`).
- **`named::caching` calls `str2bool` on the SELinux fact**
  (`caching.pp:31`) whereas `named` uses `pick(...)` directly (`init.pp:71`);
  `$facts['os']['selinux']['enforced']` is already a Boolean. This inconsistency
  is pre-existing — don't "fix" one path in isolation without checking both.
- **Configuration is rsynced, not templated (authoritative path).**
  `named::chroot` / `named::non_chroot` pull `named.conf` and zone data from an
  rsync server (`chroot.pp:86-96`, `non_chroot.pp:49-67`); the rsync password is
  derived via `simplib::passgen($_rsync_user)` (`chroot.pp:88`). If rsync isn't
  serving the expected space, named gets no config. The rsync user/source names
  embed environment + OS name + major release (`chroot.pp:39`,
  `non_chroot.pp:36`).
- **The systemd unit is fully replaced, not overridden**, for chroot service on
  systemd hosts — a workaround for RH bug 1278082 (`service.pp:41-53`); it
  changes the Requires/After lists and the service Type from forking to simple.
- **uid/gid 25 for the `named` user/group are hard-coded** and
  `allowdupe => false` (`install.pp:39-53`) — collisions with an existing
  uid/gid 25 will fail the run.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` appears only as a fixture
  (`.fixtures.yml:11`).
- **No custom types/facts/functions ship here.** There is no `types/` or `lib/`
  directory; every custom type (`iptables::listen::*`, `rsync`, `concat`,
  `concat_fragment`, `file_line`, `selboolean`) and function
  (`simplib::lookup`, `simplib::passgen`, `simplib::validate_net_list`,
  `simplib::assert_metadata`, `pick`, `str2bool`) comes from a dependency.

## The `simp_options` / `simplib::lookup` seam

This is the module's SIMP feature-toggle seam. All calls are
`simplib::lookup('simp_options::...', { 'default_value' => ... })`:

| Line | Key | `default_value` |
|------|-----|-----------------|
| `manifests/init.pp:73` | `simp_options::firewall` | `false` |
| `manifests/init.pp:74` | `simp_options::rsync::server` | `'127.0.0.1'` |
| `manifests/init.pp:78` | `simp_options::rsync::timeout` | `'2'` |
| `manifests/install.pp:18` | `simp_options::package_ensure` | `'installed'` |

Keep routing SIMP feature toggles through `simplib::lookup('simp_options::*', {
'default_value' => ... })` with an explicit default rather than assuming
`simp_options` is included.

## Dependencies

Module dependencies (from `metadata.json`):

- `simp/iptables` `>= 6.5.3 < 8.0.0` — provides `iptables::listen::tcp_stateful`
  / `iptables::listen::udp` (the firewall rules opened when `$firewall`).
- `simp/rsync` `>= 6.1.1 < 8.0.0` — provides the `rsync` type used to pull
  named's configuration.
- `simp/simplib` `>= 4.9.0 < 5.0.0` — provides `simplib::lookup`,
  `simplib::passgen`, `simplib::validate_net_list`, `simplib::assert_metadata`.
- `puppetlabs/concat` `>= 6.4.0 < 10.0.0` — provides `concat` /
  `concat_fragment` (caching forwarders file).
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` — provides `pick`, `str2bool`.

There are **no** `simp.optional_dependencies` declared in `metadata.json`.

Fixture-only dependencies (from `.fixtures.yml`, present for test compilation,
not runtime deps): `augeas_core`, `firewalld`, `selinux_core`,
`simp_firewalld`, `simp_options` (plus the runtime deps above are also checked
out as fixtures).

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. (SIMP is migrating Puppet → OpenVox; when
`metadata.json` switches this to `openvox`, update this line to match.)

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9.

## Repository layout

- `manifests/init.pp` — the `named` public entry class (authoritative server).
- `manifests/caching.pp` — the `named::caching` public entry class (resolver).
- `manifests/caching/forwarders.pp` — `named::caching::forwarders` define.
- `manifests/caching/hints.pp` — `named::caching::hints` class.
- `manifests/install.pp`, `manifests/service.pp`, `manifests/chroot.pp`,
  `manifests/non_chroot.pp` — private helper classes (`assert_private()`).
- `data/common.yaml` — module data: `chroot_path`, service names, `use_systemd`.
- `hiera.yaml` — module data hierarchy (v5): OS name+major → OS name → kernel →
  common.
- `templates/named.caching.conf.erb`, `templates/named.ca.erb`,
  `templates/named-chroot.service.erb` — ERB templates (caching config, root
  hints, systemd unit).
- `files/chroot/...` — static zone/hint files served via
  `puppet:///modules/named/...` by `named::caching`.
- `metadata.json` — deps, OS matrix, Puppet requirement.
- `spec/classes/init_spec.rb`, `spec/classes/caching_spec.rb`,
  `spec/classes/caching/hints_spec.rb` — rspec-puppet unit tests.
- `spec/acceptance/suites/default/00_caching_spec.rb`,
  `10_named_chroot_spec.rb` — beaker acceptance suites; nodesets under
  `spec/acceptance/nodesets/` (`default.yml` el7/el8, `oel.yml`).
- `REFERENCE.md` — generated Puppet Strings reference.
- No `types/` or `lib/` — this module ships no custom Puppet data types or Ruby
  types/providers/functions/facts. Every custom type and function it uses comes
  from the dependencies above.
- **Acceptance is NOT wired into CI.** `.github/workflows/pr_tests.yml` runs
  only puppet-syntax, puppet-style, ruby-style, file-checks, RELENG checks, and
  the `spec-tests` job (Puppet 7.x and 8.x). There is no `acceptance` job — the
  beaker suites under `spec/acceptance/` are run manually with
  `bundle exec rake beaker:suites`.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single class spec
bundle exec rspec spec/classes/init_spec.rb

# Puppet lint
bundle exec rake lint

# Puppet + metadata syntax (as CI runs)
bundle exec rake syntax
bundle exec rake metadata_lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite (NOT run in CI — manual only)
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to `~> 1.88.0`. The tested
Puppet range is `>= 7 < 9`. `spec/spec_helper.rb` requires
`puppetlabs_spec_helper/module_spec_helper` (with `simp/rspec-puppet-facts`),
not `voxpupuli/test/spec_helper`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the classes
  and define — they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after
  changing docs or parameters.
- Keep `assert_private()` on the helper classes (`install`, `service`,
  `chroot`, `non_chroot`); only `named`, `named::caching`,
  `named::caching::forwarders`, and `named::caching::hints` are public.
- Keep data-driven values (`chroot_path`, service names, `use_systemd`) in
  `data/*.yaml`, not hard-coded in manifests.
- Continue routing SIMP feature toggles through
  `simplib::lookup('simp_options::*', { 'default_value' => ... })` rather than
  assuming `simp_options` is included.
- `Gemfile`, `spec/spec_helper.rb`, `.gitignore`, `.pdkignore`, and
  `.github/workflows/pr_tests.yml` carry a **puppetsync** notice — they are
  baseline-managed and the next sync overwrites local edits. Push changes to
  those files upstream to the baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in the manifests.
