/**
 * SecretMsg Android & Native Mobile Bridge
 * Seamless integration between SecretMsg web views and the native Android runtime.
 * Provides hardware back button navigation, status/navigation bar theming,
 * native share sheet invocation, tactile haptic feedback, and deep link routing.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.SecretMsgNative = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  var isCapacitor = Boolean(
    typeof window !== 'undefined' &&
    window.Capacitor &&
    typeof window.Capacitor.isNativePlatform === 'function' &&
    window.Capacitor.isNativePlatform()
  );

  var Plugins = (isCapacitor && window.Capacitor.Plugins) || {};
  var App = Plugins.App;
  var StatusBar = Plugins.StatusBar;
  var SplashScreen = Plugins.SplashScreen;
  var Haptics = Plugins.Haptics;
  var Share = Plugins.Share;
  var Clipboard = Plugins.Clipboard;
  var PushNotifications = Plugins.PushNotifications;

  var lastBackPressTime = 0;

  // --------------------------------------------------------------------------
  // Haptics Helper
  // --------------------------------------------------------------------------
  var haptics = {
    tap: function () {
      if (Haptics && Haptics.impact) {
        Haptics.impact({ style: 'LIGHT' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate(10);
      }
    },
    medium: function () {
      if (Haptics && Haptics.impact) {
        Haptics.impact({ style: 'MEDIUM' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate(25);
      }
    },
    heavy: function () {
      if (Haptics && Haptics.impact) {
        Haptics.impact({ style: 'HEAVY' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate(40);
      }
    },
    success: function () {
      if (Haptics && Haptics.notification) {
        Haptics.notification({ type: 'SUCCESS' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate([15, 30, 15]);
      }
    },
    warning: function () {
      if (Haptics && Haptics.notification) {
        Haptics.notification({ type: 'WARNING' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate([20, 50, 20]);
      }
    },
    error: function () {
      if (Haptics && Haptics.notification) {
        Haptics.notification({ type: 'ERROR' }).catch(function () {});
      } else if (navigator.vibrate) {
        navigator.vibrate([30, 40, 30, 40, 30]);
      }
    }
  };

  // --------------------------------------------------------------------------
  // Status Bar & System Bar Styling
  // --------------------------------------------------------------------------
  function syncStatusBar(themeName) {
    if (!StatusBar) return;

    var theme = themeName;
    if (!theme && window.SecretMsgTheme && typeof window.SecretMsgTheme.get === 'function') {
      theme = window.SecretMsgTheme.get();
    }
    if (!theme) {
      theme = document.documentElement.classList.contains('light') ? 'light' : 'dark';
    }

    try {
      if (theme === 'light') {
        // Light theme: white status bar with dark icons
        StatusBar.setStyle({ style: 'LIGHT' }).catch(function () {});
        StatusBar.setBackgroundColor({ color: '#FFFFFF' }).catch(function () {});
      } else {
        // Dark theme: deep navy/black status bar with light icons
        StatusBar.setStyle({ style: 'DARK' }).catch(function () {});
        StatusBar.setBackgroundColor({ color: '#0B0E14' }).catch(function () {});
      }
    } catch (e) {
      console.warn('[SecretMsgNative] StatusBar style update error:', e);
    }
  }

  // --------------------------------------------------------------------------
  // Native Share Sheet
  // --------------------------------------------------------------------------
  async function share(options) {
    options = options || {};
    var title = options.title || 'SecretMsg';
    var text = options.text || 'Send me an anonymous question or TBH on SecretMsg!';
    var url = options.url || window.location.href;
    var dialogTitle = options.dialogTitle || 'Share via SecretMsg';

    haptics.tap();

    if (Share && Share.share) {
      try {
        await Share.share({
          title: title,
          text: text,
          url: url,
          dialogTitle: dialogTitle
        });
        haptics.success();
        return true;
      } catch (err) {
        if (err && err.message && err.message.toLowerCase().includes('canceled')) {
          return false;
        }
        console.warn('[SecretMsgNative] Capacitor share error, falling back to web:', err);
      }
    }

    if (navigator.share) {
      try {
        await navigator.share({ title: title, text: text, url: url });
        haptics.success();
        return true;
      } catch (e) {
        if (e && e.name === 'AbortError') return false;
      }
    }

    // Fallback: copy link to clipboard and notify
    try {
      await copyToClipboard(url);
      if (typeof window.showToast === 'function') {
        window.showToast('Link copied to clipboard!');
      }
      return true;
    } catch (e) {
      console.error('[SecretMsgNative] Fallback copy failed:', e);
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // Clipboard
  // --------------------------------------------------------------------------
  async function copyToClipboard(text) {
    haptics.tap();
    if (Clipboard && Clipboard.write) {
      try {
        await Clipboard.write({ string: text });
        haptics.success();
        return true;
      } catch (err) {
        console.warn('[SecretMsgNative] Capacitor clipboard write failed, using navigator:', err);
      }
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      haptics.success();
      return true;
    }

    // Legacy fallback
    var textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.opacity = '0';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    var success = document.execCommand('copy');
    document.body.removeChild(textArea);
    if (success) haptics.success();
    return success;
  }

  // --------------------------------------------------------------------------
  // Hardware Back Button Navigation Handling
  // --------------------------------------------------------------------------
  function findActiveModal() {
    // Check known modal IDs and common modal structures across SecretMsg pages
    var modalSelectors = [
      '#donation-modal:not(.hidden)',
      '#story-card-modal:not(.hidden)',
      '#action-modal:not(.hidden)',
      '#claim-modal:not(.hidden)',
      '#report-modal:not(.hidden)',
      '#custom-word-modal:not(.hidden)',
      '#mobile-menu:not(.hidden)',
      '[role="dialog"]:not(.hidden)',
      '.modal-backdrop:not(.hidden)'
    ];

    for (var i = 0; i < modalSelectors.length; i++) {
      var el = document.querySelector(modalSelectors[i]);
      if (el && window.getComputedStyle(el).display !== 'none') {
        return el;
      }
    }
    return null;
  }

  function dismissActiveModal(modalEl) {
    if (!modalEl) return false;

    // Check for explicit close buttons inside modal
    var closeBtn = modalEl.querySelector('[data-close-modal], .close-modal-btn, [onclick*="closeModal"]');
    if (closeBtn) {
      closeBtn.click();
      haptics.tap();
      return true;
    }

    // Check for global close functions
    if (typeof window.closeModal === 'function') {
      window.closeModal();
      haptics.tap();
      return true;
    }
    if (typeof window.closeDonationModal === 'function') {
      window.closeDonationModal();
      haptics.tap();
      return true;
    }

    // Default: hide element
    modalEl.classList.add('hidden');
    haptics.tap();
    return true;
  }

  function handleBackButton() {
    // 1. If an active modal is open, dismiss it
    var activeModal = findActiveModal();
    if (activeModal && dismissActiveModal(activeModal)) {
      return;
    }

    // 2. Check if we can navigate back in the browser history
    var currentPath = window.location.pathname;
    var isRoot = currentPath === '/' ||
                 currentPath.endsWith('/index.html') ||
                 currentPath.endsWith('/landing.html') ||
                 currentPath === '';

    if (!isRoot && window.history.length > 1) {
      haptics.tap();
      window.history.back();
      return;
    }

    // 3. If at root, double-tap to exit to prevent accidental app close
    var now = Date.now();
    if (now - lastBackPressTime < 2000) {
      if (App && App.exitApp) {
        App.exitApp();
      }
    } else {
      lastBackPressTime = now;
      haptics.warning();
      if (typeof window.showToast === 'function') {
        window.showToast('Press back again to exit SecretMsg');
      } else {
        var toast = document.createElement('div');
        toast.className = 'toast-notice';
        toast.textContent = 'Press back again to exit SecretMsg';
        document.body.appendChild(toast);
        setTimeout(function () {
          if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 1800);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Deep Link Routing
  // --------------------------------------------------------------------------
  function handleDeepLinkUrl(rawUrl) {
    if (!rawUrl) return;

    try {
      var parsed = new URL(rawUrl);
      var pathname = parsed.pathname || '';
      var search = parsed.search || '';

      // Handle custom scheme secretmsg://...
      if (parsed.protocol === 'secretmsg:') {
        var host = parsed.host;
        var path = pathname.replace(/^\/+/, '');
        if (host === 'compose' || path.startsWith('compose')) {
          var user = parsed.searchParams.get('user') || parsed.searchParams.get('u');
          window.location.href = 'compose.html' + (user ? '?user=' + encodeURIComponent(user) : '');
          return;
        }
        if (host === 'inbox' || path.startsWith('inbox')) {
          window.location.href = 'inbox.html';
          return;
        }
        if (host === 'dice' || path.startsWith('dice')) {
          window.location.href = 'dice.html';
          return;
        }
        if (host === 'profile' || path.startsWith('profile')) {
          var u = path.split('/')[1] || parsed.searchParams.get('u');
          window.location.href = 'profile.html' + (u ? '?user=' + encodeURIComponent(u) : '');
          return;
        }
      }

      // Handle https://secretmsg.net or https://m.secretmsg.net
      var segments = pathname.replace(/^\/+/, '').split('/');
      var firstSegment = segments[0] || '';

      // Clean leading @ if present
      if (firstSegment.startsWith('@')) {
        var cleanHandle = firstSegment.slice(1);
        window.location.href = 'compose.html?user=' + encodeURIComponent(cleanHandle);
        return;
      }

      // If user profile link e.g. /alex
      var reserved = ['inbox.html', 'inbox', 'settings.html', 'settings', 'supporters.html', 'supporters',
                      'dice.html', 'dice', 'sticker-studio.html', 'sticker-studio', 'login.html', 'login',
                      'compose.html', 'compose', 'about.html', 'about', 'privacy.html', 'terms.html', 'faq.html',
                      'safety.html', 'safety-tools.html', 'safety-resources.html', 'demo.html'];

      if (firstSegment && !reserved.includes(firstSegment) && !firstSegment.includes('.')) {
        window.location.href = 'compose.html?user=' + encodeURIComponent(firstSegment);
        return;
      }

      // Otherwise direct navigation
      if (pathname && pathname !== window.location.pathname) {
        window.location.href = pathname + search;
      }
    } catch (e) {
      console.warn('[SecretMsgNative] Deep link parse error:', e);
    }
  }

  // --------------------------------------------------------------------------
  // Lifecycle Initialization
  // --------------------------------------------------------------------------
  function init() {
    // 1. Sync status bar immediately and on theme changes
    syncStatusBar();
    window.addEventListener('secretmsg-theme-change', function (e) {
      var t = e && e.detail && e.detail.theme;
      syncStatusBar(t);
    });

    // 2. Hide native splash screen once DOM is interactable
    if (SplashScreen && SplashScreen.hide) {
      SplashScreen.hide({ fadeOutDuration: 300 }).catch(function () {});
    }

    // 3. Register Hardware Back Button listener if on native platform
    if (App && App.addListener) {
      App.addListener('backButton', function (data) {
        handleBackButton();
      });

      // 4. Register Deep Link appUrlOpen listener
      App.addListener('appUrlOpen', function (data) {
        if (data && data.url) {
          handleDeepLinkUrl(data.url);
        }
      });
    }

    // 5. Initialize push notification listeners
    notifications.init();

    // 6. Enhance interactive touch elements with subtle haptic feedback
    document.addEventListener('click', function (e) {
      var target = e.target.closest('button, a, [data-haptic]');
      if (!target) return;
      var hapticType = target.getAttribute('data-haptic');
      if (hapticType === 'success') {
        haptics.success();
      } else if (hapticType === 'medium') {
        haptics.medium();
      } else if (hapticType === 'heavy') {
        haptics.heavy();
      } else if (hapticType !== 'none' && target.tagName === 'BUTTON') {
        haptics.tap();
      }
    }, { passive: true });
  }

  // --------------------------------------------------------------------------
  // Push Notifications (Firebase Cloud Messaging)
  // --------------------------------------------------------------------------
  var notifications = {
    isSupported: function () {
      return Boolean(PushNotifications);
    },

    requestPermission: async function () {
      if (!PushNotifications) {
        if ('Notification' in window) {
          try {
            var perm = await Notification.requestPermission();
            return perm === 'granted';
          } catch (e) {
            return false;
          }
        }
        return false;
      }

      try {
        var status = await PushNotifications.checkPermissions();
        if (status.receive === 'prompt') {
          status = await PushNotifications.requestPermissions();
        }
        if (status.receive === 'granted') {
          await notifications.createChannel();
          await PushNotifications.register();
          haptics.success();
          return true;
        }
        return false;
      } catch (e) {
        console.warn('[SecretMsgNative] Push permission request failed:', e);
        return false;
      }
    },

    createChannel: async function () {
      if (!PushNotifications || !PushNotifications.createChannel) return;
      try {
        await PushNotifications.createChannel({
          id: 'secretmsg_messages_channel',
          name: 'SecretMsg Anonymous Messages',
          description: 'Instant alerts for received anonymous messages and thread replies',
          importance: 5,
          visibility: 1,
          sound: 'default',
          vibration: true,
          lights: true,
          lightColor: '#38BDF8'
        });
      } catch (e) {
        console.warn('[SecretMsgNative] Error creating notification channel:', e);
      }
    },

    init: function () {
      if (!PushNotifications) return;

      PushNotifications.addListener('registration', function (token) {
        console.log('[SecretMsgNative] FCM Registration Token:', token.value);
        try {
          localStorage.setItem('secretmsg_fcm_token', token.value);
        } catch (e) {}
      });

      PushNotifications.addListener('registrationError', function (error) {
        console.warn('[SecretMsgNative] FCM Registration Error:', error);
      });

      PushNotifications.addListener('pushNotificationReceived', function (notification) {
        console.log('[SecretMsgNative] Push Received:', notification);
        haptics.success();
        if (typeof window.showToast === 'function') {
          window.showToast(notification.title || 'New anonymous message received!');
        }
      });

      PushNotifications.addListener('pushNotificationActionPerformed', function (action) {
        console.log('[SecretMsgNative] Push Action Performed:', action);
        var data = (action && action.notification && action.notification.data) || {};
        if (data.url) {
          handleDeepLinkUrl(data.url);
        } else if (data.messageId) {
          window.location.href = 'message-detail.html?id=' + encodeURIComponent(data.messageId);
        } else {
          window.location.href = 'inbox.html';
        }
      });
    }
  };

  // --------------------------------------------------------------------------
  // Google Pay Integration (Android Mobile App)
  // --------------------------------------------------------------------------
  var payments = {
    isAndroid: function () {
      return isCapacitor || /Android/i.test(navigator.userAgent);
    },

    loadGooglePaySdk: function () {
      return new Promise(function (resolve, reject) {
        if (typeof window.google !== 'undefined' && window.google.payments && window.google.payments.api) {
          return resolve();
        }
        var existing = document.querySelector('script[src*="pay.google.com"]');
        if (existing) {
          existing.addEventListener('load', function () { resolve(); });
          return;
        }
        var script = document.createElement('script');
        script.src = 'https://pay.google.com/gp/p/js/pay.js';
        script.async = true;
        script.onload = function () { resolve(); };
        script.onerror = function () { reject(new Error('Failed to load Google Pay SDK')); };
        document.head.appendChild(script);
      });
    },

    getBaseGooglePayRequest: function () {
      return {
        apiVersion: 2,
        apiVersionMinor: 0,
        allowedPaymentMethods: [
          {
            type: 'CARD',
            parameters: {
              allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
              allowedCardNetworks: ['MASTERCARD', 'VISA', 'AMEX', 'DISCOVER']
            },
            tokenizationSpecification: {
              type: 'PAYMENT_GATEWAY',
              parameters: {
                gateway: 'example',
                gatewayMerchantId: 'secretmsg_merchant'
              }
            }
          }
        ]
      };
    },

    isGooglePayAvailable: async function () {
      try {
        await payments.loadGooglePaySdk();
        var client = new google.payments.api.PaymentsClient({
          environment: 'TEST'
        });
        var isReadyToPayRequest = {
          apiVersion: 2,
          apiVersionMinor: 0,
          allowedPaymentMethods: [
            {
              type: 'CARD',
              parameters: {
                allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
                allowedCardNetworks: ['MASTERCARD', 'VISA', 'AMEX', 'DISCOVER']
              }
            }
          ]
        };
        var response = await client.isReadyToPay(isReadyToPayRequest);
        return Boolean(response && response.result);
      } catch (e) {
        console.warn('[SecretMsgNative] Google Pay isReadyToPay error:', e);
        return false;
      }
    },

    payWithGoogle: async function (options) {
      options = options || {};
      var feature = options.feature || 'badge';
      var title = options.title || 'Supporter Perk';
      var amount = Number(options.amount || 2.0).toFixed(2);

      haptics.tap();

      try {
        await payments.loadGooglePaySdk();
        var client = new google.payments.api.PaymentsClient({
          environment: 'TEST'
        });

        var paymentDataRequest = Object.assign({}, payments.getBaseGooglePayRequest(), {
          merchantInfo: {
            merchantName: 'SecretMsg'
          },
          transactionInfo: {
            totalPriceStatus: 'FINAL',
            totalPrice: amount,
            currencyCode: 'USD',
            countryCode: 'US'
          }
        });

        // Present native Google Pay bottom sheet
        var paymentData = await client.loadPaymentData(paymentDataRequest);
        haptics.success();

        // Submit token to the backend API to grant the perk
        if (window.SecretMsgAPI && typeof window.SecretMsgAPI.submitGooglePayDonation === 'function') {
          var res = await window.SecretMsgAPI.submitGooglePayDonation(feature, paymentData, Number(amount));
          return res;
        }

        return { success: true, paymentData: paymentData };
      } catch (err) {
        if (err && err.statusCode === 'CANCELED') {
          return { canceled: true };
        }
        console.error('[SecretMsgNative] Google Pay error:', err);
        throw err;
      }
    }
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  return {
    isNative: isCapacitor,
    haptics: haptics,
    share: share,
    copyToClipboard: copyToClipboard,
    syncStatusBar: syncStatusBar,
    notifications: notifications,
    payments: payments,
    exitApp: function () {
      if (App && App.exitApp) App.exitApp();
    }
  };
});
