/**
 * Firestore audit — departments & courses.
 * Uses firebase-tools' auth to get a fresh token, then queries via REST.
 */

import { createRequire } from 'module';
const require = createRequire(import.meta.url);

const FBT_ROOT = 'C:/Users/Kwame/AppData/Roaming/npm/node_modules/firebase-tools';

// ── 1. Get a fresh access token using firebase-tools internals ─────────────
let token;
try {
  // firebase-tools v15 auth module
  const { getAccessToken } = require(`${FBT_ROOT}/lib/auth.js`);
  const result = await getAccessToken(null, []);
  token = result?.access_token ?? result?.accessToken ?? result;
} catch (e1) {
  try {
    // Older path
    const api = require(`${FBT_ROOT}/lib/api.js`);
    token = await api.getAccessToken();
  } catch (e2) {
    // Last resort: use the refresh_token manually via Google's token endpoint
    const path = require('path');
    const Configstore = require(`${FBT_ROOT}/node_modules/configstore`);
    const store = new Configstore('firebase-tools');
    const refreshToken = store.get('tokens')?.refresh_token;
    if (!refreshToken) throw new Error('No refresh_token in configstore');

    const body = new URLSearchParams({
      client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
      client_secret: 'j9iVZfS8sMqLXIe0T5EM_xXH',
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    });
    const res = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      body,
    });
    const json = await res.json();
    if (!json.access_token) throw new Error(`Token refresh failed: ${JSON.stringify(json)}`);
    token = json.access_token;
  }
}

if (!token) {
  console.error('❌  Could not obtain access token. Try: firebase login');
  process.exit(1);
}
console.log('🔑  Token obtained.\n');

// ── 2. Firestore REST helpers ──────────────────────────────────────────────
const PROJECT = 'project-sams-f0086';
const BASE    = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

