import { distributedKVStore } from '@kit.ArkData'
import { message, One } from './yours'


@Component
export struct ChatPage {
  @Consume('self') self: One
  @Consume('friend') mess: message[]


  build() {
    List() {
      ForEach(this.mess, (item: message, index: number) => {
        ListItem() {
          Row(){
            if (item.isSender) {
              Image("")
              Column()
              {
                Text(item.timestamp)
                Text(item.message)
              }
            } else {
              Image("")
              Column(){
                Text(item.timestamp)
                Text(item.message)
              }
            }
          }
        }
      })
    }
  }
}