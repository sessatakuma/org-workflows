/** @type {import('@commitlint/types').UserConfig} */
module.exports = {

  /**
   * Please refer to the official documentation for detailed explanations of each configuration option:
   * https://commitlint.js.org/reference/rules.html
   */
  
  /**
   * Extends:
   * By extending '@commitlint/config-conventional', we inherit a set of standard rules
   * that align with the Conventional Commits specification.
   */
  extends: ['@commitlint/config-conventional'],
  
  /**
   * Rules:
   * Here, you can override or add rules.
   * The format of a rule is: 'rule-name': [Level, Applicability, Value]
   * - Level: 0 = disable, 1 = warning, 2 = error
   * - Applicability: 'always' or 'never'
   * - Value: the specific content of the rule
   */
  rules: {
    // The maximum length for 'header', 'body', and 'footer' is set to 75 characters.
    'header-max-length': [2, 'always', 75],
    'body-max-length': [2, 'always', 75],
    'footer-max-length': [2, 'always', 75],

    // Ensure 'scope' is always in lower-case (e.g., 'feat(login)' instead of 'feat(Login)')
    'scope-case': [2, 'always', 'lower-case'],
    
    // Ensure 'subject' does not end with a period (Good: 'add login button' / Bad: 'add login button.')
    'subject-full-stop': [2, 'never', '.'],

    // 'subject' must start with a lowercase letter (e.g., 'fix: add login button')
    'subject-case': [
      2,
      'always',
      'lower-case',
    ],
  },
};