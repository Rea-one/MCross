import { PromptAction } from '@kit.ArkUI'
import {Linker} from './linker'
import { Method } from './task'
import { socket } from '@kit.NetworkKit'

@Component
export struct RegPage
{
  @State account: string = '';
  @State cpassword: string ='';
  @State password: string = '';
  @State reject: boolean = true;
  @Consume('linker') link: Linker

  @Consume('PageStack') PageStack:NavPathStack

  m: Method = new Method()
  build()
  {
    NavDestination()
    {
      Column()
      {
        Row()
        {
          Text('账号')
          TextInput({placeholder: '请输入账号'})
          .onChange((value: string) =>
          {
            this.account = value;
          })
        }
        Row()
        {
          Text('密码')
          TextInput({placeholder: '请输入密码'})
          .onChange((value: string) =>
          {
            this.cpassword = value;
          })
          .type(InputType.Password);
        }
        Row()
        {
          Text('确认密码')
          TextInput({placeholder: '请输入密码'})
          .onChange((value: string) =>
          {
            if (value == this.cpassword)
            {
              this.reject = false;
            }
            else
            {
              this.reject = true;
            }
          })
          .type(InputType.Password)
        }
        Button('确认')
          .onClick(() =>
          {
            if (!this.reject)
            {
              this.password = this.cpassword;
              this.link.send(this.m.register(this.account, this.password), (message: socket.SocketMessageInfo) => {
                let translated: string = ""
                let storage = new Uint8Array(message.message)
                for (let order: number = 0; order < message.message.byteLength; order++) {
                  translated += String.fromCharCode(storage[order])
                }
                switch (translated){
                  case "registration success":
                    this.PageStack.pushPathByName('ralPage', '')
                    this.getUIContext().getPromptAction().showToast({
                      message: "注册完成，可以登录了",
                      duration: 2000
                    })
                    return "finished"
                  default :
                    this.getUIContext().getPromptAction().showToast({
                      message: "注册失败",
                      duration: 1000
                    })
                    return "failed"
                }
              })
              this.password = ''
              this.cpassword = ''
            }
            else
            {
              this.getUIContext().getPromptAction().showDialog
              ({
                title: '输入密码不一致！',
                buttons:
                [{
                  text: '重新输入',
                  color: '#000000'
                }]
              })
            }
          })
      }
    }
  }
}