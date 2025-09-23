import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('Email Access Control', () => {
  // Save original env
  let originalEmails: string | undefined;
  let originalDomains: string | undefined;

  beforeEach(() => {
    originalEmails = process.env.ALLOWED_EMAILS;
    originalDomains = process.env.ALLOWED_DOMAINS;
  });

  afterEach(() => {
    process.env.ALLOWED_EMAILS = originalEmails;
    process.env.ALLOWED_DOMAINS = originalDomains;
  });

  // Simple email validation function extracted from server
  function isEmailAllowed(email: string): boolean {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return false;

    const normalizedEmail = email.toLowerCase().trim();
    const allowedEmails = process.env.ALLOWED_EMAILS?.split(',').map(e => e.trim().toLowerCase()) || [];
    const allowedDomains = process.env.ALLOWED_DOMAINS?.split(',').map(d => d.trim().toLowerCase()) || [];

    // If no restrictions, allow all
    if (allowedEmails.length === 0 && allowedDomains.length === 0) return true;

    // Check email or domain
    return allowedEmails.includes(normalizedEmail) ||
           allowedDomains.includes(normalizedEmail.split('@')[1]);
  }

  it('rejects invalid email format', () => {
    expect(isEmailAllowed('notanemail')).toBe(false);
    expect(isEmailAllowed('missing@domain')).toBe(false);
    expect(isEmailAllowed('@nodomain.com')).toBe(false);
    expect(isEmailAllowed('spaces in@email.com')).toBe(false);
  });

  it('allows any valid email when no restrictions', () => {
    delete process.env.ALLOWED_EMAILS;
    delete process.env.ALLOWED_DOMAINS;

    expect(isEmailAllowed('anyone@example.com')).toBe(true);
    expect(isEmailAllowed('test@test.org')).toBe(true);
  });

  it('enforces email allowlist', () => {
    process.env.ALLOWED_EMAILS = 'alice@company.com,bob@company.com';
    delete process.env.ALLOWED_DOMAINS;

    expect(isEmailAllowed('alice@company.com')).toBe(true);
    expect(isEmailAllowed('bob@company.com')).toBe(true);
    expect(isEmailAllowed('charlie@company.com')).toBe(false);
    expect(isEmailAllowed('alice@other.com')).toBe(false);
  });

  it('enforces domain allowlist', () => {
    delete process.env.ALLOWED_EMAILS;
    process.env.ALLOWED_DOMAINS = 'company.com,partner.org';

    expect(isEmailAllowed('anyone@company.com')).toBe(true);
    expect(isEmailAllowed('someone@partner.org')).toBe(true);
    expect(isEmailAllowed('user@other.com')).toBe(false);
  });

  it('is case-insensitive', () => {
    process.env.ALLOWED_EMAILS = 'alice@company.com';

    expect(isEmailAllowed('Alice@Company.com')).toBe(true);
    expect(isEmailAllowed('ALICE@COMPANY.COM')).toBe(true);
    expect(isEmailAllowed('alice@company.com')).toBe(true);
  });

  it('handles whitespace in configuration', () => {
    process.env.ALLOWED_EMAILS = ' alice@company.com , bob@company.com ';

    expect(isEmailAllowed('alice@company.com')).toBe(true);
    expect(isEmailAllowed('bob@company.com')).toBe(true);
  });
});