// ralpage.ets
import {Linker} from './linker'
import { promptAction } from '@kit.ArkUI';
import { socket } from '@kit.NetworkKit';
import { NetworkService, Waiter } from './manager';

@Component
export struct RegANDLog {

  @Consume('pageStack') PageStack: NavPathStack
  @Consume('link') link: Linker
  @Consume('nets') nets: NetworkService
  @Consume('waiter') waiter: Waiter

  @State account: string = '';
  @State password: string = '';

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
              this.password = value;
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
              let message: string = `a ${this.account} pw ${this.password} t lg`
              this.link.void_send(message);
            });
        }
      }
    }
  }
}