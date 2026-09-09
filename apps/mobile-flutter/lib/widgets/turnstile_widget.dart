import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../api/config.dart';

/// Bot-check widget rendered inside a WebView.
///
/// The WebView loads the real public origin (`https://secretmsg.net`) so the
/// The widget is created on an allowed hostname, then inlines a minimal
/// page with the widget mounted explicitly. The minted token is delivered to
/// Flutter through a JavaScript channel.
class TurnstileWidget extends StatefulWidget {
  final void Function(String token)? onToken;
  final void Function(String? error)? onError;
  final double height;
  final int resetCount;

  /// Diagnostics-only: if no token arrives after a short delay, mount an
  /// invisible `execution: 'execute'` widget and call execute() automatically.
  final bool autoExecuteFallback;

  const TurnstileWidget({
    super.key,
    this.onToken,
    this.onError,
    this.height = 88,
    this.resetCount = 0,
    this.autoExecuteFallback = false,
  });

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final WebViewController _controller;
  String _status = 'Preparing verification…';
  bool _errored = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidWebViewController.enableDebugging(kDebugMode);
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF101322))
      ..setNavigationDelegate(
        NavigationDelegate(onPageFinished: (_) => _inject()),
      )
      ..addJavaScriptChannel(
        'TurnstileChannel',
        onMessageReceived: (message) {
          Map<String, dynamic> payload;
          try {
            payload = jsonDecode(message.message) as Map<String, dynamic>;
          } catch (_) {
            return;
          }
          final kind = payload['kind']?.toString();
          final value = payload['value']?.toString();
          if (kind == 'ready') {
            if (mounted) {
              setState(() {
                _ready = true;
                _status = 'Completing verification…';
              });
            }
          } else if (kind == 'token' && value != null && value.isNotEmpty) {
            if (mounted) {
              setState(() {
                _status = 'Verification passed';
                _errored = false;
                _ready = true;
              });
            }
            widget.onToken?.call(value);
          } else if (kind == 'expired' || kind == 'error') {
            if (mounted) {
              setState(() {
                _status = kind == 'expired'
                    ? 'Challenge expired — reloading…'
                    : 'Verification unavailable';
                _errored = true;
              });
            }
            widget.onError?.call(value ?? kind);
          }
        },
      );
    _controller.loadRequest(Uri.parse('$kPublicBaseUrl/'));
  }

  @override
  void didUpdateWidget(TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetCount != widget.resetCount) {
      _reset();
    }
  }

  void _reset() {
    if (mounted && _ready) {
      setState(() {
        _ready = false;
        _errored = false;
        _status = 'Completing verification…';
      });
      _controller.runJavaScript(
        'if (window.turnstile && window.__smTsInjected) { window.turnstile.reset(); window.TurnstileChannel.postMessage(JSON.stringify({kind:"expired"})); }',
      );
    }
  }

  void _inject() async {
    try {
      const sitekey = kTurnstileSiteKey;
      final autoExecute = widget.autoExecuteFallback ? 'true' : 'false';
      final script = '''
(function(){
  if (window.__smTsInjected) return;
  var log = function(msg){ try { console.log('SMTS:' + msg); } catch(e){} };
  window.__smTsGotToken = false;
  try {
    if (!document.body) throw new Error('no body');
    document.body.innerHTML = '';
    var d = document.createElement('div');
    d.id = 'sm-ts-widget';
    d.style.cssText = 'display:flex;align-items:center;justify-content:center;min-height:64px;';
    document.body.appendChild(d);
    log('INJECTED');

    var tryExecuteFallback = function(){
      if (window.__smTsGotToken || !window.turnstile) return;
      if (window.__smTsFbTried) return;
      window.__smTsFbTried = true;
      log('TRY_EXECUTE_FALLBACK');
      var d2 = document.createElement('div');
      d2.style.cssText = 'position:absolute;left:-10000px;top:-10000px;width:300px;height:65px;';
      document.body.appendChild(d2);
      try {
        var w2 = window.turnstile.render(d2, {
          sitekey: '$sitekey',
          theme: 'dark',
          execution: 'execute',
          appearance: 'execute',
          callback: function(token){
            log('CB2_TOKEN_LEN=' + (token ? token.length : 0));
            window.__smTsGotToken = true;
            window.TurnstileChannel.postMessage(JSON.stringify({kind:'token',value:token}));
          },
          'error-callback': function(code){
            log('CB2_ERROR=' + String(code));
          },
          action: 'send-anonymous-message'
        });
        log('RENDER2=' + (!!w2));
        setTimeout(function(){
          try {
            window.turnstile.execute(w2, {action:'send-anonymous-message'});
            log('EXECUTE_CALLED');
          } catch(e) {
            log('EXECUTE_THREW=' + String(e));
          }
        }, 800);
      } catch(e) {
        log('RENDER2_THREW=' + String(e));
      }
    };

    var loadTurnstile = function(){
      log('TURNSTILE_API_PRESENT=' + (!!window.turnstile));
      if (!window.turnstile) {
        window.TurnstileChannel.postMessage(JSON.stringify({kind:'error',value:'no-turnstile-api'}));
        log('ERROR_NO_API');
        return;
      }
      window.TurnstileChannel.postMessage(JSON.stringify({kind:'ready'}));
      var w;
      try {
        w = window.turnstile.render(d, {
          sitekey: '$sitekey',
          theme: 'dark',
          size: 'flexible',
          callback: function(token){
            log('CB_TOKEN_LEN=' + (token ? token.length : 0));
            window.__smTsGotToken = true;
            window.TurnstileChannel.postMessage(JSON.stringify({kind:'token',value:token}));
          },
          'expired-callback': function(){
            log('CB_EXPIRED');
            window.TurnstileChannel.postMessage(JSON.stringify({kind:'expired'}));
          },
          'error-callback': function(code){
            log('CB_ERROR=' + String(code));
            window.TurnstileChannel.postMessage(JSON.stringify({kind:'error',value:String(code)}));
          },
          action: 'send-anonymous-message'
        });
        log('RENDERED=' + (!!w));
        setTimeout(function(){
          var fs = document.querySelectorAll('iframe');
          var info = [];
          for (var i=0;i<fs.length;i++){
            var r = fs[i].getBoundingClientRect();
            info.push(i + ':' + r.left.toFixed(0) + ',' + r.top.toFixed(0) + ',' + r.width.toFixed(0) + ',' + r.height.toFixed(0));
          }
          log('IFRAMES=' + (info.length ? info.join('|') : 'none'));
          var divs = d.querySelectorAll('div, iframe');
          var infos = [];
          for (var j=0;j<divs.length && j<6;j++){
            var rr = divs[j].getBoundingClientRect();
            infos.push(divs[j].tagName + ':' + rr.left.toFixed(0) + ',' + rr.top.toFixed(0) + ',' + rr.width.toFixed(0) + ',' + rr.height.toFixed(0));
          }
          log('WIDGETCHILDREN=' + infos.join('|'));
        }, 2500);
        if ($autoExecute) {
          setTimeout(tryExecuteFallback, 6000);
        }
      } catch(err) {
        log('RENDER_THREW=' + String(err));
        window.TurnstileChannel.postMessage(JSON.stringify({kind:'error',value:String(err)}));
      }
    };

    if (window.turnstile && window.turnstile.render) {
      log('TURNSTILE_GLOBAL_EXISTS');
      loadTurnstile();
    } else {
      log('LOADING_API_SCRIPT');
      var s = document.createElement('script');
      s.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
      s.async = true;
      s.onload = loadTurnstile;
      s.onerror = function(){
        log('API_SCRIPT_ERROR');
        window.TurnstileChannel.postMessage(JSON.stringify({kind:'error',value:'script-load'}));
      };
      document.head.appendChild(s);
    }
    window.__smTsInjected = true;
    log('DONE');
  } catch(e) {
    log('INJECT_THREW=' + String(e));
    window.TurnstileChannel.postMessage(JSON.stringify({kind:'error',value:String(e)}));
  }
})();
''';
      await _controller.runJavaScript(script);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.height),
      decoration: BoxDecoration(
        color: const Color(0xFF101322),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errored ? const Color(0xFFF43F5E) : const Color(0x336366F1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            WebViewWidget(controller: _controller),
            if (!_ready)
              Positioned(
                bottom: 6,
                child: IgnorePointer(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}