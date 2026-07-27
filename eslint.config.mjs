import path from "path";
import { fileURLToPath } from "url";
import babelParser from "@babel/eslint-parser";
import globals from "globals";
import { defineConfig, globalIgnores } from "@eslint/config-helpers";
import { FlatCompat } from "@eslint/eslintrc";
import js from '@eslint/js';
import allyPlugin from 'eslint-plugin-jsx-a11y';
import reactPlugin from 'eslint-plugin-react';
import importPlugin from 'eslint-plugin-import';
import { fixupConfigRules } from "@eslint/compat";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

  const compat = new FlatCompat({
    baseDirectory: __dirname,
  });
export default defineConfig([
  js.configs.recommended,
  allyPlugin.flatConfigs.recommended,
  reactPlugin.configs.flat.recommended,
  importPlugin.flatConfigs.recommended,
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.jest,
        ...globals.node
      },
      parser: babelParser,
      parserOptions: {
        ecmaVersion: 2020
      }
    },
    settings: {
      "import/resolver": {
        "typescript": true,
        "node": true
      },
      react: {
        version: "detect"
      }
    },
    rules: {
      "consistent-return": ["error"],
      "eqeqeq": ["error", "always", {"null": "ignore"}],
      "import/no-cycle": ["error", { maxDepth: 1 }],
      "import/no-unresolved": ["error"],
      "indent": ["error", 2],
      "jsx-a11y/label-has-associated-control": [2, {"assert": "either"}],
      "max-len": [
        2,
        {
          "code": 150,
          "tabWidth": 2,
          "ignoreUrls": true
        }
      ],
      "no-bitwise": [2],
      "no-console": "off",
      "no-nested-ternary": [2],
      "no-param-reassign": [2,{"props": false}],
      "no-plusplus": [2],
      "no-restricted-exports": [2, {"restrictDefaultExports": {"defaultFrom": false}}],
      "no-restricted-syntax": [2],
      "no-underscore-dangle": [2],
      "no-unused-vars": ["error", {"caughtErrors": "none", "ignoreRestSiblings": true}],
      "no-useless-assignment": "off",
      "object-curly-spacing": [2, "never"],
      "react/destructuring-assignment": [0],
      "react/display-name": [0],
      "react/forbid-prop-types": [
      2,
      {
        "forbid": [],
        "checkContextTypes": false,
        "checkChildContextTypes": false
      }
    ],
      "react/jsx-filename-extension": [1, {"extensions": [".js", ".jsx"]}],
      "react/jsx-indent": "off",
      "react/jsx-one-expression-per-line": [0, {"allow": "single-child"}],
      "react/jsx-props-no-spreading": [0],
      "react/prop-types": [0],
      "react/require-default-props": [
      1,
      {
        "forbidDefaultForRequired": true,
        "ignoreFunctionalComponents": true
      }
    ],
      "react/state-in-constructor": [0],
      "camelcase": ["off", {}]
    },
  }
]);
