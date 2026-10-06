import '@angular/compiler';
import { getTestBed } from '@angular/core/testing';
import {
  BrowserTestingModule,
  platformBrowserTesting,
} from '@angular/platform-browser/testing';

// The Angular `ng test` (unit-test builder) already initializes the test
// environment before loading this setup file, while plain `npx vitest`
// relies on this file. Guard so the file works under both runners.
try {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting(), {
    teardown: { destroyAfterEach: true },
  });
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  if (!message.includes('already been called')) {
    throw err;
  }
}
