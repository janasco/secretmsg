import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const PUBLIC_DIR = resolve(__dirname, '..', 'public');

/** Google's public AdMob certification ID, fixed by the IAB tech lab. */
const ADMOD_CERTIFICATION_ID = 'f08c47fec0942fa0';

/**
 * A seller record is four comma-separated fields:
 *   exchange domain, publisher ID, relationship, certification ID
 */
function parseSellerRecords(body: string): string[][] {
  return body
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0 && !line.startsWith('#'))
    .map((line) => line.split(',').map((field) => field.trim()));
}

function read(file: string): string {
  return readFileSync(resolve(PUBLIC_DIR, file), 'utf8');
}

describe.each(['ads.txt', 'app-ads.txt'])('%s', (file) => {
  const body = read(file);
  const records = parseSellerRecords(body);

  it('declares at least one seller', () => {
    expect(records.length).toBeGreaterThan(0);
  });

  // Each record is wrapped so vitest spreads one argument, not four.
  it.each(records.map((record) => [record]))(
    'has four well-formed fields in %j',
    (fields) => {
      expect(fields).toHaveLength(4);
      for (const field of fields) {
        expect(field).not.toBe('');
      }
    },
  );

  it('uses a valid publisher ID for every record', () => {
    for (const [, publisherId] of records) {
      expect(publisherId).toMatch(/^pub-\d{10,20}$/);
    }
  });

  it('points the Google seller at the AdMob certification ID', () => {
    const google = records.find(([domain]) => domain === 'google.com');
    expect(google).toBeDefined();
    expect(google?.[2]).toBe('DIRECT');
    expect(google?.[3]).toBe(ADMOD_CERTIFICATION_ID);
  });

  it('still carries the unsubstituted placeholder publisher ID', () => {
    // Deliberate. These files ship with a placeholder seller ID, which is a
    // known and documented gap. Flip this to a positive assertion once the real
    // AdMob publisher ID is in place, so the check becomes a guard instead of a
    // standing reminder.
    expect(body).toContain('pub-0000000000000000');
  });
});

describe('ads.txt and app-ads.txt agree', () => {
  it('authorize the same publisher in both files', () => {
    const domainPublishers = parseSellerRecords(read('ads.txt'))
      .filter(([domain]) => domain === 'google.com')
      .map(([, publisherId]) => publisherId);
    const appPublishers = parseSellerRecords(read('app-ads.txt'))
      .filter(([domain]) => domain === 'google.com')
      .map(([, publisherId]) => publisherId);

    expect(domainPublishers).toEqual(appPublishers);
  });

  it('name the shipped Android package in app-ads.txt', () => {
    // AdMob matches app-ads.txt to an app via these store identifiers, so a
    // renamed or replaced package would silently stop authorizing sellers.
    expect(read('app-ads.txt')).toContain('net.secretmsg.android_app');
  });
});
