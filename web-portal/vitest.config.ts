import { existsSync } from 'node:fs';
import path from 'node:path';

import { isMatch } from 'picomatch';
import { defineConfig } from 'vitest/config';

let workspaceRoot = process.cwd();

function coverageVirtualFilesPatch(): { name: string; configResolved: () => void } {
  return {
    name: 'angular:coverage-virtual-files',
    configResolved(config) {
      workspaceRoot = config.root;
      // Workaround for https://github.com/angular/angular-cli/issues/33023
      // The Angular unit-test builder serves bundled test files from memory.
      // Vitest's v8 coverage provider filters scripts by the built-in
      // `isIncluded`, which relies on the default `allowExternal`/glob checks
      // that drop these virtual files and report 0% coverage. Patch the base
      // provider so virtual build artifacts are included while real files keep
      // the normal include/exclude filtering.
      const patch = async () => {
        const { BaseCoverageProvider } = await import('vitest/node');
        if (!BaseCoverageProvider?.prototype?.isIncluded) {
          return;
        }
        BaseCoverageProvider.prototype.isIncluded = function (filename: string): boolean {
          const relativeFilename = path
            .relative(workspaceRoot, filename)
            .split(path.sep)
            .join('/');
          if (!existsSync(filename)) {
            return !isMatch(relativeFilename, this.options.exclude);
          }
          const glob = this.options.include || '**';
          return isMatch(relativeFilename, glob, { ignore: this.options.exclude });
        };
      };
      void patch();
    },
  };
}

export default defineConfig({
  plugins: [coverageVirtualFilesPatch()],
  test: {
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
      enabled: true,
      reporter: ['text', 'text-summary', 'html'],
      include: ['src/**/*.ts'],
      exclude: [
        'src/**/*.spec.ts',
        'src/main.ts',
        'src/environments/**',
        'src/**/*.model.ts',
        'src/app/core/mocks/**',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});