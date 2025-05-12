import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';


class SocketInfo {
  message: ArrayBuffer = new ArrayBuffer(1);
  remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class Linker {
  net: socket.TCPSocket = socket.constructTCPSocketInstance();
  address: socket.NetAddress = {} as socket.NetAddress;

  init(){
    this.address.address = '192.168.43.188';
    this.address.port = 25054;
  }

  connect(){
    let conn: socket.TCPConnectOptions = {} as socket.TCPConnectOptions
    conn.address = this.address
    conn.timeout = 9000
    this.net.connect(conn)
  }

  void_send(value: string) {
    let current_mess: socket.TCPSendOptions = {
      data: value
    }
    this.net.send(current_mess)
  }
}

