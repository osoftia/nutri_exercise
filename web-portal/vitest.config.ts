import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

import angular from '@analogjs/vite-plugin-angular';
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

/**
 * Inline Angular component external resources (`templateUrl`/`styleUrl`/
 * `styleUrls`) for plain `npx vitest` runs, which (unlike `ng test`) do not
 * go through the Angular AOT compiler. Styles are dropped (`styles: []`)
 * since they are irrelevant to unit tests; templates are inlined so
 * `TestBed.compileComponents()` / JIT resolution succeeds.
 *
 * Under `ng test` the builder AOT-compiles components first, so this
 * transform is a no-op there. The plugin name intentionally does NOT start
 * with `angular:`/`vitest` so the unit-test builder keeps it as a user
 * plugin instead of stripping it.
 */
function jitResourceInline(): { name: string; enforce: string; transform: (code: string, id: string) => string | undefined } {
  return {
    name: 'jit-resource-inline',
    enforce: 'pre',
    transform(code: string, id: string) {
      const filePath = id.split('?')[0];
      if (!filePath.endsWith('.ts')) {
        return undefined;
      }
      if (!code.includes('templateUrl') && !code.includes('styleUrl')) {
        return undefined;
      }
      const dir = path.dirname(filePath);
      let result = code;
      result = result.replace(/templateUrl\s*:\s*['"]([^'"]+)['"]/g, (_match, rel: string) => {
        try {
          const html = readFileSync(path.join(dir, rel), 'utf-8')
            .replace(/\\/g, '\\\\')
            .replace(/`/g, '\\`')
            .replace(/\$\{/g, '\\${');
          return `template: \`${html}\``;
        } catch {
          return 'template: ``';
        }
      });
      result = result.replace(/styleUrl\s*:\s*['"][^'"]+['"]/g, 'styles: []');
      result = result.replace(/styleUrls\s*:\s*\[[^\]]*\]/g, 'styles: []');
      return result === code ? undefined : result;
    },
  };
}

export default defineConfig({
  plugins: [
    angular({ tsconfig: './tsconfig.app.json', disableTypeChecking: true }),
    jitResourceInline(),
    coverageVirtualFilesPatch(),
  ],
  test: {
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
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