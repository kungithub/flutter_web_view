import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';

/*
* 伪协议或者channel和网页交互
* 伪协议：     phapp://hello("world" , "你好");
* channel：   phapp.postMessage(JSON.stringify({method:'hello',arg:'world'}));
*
* token默认是写入cookie，可以设置写入 localstorage 或者自定义方法
* */
class WebPage extends StatefulWidget {
  // webview打开的网址
  final url;

  // token
  final token;

  // 写入token方式 cookie|localstorage|web端自定义的方法
  final tokenMethod;

  // token的key
  final tokenKey;

  // 和网页交互的名称
  final protocol;
  Map<String, Function(List<String>)> callBacks;

  Function(WebViewController) getController;

  bool loaded = false;

  WebPage(
      {@required this.url,
      this.protocol = "phapp",
      this.callBacks,
      this.getController,
      this.token,
      this.tokenMethod = 'cookie',
      this.tokenKey = 'token'});

  _WebPageState createState() => _WebPageState(callBacks, getController);
}

class _WebPageState extends State<WebPage> {
  Map<String, Function> callBacks;
  Function(WebViewController) getController;

  _WebPageState(this.callBacks, this.getController);

  WebViewController webCtr;

  @override
  Widget build(BuildContext context) {
    Set<JavascriptChannel> createChannel() {
      Set<JavascriptChannel> set = new Set<JavascriptChannel>();
      set.add(JavascriptChannel(
          name: widget.protocol,
          onMessageReceived: (JavascriptMessage message) {
            try {
              Map<String, dynamic> webJSON = json.decode(message.message);
              callBacks[webJSON['method']](<String>[webJSON['arg']]);
            } catch (err) {
              print('webpage exception:' + err.toString());
            }
          }));
      return set;
    }

    var content = <Widget>[
      Builder(builder: (BuildContext context) {

        return WebView(
            initialUrl: widget.url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController controller) {
              webCtr = controller;
              getController(controller);
            },
            onPageStarted: (String url) async {
              setState(() {
                widget.loaded = false;
              });
            },
            onPageFinished: (String url) async {
              if (widget.token != null) {
                var setToken =
                    'switch("${widget.tokenMethod}"){case"cookie":document.cookie="${widget.tokenKey}=${widget.token};path=/";break;case"localstorage":localStorage.setItem("${widget.tokenKey}","${widget.token}");break;default:${widget.tokenKey}("${widget.token}");break};';
                await webCtr.evaluateJavascript(setToken);
              }
              setState(() {
                widget.loaded = true;
              });
            },
            javascriptChannels: createChannel(),
            navigationDelegate: (NavigationRequest request) {
              var pro = widget.protocol + '://';
              if (request.url.startsWith(pro)) {
                // 处理伪协议
                RegExp reg = new RegExp(
                    pro + r'([a-zA-Z0-9]*?)(\((\s*"[^\"]*?"\s*,?\s*)*\)|$)');
                Iterable<Match> matches = reg.allMatches(request.url);
                for (Match m in matches) {
                  try {
                    // 处理伪协议参数
                    List<String> args = [];
                    Iterable<Match> argsMatches =
                        RegExp('"([^"]*?)"').allMatches(m.group(2));
                    argsMatches.forEach((c) {
                      args.add(Uri.decodeComponent(c.group(1)));
                    });
                    callBacks[m.group(1)](args);
                  } catch (err) {
                    print('webpage exception:' + err.toString());
                  }
                }
                return NavigationDecision.prevent;
              }
              if (!request.url.startsWith("http") &&
                  !request.url.startsWith("https")) {
                // 不允许打开其他协议
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            });
      })
    ];

    if (!widget.loaded)
      content.add(Center(
          child: CupertinoActivityIndicator(
        radius: 30.0,
        animating: true,
      )));

    return Stack(children: content);
  }
}
