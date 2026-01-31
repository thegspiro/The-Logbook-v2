/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './onboarding_app/templates/**/*.html',
    './onboarding_app/static/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: 'var(--color-primary)',
          light: 'var(--color-primary-light)',
          dark: 'var(--color-primary-dark)',
        },
        secondary: {
          DEFAULT: 'var(--color-secondary)',
          light: 'var(--color-secondary-light)',
          dark: 'var(--color-secondary-dark)',
        },
      },
    },
  },
  plugins: [],
}
