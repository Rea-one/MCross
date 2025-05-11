import { distributedKVStore } from '@kit.ArkData'
import { NetworkService, One, Waiter } from './manager'


@Component
export struct ChatPage {
  @Consume('nets') nets: NetworkService
  @Consume('waiter') waiter: Waiter
  @Consume('chatTar') chatTar: string

  @State message: string = ""

  self: One | null = null
  friend: One | null = null

  aboutToAppear(): void {
    this.self = this.waiter.self
    this.friend = this.waiter.getSgn(this.chatTar)
    if (this.friend === null) {
      this.friend = {
        ID: "",
        Name: "",
        IconID: ""
      }
    }
  }

  build() {
    Column(){
      List() {
        ForEach(this.waiter.the_msg[this.chatTar], (item: string, index: number) => {
          ListItem() {
            if (item[0] == this.chatTar) {
              Row() {
                if (this.friend != null) {
                  Image(this.waiter.getImg(this.friend.IconID))
                  Column() {
                    Text(this.friend.Name)
                    Text(item[1])
                  }
                } else {
                  Image(this.waiter.getImg("default"))
                  Column() {
                    Text("这是一个名字")
                    Text(item[1])
                  }
                }
              }
            }
          }
        })
      }
      Row(){
        TextInput()
          .onChange((val) => {
            this.message = val
          })
        Button("发送")
          .onClick(() => {
            if (this.self != null){
              this.nets.send(`s ${this.self.ID} r ${this.chatTar} m ${this.message}`)
            }
            this.message = ""
          })
      }
    }
  }
}