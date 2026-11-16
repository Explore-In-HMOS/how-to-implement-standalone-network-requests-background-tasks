import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { BUNDLE_NAME, CONTINUOUS_INTERVAL_MS, logE, logI } from '../common/Constants';
import { runSync } from './SyncJob';

/**
 * Continuous task (dataTransfer mode): keeps the UIAbility process alive while backgrounded
 * and runs a connectivity-gated sync every CONTINUOUS_INTERVAL_MS. The system shows an
 * ongoing notification while it runs; tapping it reopens EntryAbility.
 */
export class ContinuousSync {
  private static timer: number = -1;
  private static running: boolean = false;

  static get isRunning(): boolean {
    return ContinuousSync.running;
  }

  static async start(ctx: common.UIAbilityContext): Promise<string> {
    if (ContinuousSync.running) {
      return '';
    }
    try {
      const agent: WantAgent = await wantAgent.getWantAgent({
        wants: [{ bundleName: BUNDLE_NAME, abilityName: 'EntryAbility' }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      });
      await backgroundTaskManager.startBackgroundRunning(ctx,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER, agent);
    } catch (e) {
      const err = e as BusinessError;
      logE(`startBackgroundRunning failed: ${err.code} ${err.message}`);
      return `Error ${err.code}`;
    }
    ContinuousSync.running = true;
    runSync(ctx, 'continuous');
    ContinuousSync.timer = setInterval(() => {
      runSync(ctx, 'continuous');
    }, CONTINUOUS_INTERVAL_MS);
    logI('continuous sync started');
    return '';
  }

  static async stop(ctx: common.UIAbilityContext): Promise<void> {
    if (ContinuousSync.timer !== -1) {
      clearInterval(ContinuousSync.timer);
      ContinuousSync.timer = -1;
    }
    if (!ContinuousSync.running) {
      return;
    }
    ContinuousSync.running = false;
    try {
      await backgroundTaskManager.stopBackgroundRunning(ctx);
    } catch (e) {
      const err = e as BusinessError;
      logE(`stopBackgroundRunning failed: ${err.code} ${err.message}`);
    }
    logI('continuous sync stopped');
  }
}
