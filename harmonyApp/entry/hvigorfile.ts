import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import fs from 'node:fs';
import path from 'node:path';
import { execSync } from 'node:child_process';

const SHARED_LOGIN_NATIVE_LIB = 'libkn.so';
const ABI = 'arm64-v8a';
const SHARED_LOGIN_NATIVE_CANDIDATES = [
  path.resolve(process.cwd(), 'entry/libs', ABI, SHARED_LOGIN_NATIVE_LIB),
  path.resolve(process.cwd(), 'entry/src/main/libs', ABI, SHARED_LOGIN_NATIVE_LIB)
];
const BRIDGE_DIR = path.resolve(process.cwd(), '../harmony-kmp-bridge');
const BRIDGE_SOURCE_DIR = path.resolve(BRIDGE_DIR, 'src/ohosArm64Main/kotlin');
const BUILD_COMMANDS_REQUIRING_SHARED_LOGIN = [
  'assembleApp',
  'assembleHap',
  'PackageApp',
  'PackageHap',
  'BuildJS',
  'CompileArkTS'
];

function shouldRequireSharedLoginNative(): boolean {
  return process.argv.some((arg: string) => BUILD_COMMANDS_REQUIRING_SHARED_LOGIN.includes(arg));
}

function findExistingLib(): string | undefined {
  return SHARED_LOGIN_NATIVE_CANDIDATES.find((candidate: string) => fs.existsSync(candidate));
}

function isKotlinSourceNewer(existingLib: string): boolean {
  const libStat = fs.statSync(existingLib);
  const libMtime = libStat.mtimeMs;

  function walkDir(dir: string): number {
    let latest = 0;
    try {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          latest = Math.max(latest, walkDir(fullPath));
        } else if (entry.name.endsWith('.kt')) {
          const stat = fs.statSync(fullPath);
          latest = Math.max(latest, stat.mtimeMs);
        }
      }
    } catch {
      // ignore permission errors on unreadable directories
    }
    return latest;
  }

  const sourceLatestMtime = walkDir(BRIDGE_SOURCE_DIR);
  return sourceLatestMtime > libMtime;
}

function buildSharedLoginNative(): void {
  const existingLib = findExistingLib();

  if (existingLib !== undefined && fs.existsSync(BRIDGE_SOURCE_DIR)) {
    if (!isKotlinSourceNewer(existingLib)) {
      return; // library is up-to-date
    }
    process.stdout.write(
      '[build-bridge] Kotlin source changed, rebuilding native bridge...\n'
    );
  } else if (existingLib !== undefined) {
    return; // library exists and we can't check source — assume up-to-date
  } else {
    process.stdout.write('[build-bridge] libkn.so not found, building native bridge...\n');
  }

  if (!fs.existsSync(BRIDGE_DIR)) {
    throw new Error(
      `harmony-kmp-bridge directory not found at ${BRIDGE_DIR}. ` +
      'Cannot auto-build the native bridge library.'
    );
  }

  try {
    execSync('./gradlew ohosArm64Binaries', {
      cwd: BRIDGE_DIR,
      stdio: 'inherit',
      timeout: 300000
    });
  } catch (error) {
    throw new Error(
      'Native bridge build failed.\n' +
      'Try manually: cd harmony-kmp-bridge && ./gradlew ohosArm64Binaries\n' +
      String(error)
    );
  }

  if (!findExistingLib()) {
    throw new Error(
      `Build completed but ${SHARED_LOGIN_NATIVE_LIB} still not found. ` +
      `Expected one of:\n${SHARED_LOGIN_NATIVE_CANDIDATES.join('\n')}`
    );
  }

  process.stdout.write('[build-bridge] libkn.so built and deployed successfully\n');
}

if (shouldRequireSharedLoginNative()) {
  buildSharedLoginNative();
}

export default {
  system: hapTasks,
  plugins: []
}
