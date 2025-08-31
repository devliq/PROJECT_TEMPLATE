module.exports = {
    env: {
        browser: true,
        es2021: true,
        node: true,
        jest: true,
    },
    extends: [
        'eslint:recommended',
        'prettier',
    ],
    plugins: [
        'prettier',
        'security',
    ],
    rules: {
        // Prettier integration
        'prettier/prettier': 'error',

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

        // Best practices
        'no-console': 'warn',
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
        'eqeqeq': ['error', 'always', { null: 'ignore' }],
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
    ignorePatterns: [
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
};