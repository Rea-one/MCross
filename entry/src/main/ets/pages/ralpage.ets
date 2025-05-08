
import {Linker} from './linker'
import {Method} from './task'
import { promptAction } from '@kit.ArkUI';
import { socket } from '@kit.NetworkKit';
import { One } from  './yours'

@Component
export struct RegANDLog {
  @Provide('self') self: One = {
    ID: "",
    Name: "",
    IconPath: "",
    Group: "self"
  }

  @Consume('pageStack') PageStack: NavPathStack;
  @Consume('linker') link: Linker;

  @State account: string = '';
  @State password: string = '';

  m: Method = new Method()

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text('账号');
          TextInput({ placeholder: '请输入账号' })
            .onChange((value: string) => {
              this.account = value;
            });
        }

        Row() {
          Text('密码');
          TextInput({ placeholder: '请输入密码' })
            .onChange((value: string) => {
              this.account = value;
            })
            .type(InputType.Password);
        }

        Row() {
          Button('注册')
            .onClick(() => {
              this.PageStack.pushPathByName('register', '')
            });

          Button('登录')
            .onClick(() => {
              this.link.send(this.m.login(this.account, this.password), (message: socket.SocketMessageInfo) => {
                let translated: string = ""
                for (let order: number = 0; order < message.message.byteLength; order++) {
                  translated += String.fromCharCode(message.message[order])
                }
                switch (translated) {
                  case "login success":
                    this.self.ID = this.account
                    this.PageStack.pushPathByName('yours', '')
                    this.password = ''
                    break
                  case "wrong password or wrong id":
                    this.getUIContext().getPromptAction().showToast({
                      message: "账号或密码错误",
                      duration: 2000,
                      bottom: 80
                    })
                }
                return "finish"
              })
            });
        }
      }
    }
  }
}