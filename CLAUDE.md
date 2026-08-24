# EDE — Claude Instructions

## Product
EDE — Español de España is a Spanish-from-Spain learning app for Thai speakers.

## Current Product Direction

EDE is PWA-first.

Priority:
1. Finish the PWA end-to-end.
2. Complete real curriculum/content.
3. Implement Auth / Trial / Membership / Progress / Review.
4. Make the PWA production-ready.
5. Adapt the same Flutter codebase to iOS and Android later.

Native iOS/Android code must remain intact, but native delivery is not the current priority.

## Language Rules
- Productive Spanish default: Spain Spanish (`es-ES`)
- Teach `vosotros/vosotras`, `os`, `vuestro/a`
- Do not default to voseo or Latin American production forms
- Apply `SPAIN_SPANISH_LANGUAGE_GUARD`
- Pronunciation target: distinción + yeísmo

## Development Rules
- Do not mix this repository with Japan Hayai or any other product.
- Do not use or modify unrelated Supabase projects.
- Prefer one complete vertical slice before scaling content.
- Do not fabricate lesson content, AI scores, pronunciation scores, or completion evidence.
- Preserve existing native iOS/Android code while prioritizing PWA work.
