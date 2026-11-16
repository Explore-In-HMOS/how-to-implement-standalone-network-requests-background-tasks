import { LinkKind } from '../network/NetworkMonitor';
import { SyncOutcome, SyncTrigger } from '../background/SyncLog';

export function linkColor(kind: LinkKind): Resource {
  switch (kind) {
    case 'wifi':
    case 'ethernet':
      return $r('app.color.wifi');
    case 'cellular':
      return $r('app.color.cellular');
    case 'relay':
      return $r('app.color.relay');
    default:
      return $r('app.color.offline');
  }
}

export function linkSymbol(kind: LinkKind): Resource {
  switch (kind) {
    case 'wifi':
    case 'ethernet':
      return $r('sys.symbol.wifi');
    case 'cellular':
      return $r('sys.symbol.signal');
    case 'relay':
      return $r('sys.symbol.phone');
    default:
      return $r('sys.symbol.wifi_slash');
  }
}

export function linkLabel(kind: LinkKind): string {
  switch (kind) {
    case 'wifi':
      return 'Wi-Fi';
    case 'ethernet':
      return 'Ethernet';
    case 'cellular':
      return 'Cellular';
    case 'relay':
      return 'Phone relay';
    default:
      return 'Offline';
  }
}

export function outcomeColor(outcome: SyncOutcome): Resource {
  switch (outcome) {
    case 'success':
      return $r('app.color.wifi');
    case 'skipped_relay':
      return $r('app.color.relay');
    case 'skipped_offline':
      return $r('app.color.text_secondary');
    default:
      return $r('app.color.offline');
  }
}

export function triggerLabel(trigger: SyncTrigger): string {
  switch (trigger) {
    case 'continuous':
      return 'LIVE';
    case 'scheduler':
      return 'JOB';
    default:
      return 'TAP';
  }
}

/** MET Norway symbolCode (e.g. 'partlycloudy_day', 'lightrain') -> system symbol. */
export function weatherSymbol(sky: string): Resource {
  if (sky.indexOf('snow') >= 0 || sky.indexOf('sleet') >= 0) {
    return $r('sys.symbol.cloud_snow');
  }
  if (sky.indexOf('rain') >= 0 || sky.indexOf('thunder') >= 0) {
    return $r('sys.symbol.cloud_heavy_storm');
  }
  if (sky.startsWith('clearsky') || sky.startsWith('fair')) {
    return $r('sys.symbol.sun_max_fill');
  }
  if (sky.startsWith('partlycloudy')) {
    return $r('sys.symbol.cloud_and_sun_fill');
  }
  return $r('sys.symbol.cloud_fill');
}

export function weatherTint(sky: string): Resource {
  if (sky.startsWith('clearsky') || sky.startsWith('fair') || sky.startsWith('partlycloudy')) {
    return $r('app.color.relay');
  }
  if (sky.indexOf('rain') >= 0 || sky.indexOf('snow') >= 0 || sky.indexOf('sleet') >= 0) {
    return $r('app.color.cellular');
  }
  return $r('app.color.text_secondary');
}

/** Translucent hex for the soft halo behind the status ring (Resources can't take alpha). */
export function linkGlow(kind: LinkKind): string {
  switch (kind) {
    case 'wifi':
    case 'ethernet':
      return '#553DDC97';
    case 'cellular':
      return '#554DA3FF';
    case 'relay':
      return '#55FFB547';
    default:
      return '#55FF5C6C';
  }
}
