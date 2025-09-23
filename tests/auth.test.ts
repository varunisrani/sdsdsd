import { describe, it, expect, beforeEach, afterEach } from 'vitest';

describe('GitHub Access Control', () => {
  // Save original env
  let originalUsers: string | undefined;
  let originalOrg: string | undefined;

  beforeEach(() => {
    originalUsers = process.env.ALLOWED_GITHUB_USERS;
    originalOrg = process.env.ALLOWED_GITHUB_ORG;
  });

  afterEach(() => {
    process.env.ALLOWED_GITHUB_USERS = originalUsers;
    process.env.ALLOWED_GITHUB_ORG = originalOrg;
  });

  // GitHub user validation function extracted from server
  function isGithubUserAllowed(githubUser: any): boolean {
    if (!githubUser?.login) return false;

    const username = githubUser.login.toLowerCase();
    const allowedGithubUsers = process.env.ALLOWED_GITHUB_USERS?.split(',').map(u => u.trim().toLowerCase()) || [];
    const allowedGithubOrg = process.env.ALLOWED_GITHUB_ORG?.trim().toLowerCase() || '';

    // If no restrictions configured, allow all GitHub users
    if (allowedGithubUsers.length === 0 && !allowedGithubOrg) return true;

    // Check username allowlist
    if (allowedGithubUsers.length > 0 && allowedGithubUsers.includes(username)) {
      return true;
    }

    // Check organization membership (basic implementation via company field)
    if (allowedGithubOrg && githubUser.company) {
      const userOrg = githubUser.company.toLowerCase().replace(/[@\s]/g, '');
      return userOrg.includes(allowedGithubOrg);
    }

    return false;
  }

  it('rejects invalid GitHub user data', () => {
    expect(isGithubUserAllowed(null)).toBe(false);
    expect(isGithubUserAllowed({})).toBe(false);
    expect(isGithubUserAllowed({ id: 123 })).toBe(false);
    expect(isGithubUserAllowed({ login: '' })).toBe(false);
  });

  it('allows any valid GitHub user when no restrictions', () => {
    delete process.env.ALLOWED_GITHUB_USERS;
    delete process.env.ALLOWED_GITHUB_ORG;

    expect(isGithubUserAllowed({ login: 'alice', id: 123 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'bob', id: 456 })).toBe(true);
  });

  it('enforces GitHub user allowlist', () => {
    process.env.ALLOWED_GITHUB_USERS = 'alice,bob';
    delete process.env.ALLOWED_GITHUB_ORG;

    expect(isGithubUserAllowed({ login: 'alice', id: 123 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'bob', id: 456 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'charlie', id: 789 })).toBe(false);
    expect(isGithubUserAllowed({ login: 'dave', id: 101 })).toBe(false);
  });

  it('enforces GitHub organization allowlist', () => {
    delete process.env.ALLOWED_GITHUB_USERS;
    process.env.ALLOWED_GITHUB_ORG = 'mycompany';

    expect(isGithubUserAllowed({ login: 'alice', id: 123, company: 'MyCompany' })).toBe(true);
    expect(isGithubUserAllowed({ login: 'bob', id: 456, company: '@mycompany' })).toBe(true);
    expect(isGithubUserAllowed({ login: 'charlie', id: 789, company: 'OtherCompany' })).toBe(false);
    expect(isGithubUserAllowed({ login: 'dave', id: 101 })).toBe(false);
  });

  it('is case-insensitive', () => {
    process.env.ALLOWED_GITHUB_USERS = 'alice';

    expect(isGithubUserAllowed({ login: 'Alice', id: 123 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'ALICE', id: 123 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'alice', id: 123 })).toBe(true);
  });

  it('handles whitespace in configuration', () => {
    process.env.ALLOWED_GITHUB_USERS = ' alice , bob ';

    expect(isGithubUserAllowed({ login: 'alice', id: 123 })).toBe(true);
    expect(isGithubUserAllowed({ login: 'bob', id: 456 })).toBe(true);
  });
});