import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';


export class Linker {
  link: socket.TCPSocket = socket.constructTCPSocketInstance();
  address: socket.NetAddress = {} as socket.NetAddress;

  init(){
    this.address.address = '192.168.43.188';
    this.address.port = 25054;
  }

  connect(){
    let conn: socket.TCPConnectOptions = {} as socket.TCPConnectOptions
    conn.address = this.address
    conn.timeout = 9000
    this.link.connect(conn)
  }


  send(value: string){
    let current_mess: socket.TCPSendOptions = {
      data: value
    }
    this.link.send(current_mess)
  }
  void_send(value: string) {
    let current_mess: socket.TCPSendOptions = {
      data: value
    }
    this.link.send(current_mess)
  }
}