async function fetchAll(collection) {
  const docs = [];
  let pageToken = null;
  do {
    const url = new URL(`${BASE}/${collection}`);
    url.searchParams.set('pageSize', '300');
    if (pageToken) url.searchParams.set('pageToken', pageToken);

    const res = await fetch(url.toString(), {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new Error(`[${collection}] HTTP ${res.status}: ${await res.text()}`);
    const json = await res.json();
    if (json.documents) docs.push(...json.documents);
    pageToken = json.nextPageToken ?? null;
  } while (pageToken);
  return docs;
}

const field = (doc, key) => {
  const f = doc.fields?.[key];
  if (!f) return undefined;
  return f.stringValue ?? f.integerValue ?? f.booleanValue ?? null;
};
const docId = (doc) => doc.name.split('/').pop();

// ── 3. Fetch ───────────────────────────────────────────────────────────────
console.log('══════════════════════════════════════════');
console.log('  Firestore Audit — project-sams-f0086');
console.log('══════════════════════════════════════════\n');

let deptDocs, courseDocs;
try {
  [deptDocs, courseDocs] = await Promise.all([
    fetchAll('departments'),
    fetchAll('courses'),
  ]);
} catch (err) {
  console.error('❌  Fetch failed:', err.message);
  process.exit(1);
}

// ── 4. Validate departments ────────────────────────────────────────────────
console.log(`📂  DEPARTMENTS  (${deptDocs.length} total)\n`);

const deptIssues = [];
const deptMap   = new Map();   // id → name
const nameCount = new Map();   // name → [ids]

for (const doc of deptDocs) {
  const id   = docId(doc);
  const name = field(doc, 'name');
  const issues = [];

  if (!name || String(name).trim() === '') issues.push('MISSING name field');

  deptMap.set(id, String(name ?? ''));

  const key = String(name ?? '').trim().toLowerCase();
  if (!nameCount.has(key)) nameCount.set(key, []);
  nameCount.get(key).push(id);

  if (issues.length) deptIssues.push({ id, name: name ?? '(missing)', issues });

  const badge = issues.length ? '⚠️ ' : '✅';
  console.log(`  ${badge} [${id}]  "${name ?? '(missing)'}"`);
  if (issues.length) console.log(`         ← ${issues.join(', ')}`);
}

const dupNames = [...nameCount.entries()].filter(([, ids]) => ids.length > 1);
if (dupNames.length) {
  console.log('\n  ⚠️  DUPLICATE department names:');
  for (const [name, ids] of dupNames) {
    console.log(`     "${name}" appears ${ids.length}× — IDs: ${ids.join(', ')}`);
    console.log('     → Delete the extra doc(s) via Firebase Console > Firestore');
  }
}
console.log();

// ── 5. Validate courses ────────────────────────────────────────────────────
console.log(`📚  COURSES  (${courseDocs.length} total)\n`);

const courseIssues = [];

for (const doc of courseDocs) {
  const id      = docId(doc);
  const name    = field(doc, 'name');
  const deptId  = field(doc, 'departmentId');
  const allowed = (doc.fields?.allowedDepartmentIds?.arrayValue?.values ?? [])
                    .map(v => v.stringValue).filter(Boolean);
  const issues  = [];

  if (!name || String(name).trim() === '') issues.push('MISSING name');
  if (!deptId && allowed.length === 0)     issues.push('NO department reference');

  if (deptId && !deptMap.has(String(deptId))) {
    issues.push(`departmentId "${deptId}" → NOT FOUND in departments`);
  }
  const orphanAllowed = allowed.filter(aid => !deptMap.has(aid));
  if (orphanAllowed.length) {
    issues.push(`allowedDepartmentIds has orphan IDs: [${orphanAllowed.join(', ')}]`);
  }

  if (issues.length) courseIssues.push({ id, name: String(name ?? ''), issues });

  const badge      = issues.length ? '⚠️ ' : '✅';
  const primary    = deptId ? `dept="${deptMap.get(String(deptId)) ?? deptId}"` : '(no primary dept)';
  const allowedStr = allowed.length
    ? `  allowed=[${allowed.map(a => deptMap.get(a) ?? a).join(', ')}]`
    : '';
  console.log(`  ${badge} [${id}]  "${name ?? '(missing)'}"`);
  console.log(`         ${primary}${allowedStr}`);
  if (issues.length) console.log(`         ← ${issues.join(' | ')}`);
}
console.log();

// ── 6. Department-filter simulation ───────────────────────────────────────
console.log('🔍  FILTER CHECK — courses per department\n');

for (const [deptId, deptName] of [...deptMap.entries()].sort((a,b) => a[1].localeCompare(b[1]))) {
  const hits = courseDocs.filter(doc => {
    const primary  = field(doc, 'departmentId');
    const allowed  = (doc.fields?.allowedDepartmentIds?.arrayValue?.values ?? [])
                       .map(v => v.stringValue).filter(Boolean);
    return String(primary) === deptId || allowed.includes(deptId);
  });
  const label = hits.length === 0 ? '(none)' : hits.map(c => `"${field(c,'name')}"`).join(', ');
  console.log(`  "${deptName}"\n    → ${hits.length} course(s): ${label}\n`);
}

// ── 7. Summary ─────────────────────────────────────────────────────────────
console.log('══════════════════════════════════════════');
console.log('  SUMMARY');
console.log('══════════════════════════════════════════');
console.log(`  Departments : ${deptDocs.length}  issues: ${deptIssues.length}  duplicates: ${dupNames.length}`);
console.log(`  Courses     : ${courseDocs.length}  issues: ${courseIssues.length}`);

if (!deptIssues.length && !dupNames.length && !courseIssues.length) {
  console.log('\n  ✅  All records are consistent — no discrepancies found.\n');
} else {
  console.log('\n  ❌  ACTION REQUIRED:');
  if (dupNames.length) {
    for (const [name, ids] of dupNames)
      console.log(`  • Delete duplicate "${name}" dept — keep one, delete IDs: ${ids.slice(1).join(', ')}`);
  }
  if (deptIssues.length) {
    for (const d of deptIssues)
      console.log(`  • Fix dept [${d.id}]: ${d.issues.join(', ')}`);
  }
  if (courseIssues.length) {
    for (const c of courseIssues)
      console.log(`  • Fix course [${c.id}] "${c.name}": ${c.issues.join(' | ')}`);
  }
  console.log();
}
