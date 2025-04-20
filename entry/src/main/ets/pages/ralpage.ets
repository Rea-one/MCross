

@Component
export struct RegANDLog
{
  @State account: string = '';
  @State password: string = '';

  @Consume('PageStack') PageStack:NavPathStack;
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
            this.account = value;
          })
          .type(InputType.Password);
        }
        Row()
        {
          Button('注册')
            .onClick(() =>
            {
              this.PageStack.pushPathByName('register', '')
            });

          Button('登录');

        }
      }
    }
  }
}