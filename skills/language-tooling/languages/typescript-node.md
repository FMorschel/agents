# TypeScript / JavaScript on Node.js (and Angular)

The exact command names vary by project: the `scripts` in `package.json` rule (`npm run lint`, `npm test`). Below, the default when the project defines nothing. The package manager can be npm, pnpm or yarn: use the one the lockfile indicates.

## Static analysis and compilation

- Types: `npx tsc --noEmit` (in plain JavaScript, ESLint and `checkJs` in `tsconfig.json`).
- Lint: `npx eslint .` (configuration in `eslint.config.js` or `.eslintrc.*`). Some projects use Biome (`npx biome check`).
- "Compiles" means `tsc --noEmit` with no errors; the project's `build` is the final test.
- `strict` and `strictNullChecks` in `tsconfig.json` define how much the compiler catches.

## Formatting and automatic fixes

- Prettier: `npx prettier --write <files>`; or `npx biome format --write`.
- Lint fixes: `npx eslint --fix <files>`.
- Suggested post-edit order: `eslint --fix` → `tsc --noEmit` → `prettier --write` → tests.

## Checking without changing files

For a review, which never writes: `npm run lint:check` (or `npx eslint .` **without** `--fix`), `npx prettier --check .` (or `npm run format:check`), `npx tsc --noEmit` (or `npm run typecheck`) and `npm test`. Never `--fix`, `--write`, `npm install` nor `npm ci` (it touches `node_modules` and the lockfile). A `package.json` script called just `lint` or `format` usually writes: check its content before running it.

## Tests and coverage

- The project's runner: Jest (`npx jest`), Vitest (`npx vitest run`) or the built-in `node --test`; check `devDependencies`.
- Filter: `-t "<name>"` (Jest/Vitest) or `--test-name-pattern` (`node --test`); by file, pass the path.
- Coverage: `npx jest --coverage`, `npx vitest run --coverage` or `node --test --experimental-test-coverage`.
- How to write: `write-dart-tests` (general rules, including Jest, Angular and RxJS).
- Test files live in `*.test.ts`/`*.spec.ts` next to the source or in `__tests__/`/`test/`: copy what the project does.
- Async: `await expect(promise).rejects.toThrow(...)`; never leave a promise without `await` in a test.
- `git stash push -- <production files>` serves for the red → green proof.

## Manifest, lockfile and dependencies

- `package.json` and the lockfile (`package-lock.json`, `pnpm-lock.yaml` or `yarn.lock`, only one of them); `tsconfig.json` for the compiler.
- The lockfile goes with the `package.json` change in the same commit.

## Generated files

- Build output (`dist/`, `build/`, `.next/`), emitted declarations (generated `*.d.ts`), `*.generated.ts`, `__generated__/`, GraphQL/OpenAPI/Prisma clients. They are normally in `.gitignore` or marked with a "generated" header.
- Regeneration: the project's script (`npm run codegen`, `npx prisma generate`, …).
- Generated output goes in the same commit as the source that triggers it, when versioned; it stays out of coverage and of style inference.

## Doc comments, references and TODO

- TSDoc/JSDoc: `/** ... */`; symbol reference `{@link Name}` or `{@link Class.member}`; `@param name`, `@returns`, `@throws`. In TypeScript do not repeat the type in `@param`.
- `// TODO(name): ...`; there is no continuation indentation rule, but keep them aligned.

## Suppressing a lint or a type error

- `// eslint-disable-next-line rule-name`, `/* eslint-disable rule-name */`.
- `// @ts-expect-error <reason>` (preferable, fails when it stops being needed) and `// @ts-ignore`.

## Nulls

- `null` and `undefined` are distinct; type narrowing happens with `if (x == null) return;` or `x === undefined`.
- `x!` is the non-null assertion; `x ?? default` and `x?.y` avoid the `!`.
- Parameters and local `const`s narrow; mutable object properties do not, so copy to a local `const` before the `if`.

## Script output

- `process.stdout.write('text ... ')` is synchronous for files and terminals, so there is no explicit flush; errors on `console.error`/`process.stderr`.
- Child process: `spawn(cmd, args, { stdio: 'inherit' })` to inherit the terminal instead of capturing with `exec`.
- A long loop that does not yield to the event loop also leaves the terminal frozen: `await` between steps.

## Post-edit flow

There is no dedicated skill. Run, in this order: lint auto-fix, type check, formatter, the module's tests and then the full suite, using the project's scripts.

## Angular

An Angular project is a TypeScript project (everything above applies) with the Angular CLI on top. Signal: `angular.json` (or `project.json` in an Nx workspace). Confirm the commands in the `package.json` `scripts`; the CLI default is:

- **Compilation and types:** `npx ng build` really compiles, templates included (`strictTemplates` in `tsconfig.json` makes the compiler check the `.html` files). `tsc --noEmit` alone does not see template errors.
- **Lint:** `npx ng lint` (requires `angular-eslint` configured; without it, `eslint .`).
- **Tests:** `npx ng test --watch=false` (Karma + Jasmine in older projects, Vitest in newer ones, Jest when the project adopted it); a single file: `--include='**/x.spec.ts'`. Coverage: `npx ng test --watch=false --code-coverage` (Karma) or the runner's equivalent. Component tests use `TestBed`; end-to-end tests (Playwright, Cypress) live in another folder and another command (`ng e2e`).
- **Generated:** `ng generate` creates new files (`*.component.ts`, `.html`, `.scss`, `.spec.ts`); keep only what the task asks for. `dist/`, `.angular/` (cache) and `coverage/` are not versioned. OpenAPI-generated clients live in their own folder.
- **Dependencies:** `npx ng add` and `ng update` change `package.json`, the lockfile and sometimes `angular.json`/`tsconfig`; an `ng update` goes in a commit of its own (`compose-commits`).
- **Nulls:** in templates, `?.` and `@if` narrow the value; the `!` in the template (`value!`) is the non-null assertion, with the same rules as `preserve-existing-code`.
- **Async, change detection and resources that need disposal:** `review-angular-async-and-disposal` (the Angular counterpart of `review-flutter-async-and-disposal`). A `subscribe` with no teardown in a component is a finding.
- **Conventions:** the official style guide and `angular-eslint` apply if the project uses them; otherwise, sample (`resolve-project-conventions`). Standalone components vs. NgModules, `inject()` vs. constructor injection, and signals vs. RxJS are project decisions: follow the dominant one in the folder.
