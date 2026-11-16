import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { logE, logI } from '../common/Constants';

/**
 * Link the watch is currently using.
 * - wifi / cellular / ethernet: the watch's own radio -> standalone, no phone needed.
 * - relay: Bluetooth bearer, i.e. traffic tunnelled through the paired phone.
 * - none: no usable network.
 */
export type LinkKind = 'wifi' | 'cellular' | 'ethernet' | 'relay' | 'none';

export class NetSnapshot {
  kind: LinkKind = 'none';
  netId: number = 0;
  hasInternet: boolean = false;
  validated: boolean = false;
  metered: boolean = false;
  upKbps: number = 0;
  downKbps: number = 0;

  get standalone(): boolean {
    return this.kind === 'wifi' || this.kind === 'cellular' || this.kind === 'ethernet';
  }

  get online(): boolean {
    return this.kind !== 'none' && this.hasInternet;
  }
}

export type NetListener = (snap: NetSnapshot) => void;

function kindOf(bearers: Array<connection.NetBearType>): LinkKind {
  if (bearers.indexOf(connection.NetBearType.BEARER_WIFI) >= 0) {
    return 'wifi';
  }
  if (bearers.indexOf(connection.NetBearType.BEARER_CELLULAR) >= 0) {
    return 'cellular';
  }
  if (bearers.indexOf(connection.NetBearType.BEARER_ETHERNET) >= 0) {
    return 'ethernet';
  }
  if (bearers.indexOf(connection.NetBearType.BEARER_BLUETOOTH) >= 0) {
    return 'relay';
  }
  return 'none';
}

export function describeNet(handle: connection.NetHandle): NetSnapshot {
  const snap = new NetSnapshot();
  if (!handle || handle.netId === 0) {
    return snap;
  }
  let caps: connection.NetCapabilities;
  try {
    caps = connection.getNetCapabilitiesSync(handle);
  } catch (e) {
    logE(`getNetCapabilities(${handle.netId}) failed: ${JSON.stringify(e)}`);
    return snap;
  }
  const netCaps: Array<connection.NetCap> = caps.networkCap ?? [];
  snap.kind = kindOf(caps.bearerTypes);
  snap.netId = handle.netId;
  snap.hasInternet = netCaps.indexOf(connection.NetCap.NET_CAPABILITY_INTERNET) >= 0;
  snap.validated = netCaps.indexOf(connection.NetCap.NET_CAPABILITY_VALIDATED) >= 0;
  snap.metered = netCaps.indexOf(connection.NetCap.NET_CAPABILITY_NOT_METERED) < 0;
  snap.upKbps = caps.linkUpBandwidthKbps ?? 0;
  snap.downKbps = caps.linkDownBandwidthKbps ?? 0;
  return snap;
}

/** Reads the default network. Safe to call from any context (UI, extension, timer). */
export function currentNetwork(): NetSnapshot {
  try {
    if (!connection.hasDefaultNetSync()) {
      return new NetSnapshot();
    }
    return describeNet(connection.getDefaultNetSync());
  } catch (e) {
    logE(`currentNetwork failed: ${JSON.stringify(e)}`);
    return new NetSnapshot();
  }
}

/**
 * Finds a network carried by the watch's own radio (Wi-Fi first, then cellular),
 * even when the system default route goes through the phone over Bluetooth.
 */
export function findStandaloneNet(): connection.NetHandle | undefined {
  try {
    const nets = connection.getAllNetsSync();
    let cellular: connection.NetHandle | undefined = undefined;
    for (const net of nets) {
      const snap = describeNet(net);
      if (!snap.hasInternet) {
        continue;
      }
      if (snap.kind === 'wifi' || snap.kind === 'ethernet') {
        return net;
      }
      if (snap.kind === 'cellular' && cellular === undefined) {
        cellular = net;
      }
    }
    return cellular;
  } catch (e) {
    logE(`findStandaloneNet failed: ${JSON.stringify(e)}`);
    return undefined;
  }
}

/** Pushes a fresh snapshot to listeners whenever the default network changes. */
export class NetworkMonitor {
  private static inst: NetworkMonitor | undefined = undefined;
  private conn: connection.NetConnection | undefined = undefined;
  private listeners: Array<NetListener> = [];
  private last: NetSnapshot = new NetSnapshot();

  static get(): NetworkMonitor {
    if (NetworkMonitor.inst === undefined) {
      NetworkMonitor.inst = new NetworkMonitor();
    }
    return NetworkMonitor.inst;
  }

  get snapshot(): NetSnapshot {
    return this.last;
  }

  subscribe(listener: NetListener): void {
    this.listeners.push(listener);
    if (this.listeners.length === 1) {
      this.start();
    }
    listener(this.refresh());
  }

  unsubscribe(listener: NetListener): void {
    this.listeners = this.listeners.filter((l: NetListener) => l !== listener);
    if (this.listeners.length === 0) {
      this.stop();
    }
  }

  refresh(): NetSnapshot {
    this.last = currentNetwork();
    return this.last;
  }

  private emit(): void {
    const snap = this.refresh();
    this.listeners.forEach((l: NetListener) => l(snap));
  }

  private start(): void {
    try {
      this.conn = connection.createNetConnection();
      this.conn.on('netAvailable', () => this.emit());
      this.conn.on('netCapabilitiesChange', () => this.emit());
      this.conn.on('netLost', () => this.emit());
      this.conn.on('netUnavailable', () => this.emit());
      this.conn.register((err: BusinessError) => {
        if (err) {
          logE(`net register failed: ${err.code} ${err.message}`);
        } else {
          logI('net monitor registered');
        }
      });
    } catch (e) {
      logE(`net monitor start failed: ${JSON.stringify(e)}`);
    }
  }

  private stop(): void {
    this.conn?.unregister(() => {
    });
    this.conn = undefined;
  }
}
