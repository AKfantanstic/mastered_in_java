### TCP连接
一个 TCP 连接必须通过(客户端ip，客户端port，服务器端ip，服务器端port)来确定

### 1.socket定义
socket是操作系统对tcp协议和udp协议的抽象。TCP是两个进程之间的通信。socket翻译是套接字，就像插座一样，一个插头插进插座，建立了连接。
插头和插座是两个端点，每个端点代表一个socket，一个客户端socket连接代表了客户端ip和port。
一个服务端socket连接代表了服务端ip和port。