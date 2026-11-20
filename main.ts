import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const root = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR || '/output';
const includeVisible = (source: string): boolean => !basename(source).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(root, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(root, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(root, 'src'), join(out, 'src'), {
  recursive: true,
  filter: includeVisible,
});

const screenshotsSource = join(root, 'screenshots');
const screenshotsOutput = join(out, 'screenshots');
mkdirSync(screenshotsOutput, { recursive: true });
if (existsSync(screenshotsSource)) {
  cpSync(screenshotsSource, screenshotsOutput, {
    recursive: true,
    filter: includeVisible,
  });
}

const dossier = await buildDossier(out, {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
});
writeFileSync(join(out, 'dossier.json'), JSON.stringify(dossier, null, 2));
