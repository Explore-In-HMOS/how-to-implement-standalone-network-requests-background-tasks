function pad(n: number): string {
  return n < 10 ? `0${n}` : `${n}`;
}

export function clock(ms: number): string {
  const d = new Date(ms);
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
}

export function kbps(v: number): string {
  if (v <= 0) {
    return '—';
  }
  return v >= 1000 ? `${(v / 1000).toFixed(v >= 10000 ? 0 : 1)} Mb/s` : `${v} kb/s`;
}
