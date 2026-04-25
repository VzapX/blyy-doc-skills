# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x   | ✅ Security fixes |
| < 1.0   | ❌ Not supported |

## Reporting a Vulnerability

If you discover a security issue in this skill (e.g., a flaw that would cause the skill to leak secrets, execute arbitrary code on behalf of a user, or corrupt user documents), please:

1. **Do NOT open a public issue**
2. Report via GitHub Security Advisory (preferred) or email the maintainer
3. Include: affected files, reproduction steps, potential impact

## Scope

**In scope**:
- Skill instructions that could cause AI to leak user secrets into generated docs
- Shell command injection in install scripts or skill-generated scripts
- Path traversal in file operations

**Out of scope**:
- Issues in user-side AI tools (Claude Code, Gemini, etc.)
- Issues in user projects that happen to use this skill
- Feature requests or general bugs (use regular Issues)

## Maintenance Mode Notice

This project is in maintenance mode. Security fixes will be prioritized, but non-critical issues may take longer to address.
