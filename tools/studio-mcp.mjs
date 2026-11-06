#!/usr/bin/env node
// Minimal stdio client for Roblox Studio's official MCP server.
// Usage:
//   node tools/studio-mcp.mjs studios
//   node tools/studio-mcp.mjs tools
//   node tools/studio-mcp.mjs call <toolName> [jsonArgs] [--out file]
// The studio_id is auto-filled from the first connected Studio when omitted.
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const LOCALAPPDATA = process.env.LOCALAPPDATA || '';
const launcher = `${LOCALAPPDATA}\\Roblox\\mcp.bat`;
if (!fs.existsSync(launcher)) {
  console.error(`Studio MCP launcher not found: ${launcher}`);
  process.exit(2);
}

const child = spawn('cmd.exe', ['/c', launcher], { stdio: ['pipe', 'pipe', 'pipe'] });
let buffer = '';
let nextId = 1;
const pending = new Map();
let stderr = '';

child.stderr.on('data', d => { stderr += d.toString(); });
child.stdout.on('data', d => {
  buffer += d.toString();
  let idx;
  while ((idx = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch { continue; }
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  }
});

function send(msg) { child.stdin.write(JSON.stringify(msg) + '\n'); }
function request(method, params = {}, timeoutMs = 120000) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`MCP timeout: ${method}`)), timeoutMs);
    pending.set(id, msg => { clearTimeout(timer); resolve(msg); });
    send({ jsonrpc: '2.0', id, method, params });
  });
}
function textOf(result) {
  if (!result) return '';
  if (Array.isArray(result.content)) {
    return result.content.map(c => c.type === 'text' ? c.text : `[${c.type}]`).join('\n');
  }
  return JSON.stringify(result, null, 2);
}
function imageOf(result) {
  if (!result || !Array.isArray(result.content)) return null;
  for (const c of result.content) {
    if (c.type === 'image' && c.data) return { data: c.data, mimeType: c.mimeType || 'image/png' };
  }
  return null;
}
function writeResult(res, outFile) {
  const image = imageOf(res.result);
  if (image) {
    const ext = image.mimeType.includes('jpeg') ? '.jpg' : '.png';
    const target = outFile && !/\.[a-z0-9]+$/i.test(outFile) ? outFile + ext : (outFile || null);
    if (target) {
      fs.writeFileSync(target, Buffer.from(image.data, 'base64'));
      console.log(`wrote image ${target} (${image.mimeType}, ${image.data.length} base64 chars)`);
      return true;
    }
  }
  return false;
}
function parseToolText(result) {
  const text = textOf(result);
  try { return JSON.parse(text); } catch { return text; }
}
const sleep = ms => new Promise(r => setTimeout(r, ms));
async function waitForStudios(timeoutMs = 30000) {
  const deadline = Date.now() + timeoutMs;
  let last = null;
  while (Date.now() < deadline) {
    const res = await request('tools/call', { name: 'list_roblox_studios', arguments: {} });
    const data = parseToolText(res.result);
    const studios = data?.studios || data?.instances || (Array.isArray(data) ? data : []);
    if (studios.length) return studios;
    last = data;
    await sleep(2000);
  }
  return last?.studios || last?.instances || [];
}

try {
  await request('initialize', {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'last-stop-agent', version: '1.0.0' },
  });
  send({ jsonrpc: '2.0', method: 'notifications/initialized', params: {} });

  const [cmd, ...rest] = process.argv.slice(2);
  if (!cmd || cmd === 'tools') {
    const res = await request('tools/list', {});
    const tools = res.result?.tools || [];
    for (const t of tools) console.log(`${t.name}\t${t.title || ''}\t${(t.description || '').split('\n')[0].slice(0, 140)}`);
  } else if (cmd === 'schema') {
    const res = await request('tools/list', {});
    const tool = (res.result?.tools || []).find(t => t.name === rest[0]);
    console.log(JSON.stringify(tool || null, null, 2));
  } else if (cmd === 'studios') {
    const studios = await waitForStudios();
    console.log(JSON.stringify({ studios }, null, 2));
  } else if (cmd === 'luau') {
    const file = rest[0];
    const datamodel = rest[1] || 'Edit';
    const outIdx = rest.indexOf('--out');
    const outFile = outIdx >= 0 ? rest[outIdx + 1] : null;
    if (!file) throw new Error('Missing Luau file');
    const studios = await waitForStudios();
    if (!studios.length) throw new Error('No connected Studio instance');
    const res = await request('tools/call', {
      name: 'execute_luau',
      arguments: { code: fs.readFileSync(file, 'utf8'), datamodel_type: datamodel, studio_id: studios[0].id },
    }, 300000);
    if (res.error) throw new Error(JSON.stringify(res.error));
    const text = textOf(res.result);
    if (outFile) {
      if (!writeResult(res, outFile)) {
        fs.writeFileSync(outFile, text);
        console.log(`wrote ${outFile} (${text.length} chars)`);
      }
    } else console.log(text);
  } else if (cmd === 'call') {
    const name = rest[0];
    if (!name) throw new Error('Missing tool name');
    let args = {};
    let outFile = null;
    for (let i = 1; i < rest.length; i++) {
      if (rest[i] === '--out') { outFile = rest[++i]; continue; }
      if (!args || Object.keys(args).length === 0) {
        try { args = JSON.parse(rest[i]); } catch { throw new Error(`Invalid JSON args: ${rest[i]}`); }
      }
    }
    const needsStudio = name !== 'list_roblox_studios' && args.studio_id === undefined;
    if (needsStudio) {
      const studios = await waitForStudios();
      if (!studios.length) throw new Error('No connected Studio instance');
      args.studio_id = studios[0].id;
      console.error(`studio_id=${args.studio_id} (${studios[0].name || ''})`);
    }
    const res = await request('tools/call', { name, arguments: args });
    if (res.error) throw new Error(JSON.stringify(res.error));
    const text = textOf(res.result);
    if (outFile) {
      if (!writeResult(res, outFile)) {
        fs.writeFileSync(outFile, text);
        console.log(`wrote ${outFile} (${text.length} chars)`);
      }
    } else {
      console.log(text);
    }
  } else {
    throw new Error(`Unknown command: ${cmd}`);
  }
} catch (e) {
  console.error(`ERROR: ${e.message}`);
  if (stderr) console.error(stderr.slice(0, 2000));
  process.exitCode = 1;
} finally {
  child.kill();
  setTimeout(() => process.exit(process.exitCode || 0), 300);
}
