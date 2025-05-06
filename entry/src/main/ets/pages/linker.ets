import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';


export type receive = ((value: socket.SocketMessageInfo) => string) | null

export class Linker {
  link: socket.TCPSocket = socket.constructTCPSocketInstance();
  address: socket.NetAddress = {} as socket.NetAddress;

  private receive: receive | null = null

  init(){
    this.address.address = '192.168.43.188';
    this.address.port = 25054
    this.link.on('message', (mess: socket.SocketMessageInfo) => {
      let result: string = ""
      if (this.receive != null)
      {
        result = this.receive(mess)
      } else {
        result = "nothing"
      }
      this.receive = null
      return result
    })
    // 设置错误监听器（非常重要！）
    this.link.on('error', (err: BusinessError) => {
      console.error('Socket error:', err);
    });
  }

  connect(){
    let conn: socket.TCPConnectOptions = {} as socket.TCPConnectOptions
    conn.address = this.address
    conn.timeout = 9000
    this.link.connect(conn)
  }


  send(value: string, action: receive){
    this.receive = action
    let current_mess: socket.TCPSendOptions = {
      data: value
    }
    this.link.send(current_mess)
  }

}

