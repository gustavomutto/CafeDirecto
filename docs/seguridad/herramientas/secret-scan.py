# Busca secretos en TODO el historial de Git (cada línea agregada en cada commit).
# Uso: python secret-scan.py <repo> <salida.txt>
# Muestra los valores tapados: solo los primeros 4 caracteres.
import re, subprocess, sys

repo, out = sys.argv[1], sys.argv[2]
RULES = [
    ('Clave privada', re.compile(r'-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----')),
    ('AWS access key', re.compile(r'AKIA[0-9A-Z]{16}')),
    ('GitHub token', re.compile(r'gh[pousr]_[A-Za-z0-9]{30,}')),
    ('Google API key', re.compile(r'AIza[0-9A-Za-z_\-]{35}')),
    ('Resend API key', re.compile(r're_[A-Za-z0-9]{20,}')),
    ('Slack token', re.compile(r'xox[abpr]-[A-Za-z0-9-]{10,}')),
    ('URL con contraseña', re.compile(r'[a-z]+://[^\s:/@]+:([^\s@/]{3,})@[^\s]+')),
    ('JWT', re.compile(r'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}')),
    ('Asignación de secreto', re.compile(r'(?i)(jwt_secret|media_secret|password|passwd|api_key|secret|token)\s*[=:]\s*["\']?([^\s"\'<>${}]{8,})')),
]
IGNORE_VALUES = re.compile(r'(?i)^(process\.env|req\.|body\.|true|false|null|none|string|required|example|tu_|your|xxx|\*\*\*|<)')

log = subprocess.run(
    ['git', '-C', repo, 'log', '--all', '-p', '--no-color', '--format=@@COMMIT %h %ad %an', '--date=short'],
    capture_output=True, text=True, encoding='utf-8', errors='replace').stdout

found, commit, file = [], '', ''
for line in log.splitlines():
    if line.startswith('@@COMMIT '):
        commit = line[9:]
        continue
    if line.startswith('+++ b/'):
        file = line[6:]
        continue
    if not line.startswith('+') or line.startswith('+++'):
        continue
    if re.search(r'\.(png|jpg|ico|lock|svg)$', file) or file.endswith('package-lock.json'):
        continue
    text = line[1:]
    for name, rx in RULES:
        m = rx.search(text)
        if not m:
            continue
        value = m.group(m.lastindex or 0)
        if name == 'Asignación de secreto' and IGNORE_VALUES.search(value):
            continue
        masked = value[:4] + '…' if len(value) > 4 else '…'
        found.append(f'{name} | {file} | commit {commit} | valor {masked}')

uniq = sorted(set(found))
with open(out, 'w', encoding='utf-8') as f:
    f.write(f'Commits revisados: {log.count("@@COMMIT ")}\nHallazgos: {len(uniq)}\n\n' + '\n'.join(uniq) + '\n')
print(f'Commits revisados: {log.count("@@COMMIT ")} · hallazgos: {len(uniq)}')
for x in uniq:
    print(x)
