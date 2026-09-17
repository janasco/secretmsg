/**
 * SecretMsg Platform Input Sanitization & Validation Engine
 * Enforces robust XSS prevention, slug sanitization, and the >= 4 character username/board link constraint.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.SecretMsgSanitize = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // System & Reserved Routing Slugs that cannot be claimed as user board links
  const RESERVED_SLUGS = new Set([
    'admin', 'api', 'login', 'logout', 'signin', 'signup', 'register',
    'faq', 'faqs', 'help', 'how-it-works', 'about', 'about-us', 'who-we-are',
    'privacy', 'terms', 'cookies', 'cookie-policy', 'disclaimer', 'contact', 'contact-us',
    'safety', 'child-safety', 'child-safety-policy', 'approach-to-safety',
    'our-approach-to-safety', 'guide-to-online-safety', 'online-safety-guide',
    'our-guide-to-online-safety', 'community-guidelines', 'our-community-guidelines',
    'safety-tools', 'our-safety-tools', 'resources', 'our-resources',
    'safety-resources', 'crisis-resources',
    'demo', 'dice', 'sticker-studio', 'inbox', 'profile', 'settings',
    'supporters', 'compose', 'p', 'css', 'js', 'assets', 'static', 'images',
    'favicon.ico', 'robots.txt', 'sitemap.xml', '404', 'null', 'undefined',
    'index', 'landing', 'home', 'root'
  ]);

  /**
   * Escape HTML entities to prevent Cross-Site Scripting (XSS)
   */
  function escapeHtml(str) {
    if (typeof str !== 'string') return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  /**
   * Strip HTML tags and dangerous scripts
   */
  function stripHtml(str) {
    if (typeof str !== 'string') return '';
    return str.replace(/<[^>]*>?/gm, '').trim();
  }

  /**
   * Sanitize a board slug or username into safe URL path component
   * Format: lowercase a-z, 0-9, underscores, hyphens, and dots
   */
  function sanitizeUsername(input) {
    if (!input || typeof input !== 'string') return '';
    let clean = input.trim();
    // Remove leading @ if present
    clean = clean.replace(/^@+/, '');
    // Remove full protocol/domain if pasted e.g. https://secretmsg.net/alex -> alex
    clean = clean.replace(/^https?:\/\/[^\/]+\//i, '');
    clean = clean.replace(/^[^\/]*secretmsg\.net\//i, '');
    // Convert to lowercase
    clean = clean.toLowerCase();
    // Keep only alphanumeric, underscores, hyphens, dots
    clean = clean.replace(/[^a-z0-9_\-\.]/g, '');
    // Collapse consecutive dots/hyphens/underscores
    clean = clean.replace(/\.{2,}/g, '.').replace(/-{2,}/g, '-').replace(/_{2,}/g, '_');
    // Strip leading/trailing dots and hyphens
    clean = clean.replace(/^[\.\-]+|[\.\-]+$/g, '');
    return clean;
  }

  /**
   * Validate board link or username against platform constraints
   * Constraint: Must be at least 4 characters long (reject if under 4 chars).
   */
  function validateUsername(input) {
    const raw = (input || '').trim();
    if (!raw) {
      return {
        valid: false,
        sanitized: '',
        error: 'Board link or username cannot be empty.'
      };
    }

    const sanitized = sanitizeUsername(raw);

    if (sanitized.length < 4) {
      return {
        valid: false,
        sanitized,
        error: 'Board link or username cannot be less than 4 characters (must be at least 4 characters).'
      };
    }

    if (sanitized.length > 30) {
      return {
        valid: false,
        sanitized: sanitized.slice(0, 30),
        error: 'Board link or username cannot exceed 30 characters.'
      };
    }

    if (RESERVED_SLUGS.has(sanitized)) {
      return {
        valid: false,
        sanitized,
        error: `"${sanitized}" is a reserved platform name. Please choose a different board name.`
      };
    }

    return {
      valid: true,
      sanitized,
      error: null
    };
  }

  /**
   * Sanitize Display Name
   */
  function sanitizeDisplayName(input) {
    if (!input || typeof input !== 'string') return '';
    let clean = stripHtml(input);
    clean = clean.replace(/[\u0000-\u001F\u007F-\u009F]/g, ''); // strip control characters
    clean = clean.replace(/\s+/g, ' ').trim();
    if (clean.length > 40) {
      clean = clean.slice(0, 40).trim();
    }
    return clean;
  }

  /**
   * Validate Display Name
   */
  function validateDisplayName(input) {
    const clean = sanitizeDisplayName(input);
    if (!clean) {
      return {
        valid: false,
        sanitized: '',
        error: 'Display name cannot be empty.'
      };
    }
    if (clean.length < 4) {
      return {
        valid: false,
        sanitized: clean,
        error: 'Display name cannot be less than 4 characters (must be at least 4 characters).'
      };
    }
    return {
      valid: true,
      sanitized: clean,
      error: null
    };
  }

  /**
   * Sanitize anonymous message text (XSS defense + length boundaries)
   */
  function sanitizeMessageText(input, maxLength = 500) {
    if (!input || typeof input !== 'string') return '';
    let clean = stripHtml(input);
    clean = clean.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '');
    clean = clean.trim();
    if (clean.length > maxLength) {
      clean = clean.slice(0, maxLength);
    }
    return clean;
  }

  /**
   * Validate password strength
   */
  function validatePassword(input) {
    const pwd = (input || '').trim();
    if (!pwd || pwd.length < 6) {
      return {
        valid: false,
        error: 'Password must be at least 6 characters long.'
      };
    }
    if (pwd.length > 128) {
      return {
        valid: false,
        error: 'Password is too long (maximum 128 characters).'
      };
    }
    return {
      valid: true,
      error: null
    };
  }

  return {
    escapeHtml,
    stripHtml,
    sanitizeUsername,
    validateUsername,
    sanitizeDisplayName,
    validateDisplayName,
    sanitizeMessageText,
    validatePassword,
    RESERVED_SLUGS
  };
});
