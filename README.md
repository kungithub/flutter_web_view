# flutter_web_view


# webview组件


## 用法：

 ``` dart

 WebPage(
     // url地址
     url: widget.url,
     // 和网页的交互 会同时 url拦截 和 channel注入方法
     /* 伪协议或者channel和网页交互
     * 伪协议：     phapp://hello("world" , "你好");
     * channel：   phapp.postMessage(JSON.stringify({method:'hello',arg:'world'}));
     */
     callBacks: {
       "toggle": (args) {
         Toast.show(args[0], context);
       }
     },
     // 控制网页
     getController: (controller) {
       webController = controller;
     },
     // 写入网页的token 默认是写入cookie，也可以写入localstorage 或者自定义方法
     // 见参数  tokenKey tokenMethod
     token: "23rdfsdfsfsdfsdf",
   ),

 ```