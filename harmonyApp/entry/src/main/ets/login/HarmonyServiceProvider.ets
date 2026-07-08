import { getHarmonyLoginService, HarmonyLoginService } from '../knoi/provider';

let cachedService: HarmonyLoginService | null = null;

export function getService(): HarmonyLoginService {
  if (cachedService === null) {
    cachedService = getHarmonyLoginService();
  }
  return cachedService;
}
