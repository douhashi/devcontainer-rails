export default {
  testEnvironment: 'jsdom',
  testMatch: [
    '<rootDir>/app/frontend/**/*.test.js',
    '<rootDir>/app/frontend/**/*.spec.js'
  ],
  transform: {},
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/app/frontend/$1'
  }
}