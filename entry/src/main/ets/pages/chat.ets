import { distributedKVStore } from '@kit.ArkData'


@Component
export struct ChatPage {

  @State messages: [string, string][] = []


  build() {
    List() {
      ForEach(this.messages, (item: [string, string], index: number) => {
        ListItem() {
          Row(){
            Image()
          }
        }
      })
    }
  }
}