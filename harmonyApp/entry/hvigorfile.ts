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
const GENERATED_KNOI_PROVIDER = path.resolve(process.cwd(), 'entry/src/main/ets/knoi/provider.ets');
const SHARED_LOGIN_OUTPUTS = [
  ...SHARED_LOGIN_NATIVE_CANDIDATES,
  GENERATED_KNOI_PROVIDER
];
const BRIDGE_DIR = path.resolve(process.cwd(), '../harmony-kmp-bridge');
const BRIDGE_SOURCE_DIR = path.resolve(BRIDGE_DIR, 'src/ohosArm64Main/kotlin');
const COMMON_SOURCE_DIR = path.resolve(process.cwd(), '../common/src/commonMain/kotlin');
const KOTLIN_SOURCE_DIRS = [
  BRIDGE_SOURCE_DIR,
  COMMON_SOURCE_DIR
];
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

function latestKotlinSourceMtime(): number {
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

  return KOTLIN_SOURCE_DIRS
    .map((sourceDir: string) => walkDir(sourceDir))
    .reduce((latest: number, current: number) => Math.max(latest, current), 0);
}

function isKotlinSourceNewerThanNativeLibs(): boolean {
  const outputMtimes = SHARED_LOGIN_NATIVE_CANDIDATES
    .filter((output: string) => fs.existsSync(output))
    .map((output: string) => fs.statSync(output).mtimeMs);
  if (outputMtimes.length !== SHARED_LOGIN_NATIVE_CANDIDATES.length) {
    return true;
  }
  const oldestOutputMtime = outputMtimes.reduce(
    (oldest: number, current: number) => Math.min(oldest, current),
    Number.POSITIVE_INFINITY
  );
  return latestKotlinSourceMtime() > oldestOutputMtime;
}

function buildSharedLoginNative(): void {
  const missingOutputs = SHARED_LOGIN_OUTPUTS.filter((output: string) => !fs.existsSync(output));

  if (missingOutputs.length === 0 && KOTLIN_SOURCE_DIRS.some((sourceDir: string) => fs.existsSync(sourceDir))) {
    if (!isKotlinSourceNewerThanNativeLibs()) {
      return; // generated bridge outputs are up-to-date
    }
    process.stdout.write(
      '[build-bridge] Kotlin source changed, rebuilding native bridge...\n'
    );
  } else if (missingOutputs.length === 0) {
    return; // outputs exist and we can't check source, so assume up-to-date
  } else {
    process.stdout.write(
      `[build-bridge] Generated bridge output missing, rebuilding native bridge:\n${missingOutputs.join('\n')}\n`
    );
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

  const stillMissingOutputs = SHARED_LOGIN_OUTPUTS.filter((output: string) => !fs.existsSync(output));
  if (stillMissingOutputs.length > 0 || !findExistingLib()) {
    throw new Error(
      'Build completed but generated bridge outputs are still missing. ' +
      `Missing:\n${stillMissingOutputs.join('\n')}`
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
