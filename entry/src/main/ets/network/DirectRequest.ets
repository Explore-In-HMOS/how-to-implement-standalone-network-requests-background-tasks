import { connection, http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CONNECT_TIMEOUT_MS, ENDPOINT, logE, logI, READ_TIMEOUT_MS, USER_AGENT } from '../common/Constants';
import { currentNetwork, describeNet, findStandaloneNet, LinkKind } from './NetworkMonitor';

export class RequestResult {
  ok: boolean = false;
  code: number = 0;
  totalMs: number = 0;
  dnsMs: number = 0;
  tcpMs: number = 0;
  tlsMs: number = 0;
  bytes: number = 0;
  link: LinkKind = 'none';
  tempC: number = NaN;
  windKmh: number = NaN;
  sky: string = '';
  error: string = '';
  at: number = 0;
}

interface InstantDetails {
  airTemperature?: number;
  windSpeed?: number;
}

interface Summary {
  symbolCode?: string;
}

interface Period {
  summary?: Summary;
}

interface StepData {
  instant?: Instant;
  next1Hours?: Period;
}

interface Instant {
  details?: InstantDetails;
}

interface Step {
  data?: StepData;
}

interface ForecastProps {
  timeseries?: Array<Step>;
}

interface ForecastBody {
  properties?: ForecastProps;
}

/**
 * Binds the app to the watch's own Wi-Fi/cellular network so traffic does not go
 * through the paired phone. Returns the kind of link the request will use,
 * or 'none' when only the phone relay (or nothing) is available.
 */
export async function bindStandalone(): Promise<LinkKind> {
  const handle = findStandaloneNet();
  if (handle === undefined) {
    return 'none';
  }
  try {
    await connection.setAppNet(handle);
  } catch (e) {
    logE(`setAppNet failed: ${JSON.stringify(e)}`);
    return 'none';
  }
  return describeNet(handle).kind;
}

/** Performs one GET over the watch's own radio and returns timing + parsed payload. */
export async function fetchDirect(): Promise<RequestResult> {
  const result = new RequestResult();
  result.at = Date.now();
  result.link = await bindStandalone();
  if (result.link === 'none') {
    result.error = currentNetwork().kind === 'relay' ? 'Only phone relay available' : 'No network';
    return result;
  }

  const req = http.createHttp();
  const started = Date.now();
  try {
    const resp = await req.request(ENDPOINT, {
      method: http.RequestMethod.GET,
      header: { 'Accept': 'application/json', 'User-Agent': USER_AGENT },
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: CONNECT_TIMEOUT_MS,
      readTimeout: READ_TIMEOUT_MS
    });
    result.code = resp.responseCode;
    result.ok = resp.responseCode >= 200 && resp.responseCode < 300;
    const t = resp.performanceTiming;
    result.totalMs = Math.round(t?.totalFinishTiming ?? (Date.now() - started));
    result.dnsMs = Math.round(t?.dnsTiming ?? 0);
    result.tcpMs = Math.round(t?.tcpTiming ?? 0);
    result.tlsMs = Math.round(t?.tlsTiming ?? 0);

    const text = resp.result as string;
    result.bytes = text.length;
    if (result.ok) {
      const body = JSON.parse(text) as ForecastBody;
      const steps: Array<Step> = body.properties?.timeseries ?? [];
      const now: StepData | undefined = steps.length > 0 ? steps[0].data : undefined;
      result.tempC = now?.instant?.details?.airTemperature ?? NaN;
      const windMs: number = now?.instant?.details?.windSpeed ?? NaN;
      result.windKmh = windMs * 3.6;
      result.sky = now?.next1Hours?.summary?.symbolCode ?? '';
    } else {
      result.error = `HTTP ${resp.responseCode}`;
    }
    logI(`direct GET ${result.code} via ${result.link} in ${result.totalMs}ms`);
  } catch (e) {
    const err = e as BusinessError;
    result.totalMs = Date.now() - started;
    result.error = err.message ? err.message : `Error ${err.code}`;
    logE(`direct GET failed: ${err.code} ${err.message}`);
  } finally {
    req.destroy();
  }
  return result;
}
