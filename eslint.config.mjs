import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';
import security from 'eslint-plugin-security';

export default [
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        require: 'readonly',
        module: 'readonly',
        exports: 'readonly',
        global: 'readonly',
        setTimeout: 'readonly',
        window: 'readonly',
        navigator: 'readonly',
      },
    },
    plugins: {
      security,
    },
    rules: {
      // Security rules
      'security/detect-buffer-noassert': 'error',
      'security/detect-child-process': 'warn',
      'security/detect-disable-mustache-escape': 'error',
      'security/detect-eval-with-expression': 'error',
      'security/detect-new-buffer': 'error',
      'security/detect-no-csrf-before-method-override': 'error',
      'security/detect-non-literal-fs-filename': 'warn',
      'security/detect-non-literal-regexp': 'warn',
      'security/detect-non-literal-require': 'error',
      'security/detect-object-injection': 'error',
      'security/detect-possible-timing-attacks': 'error',
      'security/detect-pseudoRandomBytes': 'error',
      'security/detect-unsafe-regex': 'error',

      // Best practices - relaxed for template/example code
      'no-console': 'off',
      'no-debugger': 'error',
      'no-alert': 'error',
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-new-func': 'error',
      'no-script-url': 'error',
      'no-sequences': 'error',
      'no-throw-literal': 'error',
      'no-unmodified-loop-condition': 'error',
      'no-unused-labels': 'error',
      'no-useless-call': 'error',
      'no-useless-concat': 'error',
      'no-useless-escape': 'error',
      'no-useless-return': 'error',
      'no-void': 'error',
      'prefer-promise-reject-errors': 'error',
      'require-await': 'error',
      'no-return-await': 'error',

      // Variables & scope
      'no-unused-vars': 'error',
      'no-shadow': 'error',
      'no-undef': 'error',
      'prefer-const': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'prefer-arrow-callback': 'error',
      'prefer-template': 'error',
      'template-curly-spacing': ['error', 'never'],
      'arrow-spacing': 'error',
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'no-duplicate-imports': 'error',
      'no-template-curly-in-string': 'error',

      // Functions
      'func-names': ['error', 'as-needed'],
      'func-style': ['error', 'declaration', { allowArrowFunctions: true }],
      'no-loop-func': 'error',

      // Classes & objects
      'no-constructor-return': 'error',
      'no-dupe-class-members': 'error',
      'no-useless-constructor': 'error',

      // Arrays & collections
      'array-callback-return': 'error',
      'no-sparse-arrays': 'error',
      'prefer-destructuring': [
        'error',
        {
          array: true,
          object: true,
        },
        {
          enforceForRenamedProperties: false,
        },
      ],
    },
  },
  {
    files: ['**/*.ts'],
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: 'module',
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
      },
      globals: {
        console: 'readonly',
        process: 'readonly',
        __dirname: 'readonly',
        __filename: 'readonly',
        require: 'readonly',
        module: 'readonly',
        exports: 'readonly',
        global: 'readonly',
        setTimeout: 'readonly',
        window: 'readonly',
        navigator: 'readonly',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      security,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      // Security rules
      'security/detect-buffer-noassert': 'error',
      'security/detect-child-process': 'warn',
      'security/detect-disable-mustache-escape': 'error',
      'security/detect-eval-with-expression': 'error',
      'security/detect-new-buffer': 'error',
      'security/detect-no-csrf-before-method-override': 'error',
      'security/detect-non-literal-fs-filename': 'warn',
      'security/detect-non-literal-regexp': 'warn',
      'security/detect-non-literal-require': 'error',
      'security/detect-object-injection': 'error',
      'security/detect-possible-timing-attacks': 'error',
      'security/detect-pseudoRandomBytes': 'error',
      'security/detect-unsafe-regex': 'error',

      // Best practices - relaxed for template/example code
      'no-console': 'off',
      'no-debugger': 'error',
      'no-alert': 'error',
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-new-func': 'error',
      'no-script-url': 'error',
      'no-sequences': 'error',
      'no-throw-literal': 'error',
      'no-unmodified-loop-condition': 'error',
      'no-unused-labels': 'error',
      'no-useless-call': 'error',
      'no-useless-concat': 'error',
      'no-useless-escape': 'error',
      'no-useless-return': 'error',
      'no-void': 'error',
      'prefer-promise-reject-errors': 'error',
      'require-await': 'error',
      'no-return-await': 'error',

      // Variables & scope
      'prefer-const': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'prefer-arrow-callback': 'error',
      'prefer-template': 'error',
      'template-curly-spacing': ['error', 'never'],
      'arrow-spacing': 'error',
      eqeqeq: ['error', 'always', { null: 'ignore' }],
      'no-duplicate-imports': 'error',
      'no-template-curly-in-string': 'error',

      // Functions
      'func-names': ['error', 'as-needed'],
      'func-style': ['error', 'declaration', { allowArrowFunctions: true }],
      'no-loop-func': 'error',

      // Classes & objects
      'no-constructor-return': 'error',
      'no-dupe-class-members': 'error',
      'no-useless-constructor': 'error',

      // Arrays & collections
      'array-callback-return': 'error',
      'no-sparse-arrays': 'error',
      'prefer-destructuring': [
        'error',
        {
          array: true,
          object: true,
        },
        {
          enforceForRenamedProperties: false,
        },
      ],
    },
  },
  {
    files: ['**/*.test.{js,ts}'],
    languageOptions: {
      globals: {
        jest: 'readonly',
        describe: 'readonly',
        it: 'readonly',
        test: 'readonly',
        expect: 'readonly',
        beforeEach: 'readonly',
        afterEach: 'readonly',
        beforeAll: 'readonly',
        afterAll: 'readonly',
      },
    },
  },
  {
    files: ['scripts/load-test.js'],
    languageOptions: {
      globals: {
        __ENV: 'readonly',
        __VU: 'readonly',
        console: 'readonly',
        process: 'readonly',
        setTimeout: 'readonly',
      },
    },
  },
  {
    ignores: [
      'build/',
      'dist/',
      'vendor/',
      'temp/',
      'node_modules/',
      '*.min.js',
      '*.bundle.js',
      '*.d.ts',
      'coverage/',
      '.nyc_output/',
    ],
  },
];