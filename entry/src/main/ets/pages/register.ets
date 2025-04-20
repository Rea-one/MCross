import { PromptAction } from '@kit.ArkUI'

@Component
export struct RegPage
{
  @State account: string = '';
  @State cpassword: string ='';
  @State password: string = '';
  @State reject: boolean = true;

  @Consume('PageStack') PageStack:NavPathStack
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
            if (this.reject)
            {
              this.password = this.cpassword;
            }
            else
            {
              let uiContext = this.getUIContext();
              let promptAction: PromptAction = uiContext.getPromptAction();
              promptAction.showDialog
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