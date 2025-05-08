import { One } from "./yours"


@Component
export struct settings {
  @Consume("self") self: One
  @Consume("pageStack") pageStack: NavPathStack
  build() {
    Column(){
      Row(){
        Text("昵称")
        Text(this.self.Name)
      }
      Row(){
        Text("账号")
        Text(this.self.ID)
      }
      Row(){
        Button("修改密码")
          .onClick(() => {
            this.pageStack.pushPathByName("reset password","")
          })
      }
      Row(){
        Button("修改昵称")
          .onClick(() => {
            this.pageStack.pushPathByName("reset Name", "")
          })
      }
      Row(){
        Button("修改头像")
          .onClick(() => {

          })
      }
    }
  }
}