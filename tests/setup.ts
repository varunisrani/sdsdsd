import { beforeAll, afterAll, vi } from 'vitest';

// Set test environment
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.ALLOW_LOCAL = 'true';
  process.env.CLAUDE_CODE_OAUTH_TOKEN = 'test-oauth-token';
  process.env.CLAUDE_CODE_SDK_CONTAINER_API_KEY = 'test-api-key';
  process.env.SESSION_SECRET = 'test-secret-key-for-jwt';
});

// Clean up
afterAll(() => {
  vi.restoreAllMocks();
});