# devsecops-wrappers

Automation scripts for Linux and Windows system hardening, security monitoring, network scanning, and lab work. Written and maintained by Victor Bishop, a systems and network specialist working in infrastructure security and vulnerability management.

Most of these scripts began as wrappers around standard tools (OpenSSH, Nmap, Check Point, Ansible) built to standardize recurring administration and security tasks and to make the results repeatable.

## Repository layout

- `linux/` Bash, Python, and Ansible for Debian-based systems and network security work.
- `windows/` PowerShell for Windows Server and Active Directory environments.

## Hardening

| Script | Description |
| --- | --- |
| [debian12_hardening.sh](linux/debian12_hardening.sh) | Menu-driven Debian 12 hardening suite with 14 selectable steps, from patching and firewall setup to USB storage blocking and IPv6 controls. |
| [debian-hardening-pro-menu.sh](linux/debian-hardening-pro-menu.sh) | Menu version of the pro hardening sequence. Each step can be applied on its own, or all steps can run in sequence. |
| [ssh_harden.sh](linux/ssh_harden.sh) | SSH hardening for Debian 12 based on the sshaudit.com guide. Regenerates host keys, filters weak Diffie-Hellman moduli, restricts key exchange, cipher, and MAC algorithms, and adds iptables rate limiting. |
| [ssh-auto-harden.sh](linux/ssh-auto-harden.sh) | SSH hardening automation applying the same sshaudit.com controls through a menu. |
| [ssh-key-generator.sh](linux/ssh-key-generator.sh) | Generates an RSA 4096 key pair with an optional passphrase and correct .ssh directory permissions. |

## Patching and automation

| Script | Description |
| --- | --- |
| [debian13_upgrade_ansible.yml](linux/debian13_upgrade_ansible.yml) | Ansible playbook that patches Debian 13 hosts in rolling batches of 30 percent and reboots only when a reboot is required. |
| [git-pull-all.sh](linux/git-pull-all.sh) | Runs git pull in every repository directory under the current path. |

## Monitoring and auditing

| Script | Description |
| --- | --- |
| [snmp_audit.sh](linux/snmp_audit.sh) | Audits the local SNMP configuration for legacy v1/v2c community strings, SNMPv3 users, and exposed listening interfaces. |
| [cert-expire-check.sh](linux/cert-expire-check.sh) | Checks TLS certificate expiry for a list of hosts and warns inside a configurable 30 day threshold. |
| [login-attempts.sh](linux/login-attempts.sh) | Summarizes failed SSH login attempts from auth.log. |
| [running-services.sh](linux/running-services.sh) | Color-coded list of systemd services by state. |
| [dns-info.sh](linux/dns-info.sh) | Prints the DNS servers configured on each interface. |

## Network scanning and discovery

| Script | Description |
| --- | --- |
| [nmap_ping_sweep.sh](linux/nmap_ping_sweep.sh) | Internal ping sweep with nmap, designed to run from cron with results kept for comparison. |
| [pingsweep.sh](linux/pingsweep.sh) | Lightweight subnet ping sweep. |
| [scan_multi_concurrent.sh](linux/scan_multi_concurrent.sh) | Concurrent multi-target scanning wrapper. |
| [nmap_stealth_scan_enhanced.sh](linux/nmap_stealth_scan_enhanced.sh) | Low-noise nmap wrapper with CIDR targets and proxychains support. |
| [nmap-diff-cron.sh](linux/nmap-diff-cron.sh) | Cron-driven nmap scan that stores XML output for day-over-day comparison. |
| [nmap-diff-mod.sh](linux/nmap-diff-mod.sh) | Nmap change detection with a custom port list, banner grabbing, logging, and email alerts. |

## Firewall and network administration

| Script | Description |
| --- | --- |
| [cp_get_nat_public_ips.py](linux/cp_get_nat_public_ips.py) | Extracts the unique public IP addresses from Check Point NAT rules through the mgmt_cli API, producing a NAT inventory for documentation and audits. |
| [rathole_docker_control_script.sh](linux/rathole_docker_control_script.sh) | Start and stop controller for Rathole tunnels running in Docker. |
| [16-byte-packet-v2.py](linux/16-byte-packet-v2.py) | Sends 16 byte test packets with Scapy for manual network testing. |

## Windows

| Script | Description |
| --- | --- |
| [SNTP Health Check Script for Windows Server](windows/SNTP%20Health%20Check%20Script%20for%20Windows%20Server.ps1) | Checks the Windows Time service, stratum level, configured peers, and last successful sync, then attempts a resync. |
| [SNTP Server Health Check for Client Side](windows/SNTP%20Server%20Health%20Check%20for%20Client%20Side.ps1) | AD-aware SNTP health check that scores NTP servers on offset and jitter, ranks them, and reconfigures the time service only when run on the PDC Emulator. |
| [windows-security-disable.ps1](windows/windows-security-disable.ps1) | Builds a deliberately weakened Windows target for isolated lab exercises. See the note below. |

## Red team and lab

For authorized penetration testing, bug bounty programs, and isolated lab environments only. Do not run these tools against systems you do not own or have written permission to test.

| Script | Description |
| --- | --- |
| [auto-bug-bounty.sh](linux/auto-bug-bounty.sh) | Recon pipeline chaining subfinder, amass, httpx, nmap, ffuf, waybackurls, and nuclei. |
| [generate_bug_bounty_report.sh](linux/generate_bug_bounty_report.sh) | Interactive generator that assembles a structured Markdown bug bounty report from prompts. |
| [havoc-aws-deploy.sh](linux/havoc-aws-deploy.sh) | Menu-driven deployment scaffold for a Havoc command and control server on AWS, with redirector options. |
| [sliver-red-team-infra.sh](linux/sliver-red-team-infra.sh) | Menu-driven Sliver infrastructure deployment, including a GoPhish server and a Caddy redirector. |
| [red-team-c2-deploy-safe.sh](linux/red-team-c2-deploy-safe.sh) | Sliver C2 deployment on AWS Lightsail using placeholder values for lab use. |
| [red-team-tools-install.sh](linux/red-team-tools-install.sh) | Installs a standard set of red team tools. |
| [red-team-tools-install-gui.sh](linux/red-team-tools-install-gui.sh) | GUI version of the red team tools installer. |
| [data-exfiltration.sh](linux/data-exfiltration.sh) | Short egress test used to validate outbound data controls in a lab. |
| [dirty_frag.sh](linux/dirty_frag.sh) | Applies the module blocklist mitigation for the Dirty Frag kernel vulnerability. |

## Usage notes

- Most Bash scripts must run as root and change system configuration. Test in a lab or against a snapshot before running one on a production host.
- Several scripts contain placeholders that must be set before use, including target subnets, the Check Point NAT layer name, and mail credentials.
- The Ansible playbook expects an inventory of Debian 13 hosts.

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
