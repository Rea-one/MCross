import { Storage } from "./storage";
import { distributedKVStore } from "@kit.ArkData";


export interface One {
  ID: string;
  Name: string;
  IconPath: string;
  Group: string
}


export interface Self{
  ID: string;
  IconPath: string;
}


interface  frd {
  flips: Map<string, One[]>,
  messages: Map<string, [string, string][]>
}


interface Bunch {
  one: One;
  preview: string;
}

@Component
export struct Yours {
  @Consume('self')          self: Self
  @Consume('PageStack')     PageStack: NavPathStack;
  @Consume('store')         store: Storage

  @Consume('self')          self_store: distributedKVStore.SingleKVStore | null
  @Consume('friend')        friend_store: distributedKVStore.SingleKVStore | null
  @Consume('message')       message_store: distributedKVStore.SingleKVStore | null

  @State hot_frd: One[] = []
  @State friends: frd = {
    flips: new Map<string, One[]>(),
    messages: new Map<string, [string, string][]>()
  }
  @State signal: Map<string, boolean> = new Map<string, boolean>()


  aboutToAppear(): void {
    const options: distributedKVStore.Options = {
      createIfMissing: true,
      encrypt: false,
      backup: false,
      autoSync: false,
      kvStoreType: distributedKVStore.KVStoreType.DEVICE_COLLABORATION,
      securityLevel: distributedKVStore.SecurityLevel.S3
    }
    this.store.store?.getKVStore('self', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.self_store = feedback
      feedback.get(this.self.ID, (error, value) => {
        if (error){
          console.log("头像加载失败")
          return
        }
        let temp = value.toString().split(" ")
        this.self.IconPath
      })
    })
    this.store.store?.getKVStore('friend', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.friend_store = feedback
      feedback.getEntries('', (error, value) => {
        if (error){
          console.log("数据库读取失败")
          return
        }
        value.forEach(value => {
          this.friends.flips[value.key] = value.value
        })
      })
    })
    this.store.store?.getKVStore('message', options, (err, feedback: distributedKVStore.SingleKVStore) => {
      if (err){
        console.log("数据库读取失败")
        return
      }
      this.message_store = feedback
      feedback.getEntries('', (error, value) => {
        if (error) {
          console.log("数据库读取失败")
          return
        }
        value.forEach(elem => {
          this.friends.messages[elem.key] = elem.value
        })
      })
    })
  }

  build() {
    Tabs() {
      TabContent() {
        List() {
          ForEach(this.hot_frd, (item: One, index: number) => {
            ListItem() {
              Row() {
                Image(item.IconPath)
                Column() {
                  Text(item.Name)
                  Text(item.PreView)
                }
              }
            }
          })
        }
      }
      .tabBar("消息")

      TabContent() {
        List() {
          ForEach(Array.from(this.friends.flips), (One: [string, Friends[]]) => {
            ListItem() {
              Button(item[0])
                .onClick(() => {
                  this.signal[item[0]] = !this.signal[item[0]]
                })
              if (this.signal[item[0]]) {
                ForEach(item[1], (elem: One, index: number) => {
                  ListItem() {
                    Row() {
                      Image(elem.IconPath)
                      Column() {
                        Text(elem.Name)
                      }
                    }
                  }
                })
              }
            }
          })
        }
      }
      .tabBar("联系人")
    }

  }
}