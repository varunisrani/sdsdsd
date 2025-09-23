import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { serve } from '@hono/node-server';
import request from 'supertest';
import { app } from '../server';

// Mock the Claude Code SDK
vi.mock('@anthropic-ai/claude-code', () => ({
  query: vi.fn(() => {
    return (async function* () {
      yield {
        type: 'assistant',
        message: {
          content: [{ type: 'text', text: 'Mocked response' }]
        }
      };
    })();
  })
}));

describe('API Tests', () => {
  let server: any;
  let address: string;

  beforeEach(() => {
    // Create a real server for testing
    server = serve({
      fetch: app.fetch,
      port: 0 // Random port
    });
    const port = server.address().port;
    address = `http://localhost:${port}`;
  });

  afterEach(() => {
    return new Promise((resolve) => {
      server.close(resolve);
    });
  });

  it('should return healthy status', async () => {
    const res = await request(address)
      .get('/health')
      .expect(200);

    expect(res.body).toMatchObject({
      status: 'healthy',
      hasToken: true,
      sdkLoaded: true
    });
  });

  it('should require API key for /query', async () => {
    const res = await request(address)
      .post('/query')
      .send({ prompt: 'Hello' })
      .expect(401);

    expect(res.body.error).toBe('Unauthorized - Invalid or missing API key');
  });

  it('should accept valid API key', async () => {
    const res = await request(address)
      .post('/query')
      .set('X-API-Key', 'test-api-key')
      .send({ prompt: 'Hello' })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.response).toBe('Mocked response');
  });

  it('should validate prompt is provided', async () => {
    const res = await request(address)
      .post('/query')
      .set('X-API-Key', 'test-api-key')
      .send({})
      .expect(400);

    expect(res.body.error).toBe('Prompt is required');
  });

  it('should validate prompt is a string', async () => {
    const res = await request(address)
      .post('/query')
      .set('X-API-Key', 'test-api-key')
      .send({ prompt: 123 })
      .expect(400);

    expect(res.body.error).toBe('Prompt must be a string');
  });

  it('should reject very long prompts', async () => {
    const longPrompt = 'a'.repeat(100001);
    const res = await request(address)
      .post('/query')
      .set('X-API-Key', 'test-api-key')
      .send({ prompt: longPrompt })
      .expect(400);

    expect(res.body.error).toBe('Prompt too long. Maximum 100000 characters');
  });
});