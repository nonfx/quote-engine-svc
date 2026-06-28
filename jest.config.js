/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
    preset: "ts-jest",
    testEnvironment: "node",
    roots: ["<rootDir>/test"],
    collectCoverageFrom: ["src/**/*.ts", "!src/server.ts"],
    coverageThreshold: {
        global: { branches: 80, functions: 90, lines: 90, statements: 90 }
    }
};
