import fs from 'node:fs'
import path from 'node:path'

const [nodeModulesRoot, outputRoot, ...additionalPackageRoots] = process.argv.slice(2)
if (!nodeModulesRoot || !outputRoot) {
  throw new Error('Usage: generate_notices.js NODE_MODULES OUTPUT')
}

const packages = []

function visit(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (!entry.isDirectory() || entry.name === '.bin') continue
    const child = path.join(directory, entry.name)
    if (entry.name.startsWith('@')) {
      visit(child)
      continue
    }
    collectPackage(child, entry.name)
  }
}

function collectPackage(child, fallbackName) {
  const manifestPath = path.join(child, 'package.json')
  if (!fs.existsSync(manifestPath)) return
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'))
  const name = String(manifest.name ?? fallbackName)
  const version = String(manifest.version ?? '')
  const license = typeof manifest.license === 'string' ? manifest.license : 'SEE PACKAGE'
  const homepage = typeof manifest.homepage === 'string'
    ? manifest.homepage
    : typeof manifest.repository?.url === 'string'
      ? manifest.repository.url
      : ''
  const destination = path.join(outputRoot, name.replaceAll('/', '__'))
  fs.mkdirSync(destination, { recursive: true })
  const licenseFiles = fs.readdirSync(child).filter((filename) =>
    /^(?:licen[cs]e|copying|notice)(?:\..*)?$/i.test(filename),
  )
  for (const filename of licenseFiles) {
    fs.copyFileSync(path.join(child, filename), path.join(destination, filename))
  }
  fs.writeFileSync(
    path.join(destination, 'PACKAGE'),
    `${name}\n${version}\n${license}\n${homepage}\n`,
  )
  packages.push({ name, version, license, homepage })
  const nested = path.join(child, 'node_modules')
  if (fs.existsSync(nested)) visit(nested)
}

fs.mkdirSync(outputRoot, { recursive: true })
visit(nodeModulesRoot)
for (const packageRoot of additionalPackageRoots) {
  collectPackage(packageRoot, path.basename(packageRoot))
}
packages.sort((left, right) => left.name.localeCompare(right.name) || left.version.localeCompare(right.version))
fs.writeFileSync(
  path.join(outputRoot, 'THIRD_PARTY_NOTICES.md'),
  [
    '# BusyMark visualization JavaScript notices',
    '',
    'The following packages are included in the offline visualization bundle.',
    'Their package metadata and distributed license files are preserved in sibling directories.',
    '',
    '| Package | Version | Declared license | Upstream |',
    '| --- | --- | --- | --- |',
    ...packages.map(({ name, version, license, homepage }) =>
      `| ${name.replaceAll('|', '\\|')} | ${version} | ${license.replaceAll('|', '\\|')} | ${homepage.replaceAll('|', '\\|')} |`,
    ),
    '',
  ].join('\n'),
)
