import { spawn } from 'node:child_process';
import { realpath } from 'node:fs/promises';
import { isAbsolute, join, relative, sep } from 'node:path';

export const name = 'workbench-native-config';

// The provider materializes this document; browsers cannot supply arbitrary file paths.
export function createOpener(run = spawn) {
  return async (file, signal) => {
    signal?.throwIfAborted();
    const home = await realpath(process.env.DSH_HOME);
    const target = await realpath(file);
    const inside = relative(home, target);
    if (isAbsolute(inside) || inside === '..' || inside.startsWith('..' + sep)) throw new Error('Settings document is outside DSH_HOME.');
    const editor = join(process.env.SystemRoot || 'C:\\Windows', 'System32', 'notepad.exe');
    await new Promise((resolve, reject) => {
      // One argv item preserves Chinese, spaces and apostrophes; no shell or file associations.
      const child = run(editor, [target], { shell: false, windowsHide: false, stdio: 'ignore' });
      child.once('error', reject);
      child.once('spawn', () => { child.unref(); resolve(); });
    });
  };
}

export function apply(ctx) {
  ctx.inject(['settingsController'], (host) => {
    const controller = host.settingsController;
    const previous = controller.openTextFile;
    const opener = createOpener();
    controller.openTextFile = opener;
    host.on('dispose', () => { if (controller.openTextFile === opener) controller.openTextFile = previous; });
  });
}
